
# NixOS

## Update

```
sudo nix flake update
```

## Rebuild without updating

```
sudo nixos-rebuild switch
```

## Delete old generations

```
sudo nix-collect-garbage --delete-older-than 10d
```
