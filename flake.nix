{
  description = "Nix package for Kiri, a small container runtime for macOS";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = ["aarch64-darwin" "x86_64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    packages = forAllSystems (system: rec {
      kiri = nixpkgs.legacyPackages.${system}.callPackage ./package.nix {};
      default = kiri;
    });

    overlays.default = final: _prev: {
      kiri = final.callPackage ./package.nix {};
    };

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
