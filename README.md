# nixos is life
The nix configuration of mine. My intentions are just to maintain my configuration and to contribute to the nix community.

Here i have 4 machines and 1 sd card image that i maintain.
- Laptop **tartarus** (faulty hardware, nvidia gpu doesnt work)
- Desktop **ymir** (beast, my most prized possesion as of now)
- Raspberry Pi 5 **pochita** (a server that i experiment with)
- Raspberry Pi 5 SD image **pochita-sd** (produces an sd image that could be used to flash the sd card of a rpi-5)
- Phone **atreus** (unrooted, nix-on-droid)


I didnt get these setup yet.
- Raspberry Pi Zero 2W **harmonica** (small machine for small tasks and cronjobs) (not setup yet)
- Android phone (termux) **android** (not setup yet)

<details>
  <summary> How to bootstrap raspberry pi 5</summary>

## How to use raspberry pi 5

I have 2 configurations for the raspberry pi 5. One is for the sd card (basically bootstraps the system) and the other is for my customized system itself.

build the image first (this took about 4 hours on ymir (binfmt for aarch64 needs to be enabled if you are building on x86_64))
```sh
$ nix build -L '.#nixosConfigurations.pochita-sd.config.system.build.sdImage'
```

then to flash the image to the sd card enable zstd
```sh
$ nix-shell -p zstd
```

then flash the image to the sd card
```sh
$ zstdcat nixos-sd-image-24.05.20241116.e8c38b7-aarch64-linux.img.zst | dd of=/dev/sda status=progress
```

and voila! when you plug the sd card to the raspberry pi 5 it will boot up with the configuration that you have built. And then you can ssh into it and further configure it.

</details>
build iso with:
 nix build .#nixosConfigurations.myISO.config.system.build.isoImage 

# To-do list

- [x] iso image generator for nixos
    - Basically the original nixos iso with added packages and tweaks.
- [ ] build custom android rom
    - Or how to run nixos on the phone.
- [ ] build android apps using nix
    - [ ] lichess
    - [ ] termux
- [ ] build my qmk keyboard with nix
- agenix
    - [ ] add my gpg keys
    - [x] add ssh keys so that machines can connect to each other
- [x] module system with options
- [ ] see which derivations will be built and which will be downloaded from cache or which is already present in the nix store.
- [ ] see which python packages are giving build errors.
- [x] home-manager setup
- [ ] make a development environment nix repository
- [ ] enable swap on pochita
- [ ] learnis it possible to enable swap with sd-image?

