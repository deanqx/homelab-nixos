Homelab NixOS Configuration
===========================

_A project written by a human_

This repository contains the NixOS Flake configurations for provisioning and
managing my homelab infrastructure.

- Repository: [GitHub deanqx/homelab-nixos](https://github.com/deanqx/homelab-nixos)
- Server cluster config: [Codeberg deanqx/homelab-kubernetes](https://codeberg.org/deanqx/homelab-kubernetes)

Deployment
==========

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

Developing
==========

Find configuration reference at [search.nixos.org](https://search.nixos.org/).

The configuration files are designed to live at `/etc/nixos`.
Ensure you are in that directory before running the commands below.

## Apply config without updating

Nix will ignore any files not tracked by Git. So it is required to stage them:

```sh
git add -A
```

To rebuild and switch to the current configuration without updating the
flake inputs (uses hostname to select config):

```sh
sudo nixos-rebuild switch --flake .
```

The `test` option can be used to auto revert changes after restarting.

```sh
sudo nixos-rebuild test --flake .
```

## Update packages

Nix will ignore any files not tracked by Git. So it is required to stage them:

```sh
git add -A
```

To update the flake.lock file and pull in the latest package versions from
your channels:

```sh
sudo nix flake update
```

To apply the updates immediately after updating inputs:

```sh
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

## Deployments Location and Permissions

- Deployed apps with Docker or scripts relating to them are under `/srv`.
- Kubernetes Cluster deployed apps are managed with GitOps ([Codeberg deanqx/homelab-kubernetes](https://codeberg.org/deanqx/homelab-kubernetes)).

### Creating a new project

1. Create the project folder

```sh
sudo mkdir /srv/new_project
```

2. Set generic ownership

```sh
sudo chown -R root:devops /srv/new_project
```

3. Permissions

"2" Subdirectories inherit `devops` group, "77" full access for `devops` group,
others get no access.

```sh
sudo chmod 2770 /srv/my-new-project
```

4. Default permissions for subdirectories

Set default (`-d`) and modify (`-m`) directory's primary (`:empty:`) group (`g`)
setting to "read, write, traverse". Give others (`o`) no permissions (`---`).

```sh
sudo setfacl -d -m g::rwx,o::--- /srv/my-new-project
```
