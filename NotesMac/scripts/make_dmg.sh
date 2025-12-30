#!/usr/bin/env bash
set -euo pipefail

# Creates a drag-to-install DMG:
# - Notes.app
# - /Applications symlink
#
# Output: ./dist/Notes.dmg
#
# Run on macOS (requires hdiutil).

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="NotesMac.app"
VOL_NAME="Notes"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/App"
STAGE_DIR="$DIST_DIR/DMGStage"
DMG_TMP="$DIST_DIR/${VOL_NAME}-temp.dmg"
DMG_OUT="$DIST_DIR/${VOL_NAME}.dmg"

if ! command -v hdiutil >/dev/null 2>&1; then
  echo "ERROR: hdiutil not found. Run this on macOS." >&2
  exit 1
fi

if [[ ! -d "$APP_DIR/$APP_NAME" ]]; then
  echo "ERROR: Missing built app at: $APP_DIR/$APP_NAME" >&2
  echo "Run: scripts/build_release_app.sh" >&2
  exit 1
fi

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"

cp -R "$APP_DIR/$APP_NAME" "$STAGE_DIR/"
ln -sf /Applications "$STAGE_DIR/Applications"

rm -f "$DMG_TMP" "$DMG_OUT"

echo "Creating DMG…"
hdiutil create \
  -volname "$VOL_NAME" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_OUT"

echo "Created: $DMG_OUT"

