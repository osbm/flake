_default:
  @just --list --unsorted

check-git:
  # git must be clean
  test -z "$(git status --porcelain)"

[linux]
build *args: check-git
  sudo nixos-rebuild build --flake . {{args}} |& nom
  nvd diff /run/current-system ./result

[linux]
switch *args: check-git remove-hm-backup-files
  #!/usr/bin/env sh
  if [[ "$(hostname)" == "localhost" ]]; then
    nix-on-droid switch --flake . {{args}}
  else
    nh os switch . {{args}} --accept-flake-config
  fi

[macos]
switch *args: check-git
  nh darwin switch . -- --accept-flake-config {{args}}

# Migrate Firefox profile from legacy ~/.mozilla/firefox to XDG ~/.config/mozilla/firefox.
# Run once per host AFTER the rebuild that switches firefox.configPath, with Firefox closed.
migrate-firefox-profile:
  #!/usr/bin/env sh
  set -eu
  src="$HOME/.mozilla/firefox"
  dst="$HOME/.config/mozilla/firefox"

  if pgrep -x firefox > /dev/null; then
    echo "ERROR: Firefox is running — close it before migrating, or it will create a fresh profile and clobber profiles.ini"
    exit 1
  fi
  if [ ! -e "$src" ]; then
    echo "no legacy profile at $src — nothing to do"
    exit 0
  fi
  if [ -e "$dst" ]; then
    echo "ERROR: destination $dst already exists — refusing to overwrite"
    echo "if you intended to merge, do it manually"
    exit 1
  fi

  mkdir -p "$(dirname "$dst")"
  mv "$src" "$dst"
  echo "moved $src -> $dst"

  # Sanity check: profiles.ini must reference an existing profile dir,
  # otherwise Firefox will create a fresh one on next launch and lose your data.
  ini="$dst/profiles.ini"
  if [ ! -f "$ini" ]; then
    echo "WARNING: no profiles.ini found at $ini — Firefox will start fresh"
    exit 0
  fi
  profile_path=$(awk -F= '/^Path=/ {print $2; exit}' "$ini" | tr -d '\r')
  if [ -z "$profile_path" ]; then
    echo "WARNING: profiles.ini has no Path= entry"
  elif [ ! -d "$dst/$profile_path" ]; then
    echo "WARNING: profiles.ini references '$profile_path' but $dst/$profile_path does not exist"
    echo "fix: edit $ini and set Path= to one of: $(ls -d "$dst"/*/ 2>/dev/null | xargs -n1 basename | tr '\n' ' ')"
    exit 1
  else
    echo "verified: active profile -> $profile_path"
  fi
  echo "note: native messaging hosts were not moved; reinstall if you use any"
  echo "you can now launch Firefox"

remove-hm-backup-files:
  #!/usr/bin/env sh

  if [ -f ~/.gtkrc-2.0.hmbak ]; then
    rm ~/.gtkrc-2.0.hmbak
  fi

test:
  nh os test .

update:
  nix flake update

check:
  nix flake check

repl:
  nix repl -f flake:nixpkgs

collect-garbage:
  sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old
  # home-manager expire-generations now
  sudo nix-collect-garbage --delete-older-than 3d

list-generations:
  nixos-rebuild list-generations

build-sd-image-harmonica: check-git
  nom build -L .#nixosConfigurations.harmonica-sd.config.system.build.sdImage

build-sd-image-pochita: check-git
  nom build -L .#nixosConfigurations.pochita-sd.config.system.build.sdImage

# Build (just) the system closure for harmonica-encrypted; the actual SD card is
# produced by `flash-harmonica-encrypted-sd` because the layout includes LUKS.
build-harmonica-encrypted: check-git
  nom build -L .#nixosConfigurations.harmonica-encrypted.config.system.build.toplevel --out-link result-harmonica-encrypted

