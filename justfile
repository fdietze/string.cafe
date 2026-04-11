set shell := ["bash", "-cu"]

default:
	@just --list

shell:
	nix develop

check:
	nix develop -c php -l public/index.php

run:
	nix develop -c php -S 127.0.0.1:8000 -t public

gen:
	nix run .#write-fly-assets

deploy:
	nix run .#fly-deploy

status:
	nix develop -c flyctl status -a "${FLY_APP_NAME:-string-cafe-felx}"

logs:
	nix develop -c flyctl logs -a "${FLY_APP_NAME:-string-cafe-felx}"
