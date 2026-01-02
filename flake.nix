{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = inputs@{ self, nixpkgs, ... }: {
    nixosConfigurations.dean-homelab = nixpkgs.lib.nixosSystem {
      modules = [ ./configuration.nix ];
    };
  };
}

