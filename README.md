Homelab NixOS Configuration
===========================

_A project written by a human_

This repository contains the NixOS Flake configurations for provisioning and
managing my homelab infrastructure.

- Main Repository: [Codeberg deanqx/homelab-nixos](https://codeberg.org/deanqx/homelab-nixos)
- Mirror: [GitHub deanqx/homelab-nixos](https://github.com/deanqx/homelab-nixos)
- Server cluster confg: [Codeberg deanqx/homelab-kubernetes](https://codeberg.org/deanqx/homelab-kubernetes)

Developing
==========

Find configuration reference at [search.nixos.org](https://search.nixos.org/).

The configuration files are designed to live at `/etc/nixos`.
Ensure you are in that directory before running the commands below.

## Apply config without updating

Nix will ignore any files not tracked by Git. So it is required to stage them:

```zsh
git add -A
```

To rebuild and switch to the current configuration without updating the
flake inputs (uses hostname to select config):

```zsh
sudo nixos-rebuild switch --flake .
```

The `test` option can be used to auto revert changes after restarting.

```zsh
sudo nixos-rebuild test --flake .
```

## Update packages

Nix will ignore any files not tracked by Git. So it is required to stage them:

```zsh
git add -A
```

To update the flake.lock file and pull in the latest package versions from
your channels:

```zsh
sudo nix flake update
```

To apply the updates immediately after updating inputs:

```zsh
sudo nixos-rebuild switch --flake .
```

### Rollback

The best option to rollback a faulty change is to undo it with Git or manually
in the config and rebuild again. Sometimes this is not possible
(e.g. no internet connection) then `nix-env` can be used.

1. Find working generation

```zsh
nix-env --list-generations -p /nix/var/nix/profiles/system
```

Example Output:

```
  105   2026-06-28 14:20:11   
  106   2026-07-01 09:15:32   
  107   2026-07-03 11:00:00   (Current)
```

2. Switch to the working generation

```sh
sudo /nix/var/nix/profiles/system-106-link/bin/switch-to-configuration switch
```
