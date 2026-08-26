# Installation

1. Download the [minimal ISO image](https://nixos.org/download/).

2. Verify the SHA-256 by running `sha256sum`.

3. Transfer the image to an USB (see [Arch Wiki](https://wiki.archlinux.org/title/USB_flash_installation_medium))

4. Boot from it on the installation target.

5. The Arch Wiki has a detailed guide on [partitioning](https://wiki.archlinux.org/title/Partitioning#Example_layouts).
   Important is to not configure `swap` because this is a server and the system
   should never try to use slow swapping.

6. Mount server disk (find it with `lsblk`):

```sh
sudo mount /dev/sdX /mnt
```

7. Connect to internet with `Ethernet` or with Wifi:

```sh
iwctl
```

8. Clone configuration:

```sh
cd /mnt/etc
nix-shell -p git
sudo git clone https://github.com/homelab-nixos nixos
```

9. Create new server configuration. And use other as reference.
   Adjust at least hostname and network interface (e.g. enp0XX or wlp0XX)
   potentially also the grub device.

```sh
cd nixos/hosts
sudo mkdir new-server
sudo cp existing-server/config.nix new-server
sudo -e new-server/config.nix
```

10. Generate Nixos hardware configuration:

```sh
sudo nixos-generate-config --root /mnt
mv ../../hardware.nix .
sudo git add -A
```

11. Create entry for new-server in `flake.nix`:

```sh
cd ../..
sudo -e flake.nix
cd /mnt
sudo nixos-install --flake /mnt/etc/nixos#new-server
sudo passwd [USER]
```

12. Reboot into installed Nixos

```sh
reboot
```

13. Login with your user and sync the system with the configuration.

```sh
cd /etc/nixos
sudo nixos-rebuild switch --flake .
```

## Git sync

The NixOS configuration on each server is automatically updated through Git.
When a commit gets pushed all server pull it and apply it using Comin.

To inspect what Comin is currently fetching, building, or failing on:

```sh
journalctl -u comin -f
```

To see the latest deployed commit and poll status:

```sh
comin status
```
