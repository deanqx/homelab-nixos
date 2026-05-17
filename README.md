NixOS Homelab Configuration
===========================

This repository contains the NixOS Flake configurations for provisioning and
managing my homelab infrastructure.

- Main Repository: [Codeberg deanqx/homelab-nixos](https://codeberg.org/deanqx/homelab-nixos).
- Mirror: [GitHub deanqx/homelab-nixos](https://github.com/deanqx/homelab-nixos).
- The Kubernetes configurations for services running on the cluster can be
  found on [Codeberg deanqx/homelab-kubernetes](https://codeberg.org/deanqx/homelab-kubernetes).

Development
===========

The configuration files are designed to live at `/etc/nixos`.
Ensure you are in that directory before running the commands below.

## Apply config without updating

Nix will ignore any files not tracked by Git. So it is required to stage them:

```zsh
git add -A
```

To rebuild and switch to the current configuration without updating the
flake inputs:

```zsh
sudo nixos-rebuild switch --flake .
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
