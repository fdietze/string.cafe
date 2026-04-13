set shell := ["bash", "-cu"]

default:
	@just --list

dev:
	nix develop -c process-compose up --config process-compose.yml --no-server --tui=true

shell:
	nix develop

check:
	nix develop -c php -l public/index.php
	nix develop -c db-check-migrations

run:
	nix develop -c php -S 127.0.0.1:8000 -t public

db-init:
	nix develop -c db-init

db-psql:
	nix develop -c db-psql

db-reset:
	nix develop -c db-reset

db-reset-from-migrations:
	nix develop -c db-reset-from-migrations

db-wipe:
	nix develop -c db-wipe

check-migrations:
	nix develop -c db-check-migrations

generate-migration name:
	nix develop -c db-generate-migration "{{name}}"

gen:
	nix run .#write-fly-toml

image:
	nix build .#fly-image

deploy:
	nix run .#fly-deploy

status:
	nix develop -c flyctl status -a "${FLY_APP_NAME:-string-cafe-felx}"

logs:
	nix develop -c flyctl logs -a "${FLY_APP_NAME:-string-cafe-felx}"
