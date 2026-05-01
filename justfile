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

flash-sd-image-harmonica:
  # raise error because this command should be edited before running
  false
  nom build -L .#nixosConfigurations.harmonica-sd.config.system.build.sdImage
  sudo dd if=result/sd-image/nixos-image-sd-card-25.05.20250224.0196c01-aarch64-linux.img of=/dev/sda bs=4M status=progress conv=fsync

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
