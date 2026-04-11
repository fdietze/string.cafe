{
  description = "Minimal PHP app with Fly.io deployment from Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forEachSystem = f:
        nixpkgs.lib.genAttrs systems (system:
          let
            pkgs = import nixpkgs { inherit system; };
            lib = pkgs.lib;
            php = pkgs.php84;
            defaultAppName = "string-cafe-felx";
            defaultRegion = "ams";
            defaultPort = 8080;

            appRoot = pkgs.runCommand "string-cafe-app-root" {} ''
              mkdir -p "$out/app"
              cp -r ${./public} "$out/app/public"
            '';

            startApp = pkgs.writeShellScriptBin "start-app" ''
              port="''${PORT:-${toString defaultPort}}"
              exec ${php}/bin/php -S "0.0.0.0:$port" -t /app/public
            '';

            flyImage = pkgs.dockerTools.buildLayeredImage {
              name = defaultAppName;
              tag = "latest";
              contents = [
                appRoot
                startApp
                php
                pkgs.cacert
              ];
              config = {
                WorkingDir = "/app";
                Cmd = [ "${startApp}/bin/start-app" ];
                Env = [
                  "PORT=${toString defaultPort}"
                  "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                ];
                ExposedPorts = {
                  "${toString defaultPort}/tcp" = {};
                };
              };
            };

            writeFlyToml = pkgs.writeShellApplication {
              name = "write-fly-toml";
              runtimeInputs = [ pkgs.coreutils ];
              text = ''
                app_name="''${FLY_APP_NAME:-${defaultAppName}}"
                primary_region="''${FLY_PRIMARY_REGION:-${defaultRegion}}"
                port="''${FLY_INTERNAL_PORT:-${toString defaultPort}}"

                cat > fly.toml <<EOF
app = "$app_name"
primary_region = "$primary_region"

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

            flyDeploy = pkgs.writeShellApplication {
              name = "fly-deploy";
              runtimeInputs = [
                pkgs.coreutils
                pkgs.flyctl
                pkgs.nix
                pkgs.skopeo
                writeFlyToml
              ];
              text = ''
                app_name="''${FLY_APP_NAME:-${defaultAppName}}"
                image_label="''${FLY_IMAGE_LABEL:-deployment-$(date -u +%Y%m%d%H%M%S)}"
                image_ref="registry.fly.io/$app_name:$image_label"
                token="''${FLY_API_TOKEN:-}"

                if [ -z "$token" ]; then
                  token="$(flyctl auth token 2>/dev/null || true)"
                fi

                if [ -z "$token" ]; then
                  printf >&2 'FLY_API_TOKEN must be set or flyctl auth login must be configured\n'
                  exit 1
                fi

                write-fly-toml

                image_archive="$(nix build .#fly-image --print-out-paths --no-link)"

                printf 'Built image archive: %s\n' "$image_archive"
                printf 'Pushing image: %s\n' "$image_ref"

                skopeo copy \
                  --insecure-policy \
                  --dest-creds "x:$token" \
                  "docker-archive:$image_archive" \
                  "docker://$image_ref"

                exec flyctl deploy --yes --config fly.toml --image "$image_ref" "$@"
              '';
            };
          in
          f {
            inherit pkgs php flyImage writeFlyToml flyDeploy;
          });
    in {
      devShells = forEachSystem ({ pkgs, php, flyDeploy, ... }: {
        default = pkgs.mkShell {
          packages = [
            php
            pkgs.flyctl
            pkgs.gh
            pkgs.git
            pkgs.just
            pkgs.skopeo
            flyDeploy
          ];

          shellHook = ''
            echo "PHP/Fly dev shell ready."
            echo "Show commands: just"
            echo "Run locally: php -S 127.0.0.1:8000 -t public"
            echo "Generate config: write-fly-toml"
            echo "Build image: nix build .#fly-image"
            echo "Deploy to Fly: fly-deploy"
          '';
        };
      });

      packages = forEachSystem ({ writeFlyToml, flyImage, flyDeploy, ... }: {
        default = writeFlyToml;
        write-fly-toml = writeFlyToml;
        fly-image = flyImage;
        fly-deploy = flyDeploy;
      });

      apps = forEachSystem ({ writeFlyToml, flyDeploy, ... }: {
        write-fly-toml = {
          type = "app";
          program = "${writeFlyToml}/bin/write-fly-toml";
        };
        fly-deploy = {
          type = "app";
          program = "${flyDeploy}/bin/fly-deploy";
        };
      });
    };
}
