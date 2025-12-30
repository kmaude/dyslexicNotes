#!/usr/bin/env bash
set -euo pipefail

# Builds NotesMac.app (Release) into ./dist/App

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/NotesMac.xcodeproj"
SCHEME="NotesMac"
CONFIG="Release"
OUT_DIR="$ROOT_DIR/dist/App"

mkdir -p "$OUT_DIR"

echo "Building $SCHEME ($CONFIG)…"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -destination "platform=macOS" \
  -derivedDataPath "$ROOT_DIR/dist/DerivedData" \
  BUILD_LIBRARY_FOR_DISTRIBUTION=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

APP_PATH="$(find "$ROOT_DIR/dist/DerivedData/Build/Products/$CONFIG" -maxdepth 1 -name "${SCHEME}.app" -print -quit)"
if [[ -z "${APP_PATH:-}" ]]; then
  echo "ERROR: Could not find built app in DerivedData." >&2
  exit 1
fi

rm -rf "$OUT_DIR/${SCHEME}.app"
cp -R "$APP_PATH" "$OUT_DIR/"

echo "Built: $OUT_DIR/${SCHEME}.app"

