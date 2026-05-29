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
