{
  description = "Nix flake for my homepage";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
  in {
    devShells."${system}".default = let
      pkgs = import nixpkgs {
        inherit system;
      };
    in
      pkgs.mkShell {
        name = "homepage";
        packages = with pkgs; [
          just

          hugo
        ];

        shellHook = ''
          echo "hugo: $(hugo version)"
        '';
      };
  };
}
