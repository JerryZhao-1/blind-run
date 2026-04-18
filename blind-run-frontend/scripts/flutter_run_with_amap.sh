#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IOS_XCCONFIG="$PROJECT_ROOT/ios/Flutter/Amap.local.xcconfig"
ENV_FILES=(
  "$PROJECT_ROOT/.env"
  "$PROJECT_ROOT/.env.local"
  "$PROJECT_ROOT/.env.amap.local"
)

LOADED_ENV=false
for ENV_FILE in "${ENV_FILES[@]}"; do
  if [[ -f "$ENV_FILE" ]]; then
    set -a
    source "$ENV_FILE"
    set +a
    LOADED_ENV=true
  fi
done

if [[ "$LOADED_ENV" == false ]]; then
  echo "Warning: no local env file found; continuing without AMap keys." >&2
fi

: "${AMAP_ANDROID_KEY:=}"
: "${AMAP_IOS_KEY:=}"
: "${AMAP_WEB_KEY:=}"

cat > "$IOS_XCCONFIG" <<EOF
// Generated from local env by scripts/flutter_run_with_amap.sh
AMAP_IOS_KEY=$AMAP_IOS_KEY
EOF

cd "$PROJECT_ROOT"

flutter run \
  --dart-define=AMAP_ANDROID_KEY="$AMAP_ANDROID_KEY" \
  --dart-define=AMAP_IOS_KEY="$AMAP_IOS_KEY" \
  --dart-define=AMAP_WEB_KEY="$AMAP_WEB_KEY" \
  "$@"
