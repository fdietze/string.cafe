#!/usr/bin/env bash
set -Eeuo pipefail

require_env() {
  local env_name="$1"

  if [ -z "${!env_name:-}" ]; then
    printf >&2 'Required environment variable %s is not set.\n' "$env_name"
    exit 1
  fi
}

require_env STRING_CAFE_ROOT
require_env APP_PORT
require_env PGDATA
require_env PGSOCKETDIR
require_env PGHOST
require_env PGPORT
require_env PGUSER
require_env PGDATABASE
require_env DATABASE_URL
require_env PGLOG_MIN_DURATION_MS

readonly REPO_ROOT="$STRING_CAFE_ROOT"

ensure_layout() {
  mkdir -p "$REPO_ROOT/.local/postgres"
  mkdir -p "$PGSOCKETDIR"
}

init_db_cluster() {
  ensure_layout

  if [ -d "$PGDATA" ]; then
    return
  fi

  initdb \
    --pgdata="$PGDATA" \
    --username="$PGUSER" \
    --auth=trust \
    --no-locale \
    --encoding=UTF8

  cat >>"$PGDATA/pg_hba.conf" <<'EOF'
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
local   all             all                                     trust
EOF
}

postgres_is_ready() {
  pg_isready \
    --host="$PGHOST" \
    --port="$PGPORT" \
    --username="$PGUSER" \
    --dbname=postgres \
    >/dev/null 2>&1
}

wait_for_postgres() {
  local attempts=0

  until postgres_is_ready; do
    attempts=$((attempts + 1))

    if [ "$attempts" -ge 50 ]; then
      printf >&2 'Postgres did not become ready on %s:%s.\n' "$PGHOST" "$PGPORT"
      exit 1
    fi

    sleep 0.2
  done
}

start_temp_postgres_if_needed() {
  if postgres_is_ready; then
    return
  fi

  init_db_cluster

  postgres \
    -D "$PGDATA" \
    -k "$PGSOCKETDIR" \
    -p "$PGPORT" \
    -c listen_addresses='127.0.0.1' \
    -c unix_socket_directories="$PGSOCKETDIR" \
    -c "log_min_duration_statement=$PGLOG_MIN_DURATION_MS" \
    -c log_line_prefix='%m [%p] ' \
    &

  TEMP_POSTGRES_PID=$!
  export TEMP_POSTGRES_PID
  wait_for_postgres
}

stop_temp_postgres_if_started() {
  if [ -n "${TEMP_POSTGRES_PID:-}" ] && kill -0 "$TEMP_POSTGRES_PID" 2>/dev/null; then
    kill "$TEMP_POSTGRES_PID"
    wait "$TEMP_POSTGRES_PID" || true
  fi
}

database_exists() {
  local db_name="$1"

  psql \
    --dbname=postgres \
    --tuples-only \
    --no-align \
    --command="SELECT 1 FROM pg_database WHERE datname = '$db_name';" \
    | grep -q '^1$'
}

ensure_database_exists() {
  local db_name="$1"

  if database_exists "$db_name"; then
    return
  fi

  createdb "$db_name"
}

terminate_database_connections() {
  local db_name="$1"

  psql \
    --dbname=postgres \
    --command="SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$db_name' AND pid <> pg_backend_pid();"
}

recreate_database() {
  local db_name="$1"

  if database_exists "$db_name"; then
    terminate_database_connections "$db_name"
    dropdb "$db_name"
  fi

  createdb "$db_name"
}

apply_schema_to_database() {
  local db_name="$1"

  PGDATABASE="$db_name" pgschema apply \
    --file "$REPO_ROOT/schema.sql" \
    --auto-approve
}

apply_migrations_to_database() {
  local db_name="$1"
  local migration_file

  shopt -s nullglob

  for migration_file in "$REPO_ROOT"/migrations/*.sql; do
    printf 'Applying migration %s\n' "$(basename "$migration_file")"
    psql \
      --dbname="$db_name" \
      --set=ON_ERROR_STOP=1 \
      --file="$migration_file"
  done
}

make_temp_database_name() {
  printf 'string_cafe_tmp_%s_%s\n' "$(date -u +%Y%m%d%H%M%S)" "$RANDOM"
}

slugify_migration_name() {
  printf '%s\n' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/_/g; s/^_+//; s/_+$//; s/__+/_/g'
}
