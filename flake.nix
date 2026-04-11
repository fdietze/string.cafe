{
  description = "Minimal PHP hello world";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSystem = f:
        nixpkgs.lib.genAttrs systems (system:
          f {
            pkgs = import nixpkgs { inherit system; };
          });
    in {
      devShells = forEachSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = [
            pkgs.php
          ];

          shellHook = ''
            echo "PHP dev shell ready."
            echo "Start with: php -S 127.0.0.1:8000 -t public"
          '';
        };
      });
    };
}
