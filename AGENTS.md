# AGENTS.md

## Project Overview

- Minimal PHP app served from `public/index.php`.
- Nix is the source of truth for local tooling and deployment helpers.
- Fly.io deploy artifacts (`fly.toml` and `Dockerfile`) are generated, not committed.

## Important Files

- `flake.nix` defines the dev shell and the generated Fly tooling.
- `justfile` provides convenience commands for the most common tasks.
- `just` is a repo-local launcher so contributors can run `./just ...` without a global `just` install.
- `.github/workflows/fly.yml` deploys to Fly on push to `main`.
- `public/index.php` is the current application entrypoint.

## Preferred Commands

Use these from the repository root:

- `./just --list` to see available commands.
- `./just run` to start the local PHP server.
- `./just check` to run a PHP syntax check.
- `./just gen` to generate `fly.toml` and `Dockerfile`.
- `./just deploy` to deploy with Fly using the flake-defined tooling.
- `./just status` to inspect the Fly app.
- `./just logs` to stream Fly logs.

Direct Nix commands still work and remain the underlying source of truth.

## Deployment Notes

- GitHub Actions deploys on push to `main` via `.github/workflows/fly.yml`.
- The workflow expects `FLY_API_TOKEN` in GitHub repository secrets.
- Default Fly app name is `string-cafe-felx` unless overridden with `FLY_APP_NAME`.
- Default Fly region is `ams` unless overridden with `FLY_PRIMARY_REGION`.
- Default PHP version for the generated Dockerfile is `8.4` unless overridden with `PHP_VERSION`.

## Editing Guidelines

- Keep the setup simple: Nix generates deploy assets, Fly builds remotely from the generated Dockerfile.
- Do not commit generated `fly.toml` or `Dockerfile` unless the workflow intentionally changes.
- Prefer updating `flake.nix` and `justfile` together when changing developer workflow.
- Preserve the plain-text PHP entrypoint style unless there is a clear reason to expand it.