# Flash an encrypted harmonica SD card with LUKS-encrypted root + TTY decryption.
# Usage: just flash-harmonica-encrypted-sd /dev/sdX [PASSPHRASE]
# Layout:  p1 = vfat FIRMWARE (128 MiB) — Pi firmware reads this
#          p2 = LUKS (rest) labeled cryptroot, ext4 inside labeled NIXOSROOT
flash-harmonica-encrypted-sd DEVICE PASSPHRASE="changeme": build-harmonica-encrypted
  #!/usr/bin/env bash
  set -euo pipefail
  DEV={{DEVICE}}
  PASS={{PASSPHRASE}}
  if [ "$(lsblk -o TRAN -nr $DEV | head -1)" != "usb" ]; then
    echo "ERROR: $DEV is not a USB device. Refusing." >&2; exit 1
  fi
  if mount | grep -q "^$DEV"; then
    echo "ERROR: $DEV has mounted partitions. Unmount first." >&2; exit 1
  fi
  CLOSURE=$(readlink -f result-harmonica-encrypted)
  RPI_FW=$(nix eval --raw nixpkgs#raspberrypifw)/share/raspberrypi/boot
  echo "Closure:  $CLOSURE"
  echo "RPi-fw:   $RPI_FW"
  echo "Device:   $DEV"
  sudo -v

  # 1. wipe + partition
  sudo wipefs -a "$DEV"
  sudo sfdisk "$DEV" <<EOF
  label: gpt
  size=128MiB, type=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7, name="FIRMWARE"
  type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name="cryptroot"
  EOF
  sudo blockdev --rereadpt "$DEV"
  sleep 2

  # 2. format FAT + LUKS + ext4-inside-LUKS
  sudo mkfs.vfat -F 32 -n FIRMWARE "${DEV}1"
  echo -n "$PASS" | sudo cryptsetup luksFormat --type luks2 --label CRYPTROOT --batch-mode "${DEV}2" -
  echo -n "$PASS" | sudo cryptsetup open --key-file - "${DEV}2" cryptroot_inst
  sudo mkfs.ext4 -L NIXOSROOT /dev/mapper/cryptroot_inst

  # 3. mount target
  MNT=$(mktemp -d)
  trap 'sudo umount "$MNT/boot/firmware" 2>/dev/null || true; sudo umount "$MNT" 2>/dev/null || true; sudo cryptsetup close cryptroot_inst 2>/dev/null || true; rmdir "$MNT" 2>/dev/null || true' EXIT
  sudo mount /dev/mapper/cryptroot_inst "$MNT"
  sudo mkdir -p "$MNT/boot/firmware"
  sudo mount "${DEV}1" "$MNT/boot/firmware"

  # 4. install the closure to cryptroot
  sudo nixos-install --root "$MNT" --system "$CLOSURE" --no-root-passwd --no-channel-copy

  # 5. populate /boot/firmware (Pi firmware blobs + kernel + initrd + config.txt + cmdline.txt)
  sudo cp "$RPI_FW"/{bootcode.bin,start*.elf,fixup*.dat} "$MNT/boot/firmware/"
  sudo cp "$RPI_FW"/bcm*.dtb "$MNT/boot/firmware/"
  sudo cp -r "$RPI_FW/overlays" "$MNT/boot/firmware/"
  sudo cp -L "$CLOSURE/kernel"  "$MNT/boot/firmware/kernel.img"
  sudo cp -L "$CLOSURE/initrd"  "$MNT/boot/firmware/initrd"
  printf '%s\n' \
    'arm_64bit=1' \
    'kernel=kernel.img' \
    'initramfs initrd followkernel' \
    'enable_uart=1' \
    'disable_overscan=1' \
    | sudo tee "$MNT/boot/firmware/config.txt" > /dev/null
  printf '%s\n' \
    'console=tty1 console=serial0,115200n8 root=/dev/mapper/cryptroot rootfstype=ext4 rootwait init=/sbin/init loglevel=4' \
    | sudo tee "$MNT/boot/firmware/cmdline.txt" > /dev/null

  # 6. pre-deploy the harmonica host SSH key (so agenix can decrypt at first boot)
  TMPKEY=$(mktemp)
  nix run nixpkgs#age -- -d -i "$HOME/.ssh/id_ed25519" secrets/harmonica-host-key-private.age > "$TMPKEY"
  ssh-keygen -y -f "$TMPKEY" >/dev/null
  sudo install -m 600 -o root -g root "$TMPKEY" "$MNT/etc/ssh/ssh_host_ed25519_key"
  printf '%s root@harmonica\n' "$(ssh-keygen -y -f "$TMPKEY")" | sudo tee "$MNT/etc/ssh/ssh_host_ed25519_key.pub" > /dev/null
  sudo chmod 644 "$MNT/etc/ssh/ssh_host_ed25519_key.pub"
  rm -f "$TMPKEY"

  # 7. flush + clean up
  sudo sync
  sudo umount "$MNT/boot/firmware"
  sudo umount "$MNT"
  sudo cryptsetup close cryptroot_inst
  rmdir "$MNT"
  trap - EXIT
  echo "Flashed. LUKS passphrase: $PASS"
  echo "Insert SD into the Pi; it will prompt for the passphrase at the TTY."

build-iso: check-git
  nom build -L .#nixosConfigurations.iso.config.system.build.isoImage

# Flash harmonica SD card AND pre-deploy the host SSH key so agenix can decrypt at first boot.
# Usage: just flash-harmonica-sd /dev/sdX
# Refuses non-USB devices to avoid clobbering the system disk.
flash-harmonica-sd DEVICE: build-sd-image-harmonica
  #!/usr/bin/env bash
  set -euo pipefail
  if [ "$(lsblk -o TRAN -nr {{DEVICE}} | head -1)" != "usb" ]; then
    echo "ERROR: {{DEVICE}} is not a USB device. Refusing." >&2; exit 1
  fi
  if mount | grep -q "^{{DEVICE}}"; then
    echo "ERROR: {{DEVICE}} has mounted partitions. Unmount first." >&2; exit 1
  fi
  IMG=$(ls result/sd-image/*.img | head -1)
  echo "Flashing $IMG -> {{DEVICE}}"
  sudo -v
  sudo wipefs -a {{DEVICE}}
  sudo dd if="$IMG" of={{DEVICE}} bs=4M status=progress conv=fsync
  sync
  sudo blockdev --rereadpt {{DEVICE}}
  sleep 2
  MNT=$(mktemp -d)
  TMPKEY=$(mktemp)
  trap 'rm -f "$TMPKEY"; sudo umount "$MNT" 2>/dev/null || true; rmdir "$MNT" 2>/dev/null || true' EXIT
  # decrypt to local tempfile FIRST so a silent failure aborts before we touch the SD
  nix run nixpkgs#age -- -d -i "$HOME/.ssh/id_ed25519" secrets/harmonica-host-key-private.age > "$TMPKEY"
  ssh-keygen -y -f "$TMPKEY" >/dev/null   # validate it's actually a usable SSH private key
  sudo mount {{DEVICE}}2 "$MNT"
  sudo mkdir -p "$MNT/etc/ssh"
  sudo install -m 600 -o root -g root "$TMPKEY" "$MNT/etc/ssh/ssh_host_ed25519_key"
  printf '%s root@harmonica\n' "$(ssh-keygen -y -f "$TMPKEY")" | sudo tee "$MNT/etc/ssh/ssh_host_ed25519_key.pub" > /dev/null
  sudo chmod 644 "$MNT/etc/ssh/ssh_host_ed25519_key.pub"
  sudo sync
  echo "Flashed + host key deployed. Eject and insert into the Pi."

setup-apollo-nixos:
  nano /tmp/secret.key
  sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode destroy,format,mount --flake github:osbm/flake#apollo

  sudo mkdir -p /mnt/etc/ssh
  sudo ssh-keygen -t ed25519 -N "" -f /mnt/etc/ssh/initrd

  sudo nixos-install --flake github:osbm/flake#apollo --root /mnt --no-root-passwd

sweep *args:
   nix run github:jzbor/nix-sweep -- {{args}}

# Deploy to a specific machine natively using nh
deploy HOST:
  nh os switch . --hostname {{HOST}} --target-host osbm@{{HOST}}-ts

# Deploy to ALL machines natively via nh
deploy-all:
  @echo "Deploying to all machines..."
  just deploy ymir
  just deploy tartarus
  just deploy apollo
  just deploy ares
  just deploy wallfacer
