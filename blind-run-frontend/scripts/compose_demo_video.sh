#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLIPS_DIR="${1:-$ROOT_DIR/.demo-video/raw}"
OUTPUT_PATH="${2:-$HOME/Desktop/aidrun-demo-review.mp4}"

xcrun swift \
  "$ROOT_DIR/tools/demo_video/compose_demo_video.swift" \
  --manifest "$ROOT_DIR/tools/demo_video/review_manifest.json" \
  --clips "$CLIPS_DIR" \
  --output "$OUTPUT_PATH"
