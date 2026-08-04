{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, comin }@inputs: {
    nixosConfigurations = {
      "dean-homelab" = nixpkgs.lib.nixosSystem {
        modules = [
          comin.nixosModules.comin
          ./common.nix
          ./hosts/dean-homelab/hardware.nix
          ./hosts/dean-homelab/config.nix
        ];
      };
      "storage-01" = nixpkgs.lib.nixosSystem {
        modules = [
          comin.nixosModules.comin
          ./common.nix
          ./hosts/storage-01/hardware.nix
          ./hosts/storage-01/config.nix
        ];
      };
      "worker-01" = nixpkgs.lib.nixosSystem {
        modules = [
          comin.nixosModules.comin
          ./common.nix
          ./hosts/worker-01/hardware.nix
          ./hosts/worker-01/config.nix
        ];
      };
    };
  };
}
