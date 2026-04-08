#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${BASE_DIR:-$HOME/web/guess-together.gall-studio.com/private}"
POSTGRES_ROOT="${POSTGRES_ROOT:-$BASE_DIR/runtime/postgres}"
DATA_DIR="${POSTGRES_DATA_DIR:-$BASE_DIR/runtime/postgres-data}"
LOG_FILE="${POSTGRES_LOG_FILE:-$BASE_DIR/runtime/logs/postgres.log}"
POSTGRES_PORT="${POSTGRES_PORT:-55432}"

mkdir -p "$(dirname "$LOG_FILE")"

if [[ ! -x "$POSTGRES_ROOT/bin/pg_ctl" ]]; then
  echo "Missing pg_ctl at $POSTGRES_ROOT/bin/pg_ctl" >&2
  exit 1
fi

if [[ ! -d "$DATA_DIR" ]]; then
  echo "Missing postgres data dir: $DATA_DIR" >&2
  exit 1
fi

if "$POSTGRES_ROOT/bin/pg_ctl" -D "$DATA_DIR" status >/dev/null 2>&1; then
  echo "PostgreSQL already running"
  exit 0
fi

"$POSTGRES_ROOT/bin/pg_ctl" \
  -D "$DATA_DIR" \
  -l "$LOG_FILE" \
  -o "-p $POSTGRES_PORT -h 127.0.0.1" \
  start

echo "Started PostgreSQL on 127.0.0.1:$POSTGRES_PORT"
