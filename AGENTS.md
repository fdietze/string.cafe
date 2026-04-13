# AGENTS.md

You must always keep this file up-to date for: project requirements, architectural changes, learnings, editing guidelines.

## Core Philosophy

- Keep the project small, explicit, and easy to reason about.
- Nix is the source of truth for tooling, build logic, and deployment artifacts.
- The deployed runtime should come from Nix, not from an unpinned external base image.
- Prefer one clear path from local development to production over multiple partially overlapping workflows.

## Architecture

- The application is a minimal PHP app served from `public/index.php`.
- The index page reads and writes channel records directly against Postgres using PDO.
- `flake.nix` defines the development environment, the generated Fly config, the runtime image, and the deploy command.
- The local Postgres development environment is repo-local and Nix-provided. Database state lives under `.local/postgres/`.
- `schema.sql` defines the desired Postgres schema. Schema changes start there.
- `migrations/*.sql` is append-only migration history. Existing migration files are never edited or deleted.
- `fly.toml` is generated from Nix and should be treated as a build artifact rather than hand-maintained source.
- The Fly runtime image is built from Nix and deployed as an image, instead of relying on Fly to build a custom Dockerfile.

## Tools

- Use `flake.nix` as the authoritative place for project tooling and deployment behavior.
- Keep database command names and database settings in `flake.nix`. The repo-local shell layer is only an implementation detail behind those Nix-defined commands.
- Use `justfile` only as a convenience layer over the Nix-defined workflow.
- Use the repo-local `just` launcher so contributors do not need a global `just` install.
- Use `process-compose` for the local multi-process development workflow.
- Keep GitHub Actions aligned with the same Nix-defined deploy path used locally.

## Learnings

- If reproducibility matters, generating a Dockerfile is not enough; the runtime itself must also come from Nix.
- A convenience command layer is useful, but it should stay thin and never become the real source of truth.
- A small repo-local shell implementation is fine, but avoid a large fleet of tiny wrapper scripts when one dispatcher will do.
- Generated operational files are easier to trust when their logic lives in one place.
- The persistent dev database must stay outside migration generation and migration verification. Those workflows use disposable databases only.
- `just dev` should make the local PHP and Postgres stack work without any manual database bootstrap.
- Simple PHP hosting is enough for this project; avoid introducing framework or infrastructure complexity without a clear reason.

## Editing Guidelines

- Preserve the simple shape of the app unless the project requirements materially change.
- Prefer changes that keep local development, CI, and deployment conceptually aligned.
- When changing workflow or deploy behavior, update `flake.nix`, `justfile`, `process-compose.yml`, and this document together.
- Keep the long-lived dev database isolated from migration generation and migration verification tooling.
- When changing the database schema, update `schema.sql` first, then generate a new migration. Never hand-edit old migrations.
- Favor clarity and reproducibility over cleverness.


# Architecture Principles to follow
- Keep It Simple, Stupid (KISS): Avoid unnecessary complexity in design and implementation.
- You Ain’t Gonna Need It (YAGNI): Do not add functionality until it is demonstrably necessary.
- Don’t Repeat Yourself (DRY): Every piece of knowledge must have a single, unambiguous representation.
- Separation of Concerns (SoC): Divide the system into distinct sections with minimal overlap in functionality.
- Minimize Cognitive Load: Design systems that are as easy as possible to understand and reason about.
- High Cohesion, Low Coupling: Keep related code together and reduce dependencies between modules.
- Functional Core, Imperative Shell: Isolate side-effects to the outermost layers of the application.
- Vertical Slice Architecture: Structure code around business capabilities or features, not technical layers.
- SOLID Principles: A set of five fundamental principles for object-oriented design.
- Single Responsibility Principle (SRP): A class or module should have one, and only one, reason to change.
- Law of Demeter (Principle of Least Knowledge): A module should not know about the internal details of the objects it manipulates.
- Tell, Don’t Ask: An object should command another object to perform an action, rather than asking for its state.
- Make Illegal States Irrepresentable: Use the type system to ensure that invalid data cannot exist.
- Parse, Don’t Validate: Transform un-trusted input into a validated domain model at the system boundary.
- Correctness by Construction: Design components so they can only be created in a valid state.
- Prefer Compile-Time Errors over Runtime Errors: Maximize the number of errors that can be caught by the compiler.
- Favor Immutability: Prefer data structures that cannot be modified after they are created.
- Design by Contract: Be explicit about the preconditions, postconditions, and invariants of components.
- Design for Testability: Structure the system to allow for easy and effective unit and integration testing.
