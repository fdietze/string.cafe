{ pkgs ? import <nixpkgs> {} }:

let
  pkgs = import <nixpkgs> { overlays = [ (import ./cypress-overlay.nix) ]; };
in
  pkgs.mkShell {
    nativeBuildInputs = with pkgs; [
      git
      terraform

      nodejs-16_x
      yarn

      sbt
    ];

    buildInputs = with pkgs; [
      nodePackages.prisma
      cypress
    ];

    shellHook = with pkgs; ''
      export PRISMA_MIGRATION_ENGINE_BINARY="${prisma-engines}/bin/migration-engine"
      export PRISMA_QUERY_ENGINE_BINARY="${prisma-engines}/bin/query-engine"
      export PRISMA_QUERY_ENGINE_LIBRARY="${prisma-engines}/lib/libquery_engine.node"
      export PRISMA_INTROSPECTION_ENGINE_BINARY="${prisma-engines}/bin/introspection-engine"
      export PRISMA_FMT_BINARY="${prisma-engines}/bin/prisma-fmt"

      export CYPRESS_INSTALL_BINARY=0
      export CYPRESS_RUN_BINARY=${pkgs.cypress}/bin/Cypress
    '';
  }
