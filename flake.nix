{
  description = "Minimal PHP app with Fly.io deployment from Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    forEachSystem = f:
      nixpkgs.lib.genAttrs systems (system: let
        pkgs = import nixpkgs {inherit system;};
        php = pkgs.php84;

        writeFlyToml = pkgs.writeShellApplication {
          name = "write-fly-toml";
          runtimeInputs = [pkgs.coreutils];
          text = ''
                            app_name="''${FLY_APP_NAME:-string-cafe-felx}"
                            primary_region="''${FLY_PRIMARY_REGION:-ams}"
                            port="''${FLY_INTERNAL_PORT:-8080}"

                            cat > fly.toml <<EOF
            app = "$app_name"
            primary_region = "$primary_region"

            [build]
              dockerfile = "Dockerfile"

            [env]
              PORT = "$port"

            [http_service]
              internal_port = $port
              force_https = true
              auto_stop_machines = "stop"
              auto_start_machines = true
              min_machines_running = 0

            [[vm]]
              cpu_kind = "shared"
              cpus = 1
              memory_mb = 256
            EOF

                            printf 'Wrote fly.toml for %s\n' "$app_name"
          '';
        };

        writeFlyDockerfile = pkgs.writeShellApplication {
          name = "write-fly-dockerfile";
          runtimeInputs = [pkgs.coreutils];
          text = ''
                            php_version="''${PHP_VERSION:-8.4}"
                            port="''${FLY_INTERNAL_PORT:-8080}"

                            cat > Dockerfile <<EOF
            FROM php:$php_version-cli-alpine
            WORKDIR /app
            COPY public ./public
            EXPOSE $port
            CMD ["php", "-S", "0.0.0.0:$port", "-t", "public"]
            EOF

                            printf 'Wrote Dockerfile for PHP %s\n' "$php_version"
          '';
        };

        writeFlyAssets = pkgs.writeShellApplication {
          name = "write-fly-assets";
          runtimeInputs = [writeFlyToml writeFlyDockerfile];
          text = ''
            write-fly-dockerfile
            write-fly-toml
          '';
        };

        flyDeploy = pkgs.writeShellApplication {
          name = "fly-deploy";
          runtimeInputs = [pkgs.flyctl writeFlyAssets];
          text = ''
            write-fly-assets
            exec flyctl deploy --remote-only --config fly.toml "$@"
          '';
        };
      in
        f {
          inherit pkgs php writeFlyToml writeFlyDockerfile writeFlyAssets flyDeploy;
        });
  in {
    devShells = forEachSystem ({
      pkgs,
      php,
      writeFlyAssets,
      flyDeploy,
      ...
    }: {
      default = pkgs.mkShell {
        packages = [
          php
          pkgs.flyctl
          pkgs.gh
          pkgs.git
          pkgs.just
          writeFlyAssets
          flyDeploy
        ];
      };
    });

    packages = forEachSystem ({
      writeFlyToml,
      writeFlyDockerfile,
      writeFlyAssets,
      flyDeploy,
      ...
    }: {
      default = writeFlyAssets;
      write-fly-toml = writeFlyToml;
      write-fly-dockerfile = writeFlyDockerfile;
      write-fly-assets = writeFlyAssets;
      fly-deploy = flyDeploy;
    });

    apps = forEachSystem ({
      writeFlyToml,
      writeFlyDockerfile,
      writeFlyAssets,
      flyDeploy,
      ...
    }: {
      write-fly-toml = {
        type = "app";
        program = "${writeFlyToml}/bin/write-fly-toml";
      };
      write-fly-dockerfile = {
        type = "app";
        program = "${writeFlyDockerfile}/bin/write-fly-dockerfile";
      };
      write-fly-assets = {
        type = "app";
        program = "${writeFlyAssets}/bin/write-fly-assets";
      };
      fly-deploy = {
        type = "app";
        program = "${flyDeploy}/bin/fly-deploy";
      };
    });
  };
}
