#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PBX="$ROOT_DIR/NotesMac.xcodeproj/project.pbxproj"

if [[ ! -f "$PBX" ]]; then
  echo "ERROR: Missing $PBX" >&2
  exit 1
fi

if ! command -v plutil >/dev/null 2>&1; then
  echo "ERROR: plutil not found. Run on macOS." >&2
  exit 1
fi

echo "Validating project.pbxproj…"
plutil -lint "$PBX"
echo "OK"

