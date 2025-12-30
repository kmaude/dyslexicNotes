#!/usr/bin/env bash
set -euo pipefail

# Repairs common project.pbxproj corruption:
# - Strips UTF-8 BOM
# - Removes any junk bytes before the expected header line
# - Normalizes line endings to LF
#
# Run from repo root:
#   ./scripts/fix_project_pbxproj.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PBX="$ROOT_DIR/NotesMac.xcodeproj/project.pbxproj"

python3 - <<'PY'
from __future__ import annotations

from pathlib import Path

pbx = Path(__file__).resolve().parent.parent / "NotesMac.xcodeproj" / "project.pbxproj"
data = pbx.read_bytes()

header = b"// !$*UTF8*$!"

# Strip UTF-8 BOM if present
if data.startswith(b"\xef\xbb\xbf"):
    data = data[3:]

# If header exists later, drop everything before it
idx = data.find(header)
if idx > 0:
    data = data[idx:]

# Normalize CRLF -> LF
data = data.replace(b"\r\n", b"\n")
data = data.replace(b"\r", b"\n")

# Final sanity: must start with header
if not data.startswith(header):
    # Give a helpful error that prints the first few bytes as hex
    preview = " ".join(f"{b:02x}" for b in data[:16])
    raise SystemExit(f"ERROR: pbxproj still does not start with expected header. First bytes: {preview}")

pbx.write_bytes(data)
print("Fixed:", pbx)
PY

