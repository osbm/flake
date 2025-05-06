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
    nix-on-droid switch --flake .
  else
    nh os switch .
  fi

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
  nom build -L .#nixosConfigurations.myISO.config.system.build.isoImage

flash-sd-image-harmonica:
  # raise error because this command should be edited before running
  false
  nom build -L .#nixosConfigurations.harmonica-sd.config.system.build.sdImage
  sudo dd if=result/sd-image/nixos-image-sd-card-25.05.20250224.0196c01-aarch64-linux.img of=/dev/sda bs=4M status=progress conv=fsync

