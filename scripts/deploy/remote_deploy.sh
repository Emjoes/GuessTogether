#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <release-id> <archive-path>" >&2
  exit 1
fi

RELEASE_ID="$1"
ARCHIVE_PATH="$2"
DEPLOY_ROOT="${DEPLOY_ROOT:-$HOME/web/guess-together.gall-studio.com/private/backend}"
SHARED_DIR="$DEPLOY_ROOT/shared"
RELEASES_DIR="$DEPLOY_ROOT/releases"
CURRENT_LINK="$DEPLOY_ROOT/current"
ENV_FILE="$SHARED_DIR/backend.env"
START_SCRIPT="${START_SCRIPT:-$HOME/web/guess-together.gall-studio.com/private/backend/bin/start_backend.sh}"

if [[ ! -f "$ARCHIVE_PATH" ]]; then
  echo "Archive not found: $ARCHIVE_PATH" >&2
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing env file: $ENV_FILE" >&2
  exit 1
fi

mkdir -p "$RELEASES_DIR" "$SHARED_DIR/logs"
RELEASE_DIR="$RELEASES_DIR/$RELEASE_ID"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"
tar -xzf "$ARCHIVE_PATH" -C "$RELEASE_DIR"
ln -sfn "$RELEASE_DIR" "$CURRENT_LINK"

if [[ ! -x "$START_SCRIPT" ]]; then
  echo "Missing start script: $START_SCRIPT" >&2
  exit 1
fi

"$START_SCRIPT"

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

HEALTH_URL="http://${SERVER_HOST}:${PORT}/health"
for _ in $(seq 1 30); do
  if curl --silent --show-error --fail "$HEALTH_URL" >/dev/null; then
    echo "Backend is healthy at $HEALTH_URL"
    rm -f "$ARCHIVE_PATH"
    exit 0
  fi
  sleep 1
done

echo "Backend failed health check at $HEALTH_URL" >&2
tail -n 80 "$LOG_FILE" >&2 || true
exit 1
