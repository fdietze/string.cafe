#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

cd "$script_dir"

exec nix develop -c just --justfile "$script_dir/justfile" "$@"
