{
  description = "Desktop notifications as clickable SteamVR overlays";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    forAllSystems = nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ];
  in {
    packages = forAllSystems (system: rec {
      vr-notifyd = nixpkgs.legacyPackages.${system}.callPackage ./package.nix { };
      default = vr-notifyd;
    });

    overlays.default = final: prev: {
      vr-notifyd = final.callPackage ./package.nix { };
    };

    homeManagerModules.default = ./module.nix;
  };
}
