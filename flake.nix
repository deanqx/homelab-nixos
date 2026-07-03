{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations = {
      "dean-homelab" = nixpkgs.lib.nixosSystem {
        modules = [
          ./common.nix
          ./hosts/dean-homelab/hardware.nix
          ./hosts/dean-homelab/config.nix
        ];
      };
      "storage-01" = nixpkgs.lib.nixosSystem {
        modules = [
          ./common.nix
          ./hosts/storage-01/hardware.nix
          ./hosts/storage-01/config.nix
        ];
      };
    };
  };
}

