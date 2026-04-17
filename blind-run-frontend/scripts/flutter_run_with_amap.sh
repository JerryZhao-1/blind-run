#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env.amap.local"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

cd "$PROJECT_ROOT"

flutter run \
  --dart-define=AMAP_ANDROID_KEY="$AMAP_ANDROID_KEY" \
  --dart-define=AMAP_IOS_KEY="$AMAP_IOS_KEY" \
  --dart-define=AMAP_WEB_KEY="$AMAP_WEB_KEY" \
  "$@"
