#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILES=(
  "$PROJECT_ROOT/.env"
  "$PROJECT_ROOT/.env.local"
  "$PROJECT_ROOT/.env.amap.local"
)

ENV_FILE_TO_USE=""
for ENV_FILE in "${ENV_FILES[@]}"; do
  if [[ -f "$ENV_FILE" ]]; then
    ENV_FILE_TO_USE="$ENV_FILE"
  fi
done

cd "$PROJECT_ROOT"

if [[ -n "$ENV_FILE_TO_USE" ]]; then
  flutter run \
    --dart-define-from-file="$ENV_FILE_TO_USE" \
    "$@"
else
  echo "Warning: no local env file found; continuing without AMap keys." >&2
  flutter run "$@"
fi
