# AGENTS.md

## Core Philosophy

- Keep the project small, explicit, and easy to reason about.
- Nix is the source of truth for tooling, build logic, and deployment artifacts.
- The deployed runtime should come from Nix, not from an unpinned external base image.
- Prefer one clear path from local development to production over multiple partially overlapping workflows.

## Architecture

- The application is a minimal PHP app served from `public/index.php`.
- `flake.nix` defines the development environment, the generated Fly config, the runtime image, and the deploy command.
- `fly.toml` is generated from Nix and should be treated as a build artifact rather than hand-maintained source.
- The Fly runtime image is built from Nix and deployed as an image, instead of relying on Fly to build a custom Dockerfile.

## Tools

- Use `flake.nix` as the authoritative place for project tooling and deployment behavior.
- Use `justfile` only as a convenience layer over the Nix-defined workflow.
- Use the repo-local `just` launcher so contributors do not need a global `just` install.
- Keep GitHub Actions aligned with the same Nix-defined deploy path used locally.

## Learnings

- If reproducibility matters, generating a Dockerfile is not enough; the runtime itself must also come from Nix.
- A convenience command layer is useful, but it should stay thin and never become the real source of truth.
- Generated operational files are easier to trust when their logic lives in one place.
- Simple PHP hosting is enough for this project; avoid introducing framework or infrastructure complexity without a clear reason.

## Editing Guidelines

- Preserve the simple shape of the app unless the project requirements materially change.
- Prefer changes that keep local development, CI, and deployment conceptually aligned.
- When changing workflow or deploy behavior, update `flake.nix`, `justfile`, and this document together.
- Favor clarity and reproducibility over cleverness.
