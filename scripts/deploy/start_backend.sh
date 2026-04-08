#!/usr/bin/env bash
set -euo pipefail

DEPLOY_ROOT="${DEPLOY_ROOT:-$HOME/web/guess-together.gall-studio.com/private/backend}"
CURRENT_LINK="$DEPLOY_ROOT/current"
SHARED_DIR="$DEPLOY_ROOT/shared"
ENV_FILE="$SHARED_DIR/backend.env"
PID_FILE="$SHARED_DIR/backend.pid"
LOG_FILE="$SHARED_DIR/logs/backend.log"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing env file: $ENV_FILE" >&2
  exit 1
fi

if [[ ! -x "$CURRENT_LINK/bin/server" ]]; then
  echo "Backend binary not found: $CURRENT_LINK/bin/server" >&2
  exit 1
fi

mkdir -p "$SHARED_DIR/logs"

if [[ -f "$PID_FILE" ]]; then
  OLD_PID="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "${OLD_PID:-}" ]] && kill -0 "$OLD_PID" 2>/dev/null; then
    kill "$OLD_PID" || true
    for _ in $(seq 1 20); do
      if ! kill -0 "$OLD_PID" 2>/dev/null; then
        break
      fi
      sleep 1
    done
    if kill -0 "$OLD_PID" 2>/dev/null; then
      kill -9 "$OLD_PID" || true
    fi
  fi
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

nohup "$CURRENT_LINK/bin/server" >>"$LOG_FILE" 2>&1 &
NEW_PID=$!
echo "$NEW_PID" > "$PID_FILE"
echo "Started backend pid=$NEW_PID"
