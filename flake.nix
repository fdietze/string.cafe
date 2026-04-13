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
            bash = pkgs.bash;
            php = pkgs.php84;
            postgresql = pkgs.postgresql_17;
            defaultAppName = "string-cafe-felx";
            defaultRegion = "ams";
            defaultPort = 8080;
            defaultAppDevPort = 8000;
            defaultPgPort = 54329;
            defaultPgUser = "postgres";
            defaultPgDatabase = "string_cafe";

            pgschema = pkgs.buildGoModule {
              pname = "pgschema";
              version = "1.6.2";

              src = pkgs.fetchFromGitHub {
                owner = "pgschema";
                repo = "pgschema";
                rev = "v1.6.2";
                hash = "sha256-leAI/+K717f+wsQG6O3Huohuqu80Hq87lA+yXMeQK64=";
              };

              vendorHash = "sha256-NXTGbts0Mb/h/ymL76kpFUMBZ+kNt06+KdtVsDFeGYw=";
              doCheck = false;

              meta = with pkgs.lib; {
                description = "Terraform-style declarative schema migration CLI for Postgres";
                homepage = "https://github.com/pgschema/pgschema";
                license = licenses.asl20;
                mainProgram = "pgschema";
              };
            };

            dbRuntimeInputs = [
              bash
              pkgs.coreutils
              pkgs.findutils
              pkgs.gawk
              pkgs.gnugrep
              pkgs.gnused
              pgschema
              postgresql
            ];

            mkDbApp = name: subcommand:
              pkgs.writeShellApplication {
                inherit name;
                runtimeInputs = dbRuntimeInputs;
                text = ''
                  if [ ! -f "$PWD/flake.nix" ] || [ ! -f "$PWD/AGENTS.md" ]; then
                    printf >&2 'Run %s from the repository root.\n' "${name}"
                    exit 1
                  fi

                  export STRING_CAFE_ROOT="$PWD"
                  export APP_PORT="${toString defaultAppDevPort}"
                  export PGDATA="$PWD/.local/postgres/data"
                  export PGSOCKETDIR="$PWD/.local/postgres/socket"
                  export PGHOST="127.0.0.1"
                  export PGPORT="${toString defaultPgPort}"
                  export PGUSER="${defaultPgUser}"
                  export PGDATABASE="${defaultPgDatabase}"
                  export DATABASE_URL="postgresql://$PGUSER@$PGHOST:$PGPORT/$PGDATABASE"
                  export PGLOG_MIN_DURATION_MS="250"

                  exec ${bash}/bin/bash "$STRING_CAFE_ROOT/scripts/db" ${subcommand} "$@"
                '';
              };

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

            dbCheckMigrations = mkDbApp "db-check-migrations" "check-migrations";
            dbGenerateMigration = mkDbApp "db-generate-migration" "generate-migration";
            dbInit = mkDbApp "db-init" "init";
            dbPsql = mkDbApp "db-psql" "psql";
            dbReset = mkDbApp "db-reset" "reset";
            dbResetFromMigrations = mkDbApp "db-reset-from-migrations" "reset-from-migrations";
            dbRun = mkDbApp "db-run" "run";
            dbWait = mkDbApp "db-wait" "wait";
            dbWipe = mkDbApp "db-wipe" "wipe";
          in
          f {
            inherit
              pkgs
              php
              flyImage
              writeFlyToml
              flyDeploy
              pgschema
              postgresql
              defaultAppDevPort
              defaultPgPort
              defaultPgUser
              defaultPgDatabase
              dbCheckMigrations
              dbGenerateMigration
              dbInit
              dbPsql
              dbReset
              dbResetFromMigrations
              dbRun
              dbWait
              dbWipe
              ;
          });
    in {
      devShells = forEachSystem ({
        pkgs,
        php,
        flyDeploy,
        pgschema,
        postgresql,
        defaultAppDevPort,
        defaultPgPort,
        defaultPgUser,
        defaultPgDatabase,
        dbCheckMigrations,
        dbGenerateMigration,
        dbInit,
        dbPsql,
        dbReset,
        dbResetFromMigrations,
        dbRun,
        dbWait,
        dbWipe,
        ...
      }: {
        default = pkgs.mkShell {
          packages = [
            dbCheckMigrations
            dbGenerateMigration
            dbInit
            dbPsql
            dbReset
            dbResetFromMigrations
            dbRun
            dbWait
            dbWipe
            php
            pkgs.flyctl
            pkgs.gh
            pkgs.git
            pkgs.just
            pkgs.process-compose
            pkgs.skopeo
            pgschema
            postgresql
            flyDeploy
          ];

          shellHook = ''
            export STRING_CAFE_ROOT="$PWD"
            export APP_PORT="${toString defaultAppDevPort}"
            export PGDATA="$PWD/.local/postgres/data"
            export PGSOCKETDIR="$PWD/.local/postgres/socket"
            export PGHOST="127.0.0.1"
            export PGPORT="${toString defaultPgPort}"
            export PGUSER="${defaultPgUser}"
            export PGDATABASE="${defaultPgDatabase}"
            export DATABASE_URL="postgresql://$PGUSER@$PGHOST:$PGPORT/$PGDATABASE"
            export PGLOG_MIN_DURATION_MS="250"

            echo "PHP/Fly dev shell ready."
            echo "Show commands: just"
            echo "Run the full dev stack: just dev"
            echo "Run PHP only: just run"
            echo "Open psql: just db-psql"
            echo "Generate a migration: just generate-migration add_example"
            echo "Generate config: write-fly-toml"
            echo "Build image: nix build .#fly-image"
            echo "Deploy to Fly: fly-deploy"
          '';
        };
      });

      packages = forEachSystem ({
        writeFlyToml,
        flyImage,
        flyDeploy,
        pgschema,
        dbCheckMigrations,
        dbGenerateMigration,
        dbInit,
        dbPsql,
        dbReset,
        dbResetFromMigrations,
        dbRun,
        dbWait,
        dbWipe,
        ...
      }: {
        default = writeFlyToml;
        db-check-migrations = dbCheckMigrations;
        db-generate-migration = dbGenerateMigration;
        db-init = dbInit;
        db-psql = dbPsql;
        db-reset = dbReset;
        db-reset-from-migrations = dbResetFromMigrations;
        db-run = dbRun;
        db-wait = dbWait;
        db-wipe = dbWipe;
        write-fly-toml = writeFlyToml;
        fly-image = flyImage;
        fly-deploy = flyDeploy;
        inherit pgschema;
      });

      apps = forEachSystem ({
        writeFlyToml,
        flyDeploy,
        dbCheckMigrations,
        dbGenerateMigration,
        dbPsql,
        dbReset,
        dbResetFromMigrations,
        dbRun,
        dbWipe,
        ...
      }: {
        db-check-migrations = {
          type = "app";
          program = "${dbCheckMigrations}/bin/db-check-migrations";
        };
        db-generate-migration = {
          type = "app";
          program = "${dbGenerateMigration}/bin/db-generate-migration";
        };
        db-psql = {
          type = "app";
          program = "${dbPsql}/bin/db-psql";
        };
        db-reset = {
          type = "app";
          program = "${dbReset}/bin/db-reset";
        };
        db-reset-from-migrations = {
          type = "app";
          program = "${dbResetFromMigrations}/bin/db-reset-from-migrations";
        };
        db-run = {
          type = "app";
          program = "${dbRun}/bin/db-run";
        };
        db-wipe = {
          type = "app";
          program = "${dbWipe}/bin/db-wipe";
        };
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
