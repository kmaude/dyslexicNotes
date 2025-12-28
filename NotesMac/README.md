## Notes (NotesMac)

Personal, offline-first macOS (13+) SwiftUI app for dyslexic high school students.

### Setup
- Open `NotesMac.xcodeproj` in Xcode (macOS 13+).
- Build + Run on Apple Silicon.
- On first launch, the app creates:
  - **Note bundles base**: `~/Documents/Notes/`
  - **App Support**: `~/Library/Application Support/Notes/`
    - `settings.json`
    - `notes.sqlite`
    - `Models/` (whisper.cpp models)

### Model download (Whisper)
- Go to **Settings → Models**.
- Download **Small** or **Medium**.
- Downloads are **blocked when School Mode is ON**.
- Models are stored in `~/Library/Application Support/Notes/Models/`.

### School Mode
- **School Mode ON** disables all networking and blocks model downloads/updates.
- Toggle from **Dashboard top bar** or **Settings → Privacy**.

### Folder structure (per note bundle)
Notes are stored under:
- `~/Documents/Notes/<Class Name>/<YYYY-MM-DD>/`

Files (per note):
- Audio: `YYYY-MM-DD - HHMM - <Title>.m4a`
- Metadata/content:
  - `... - meta.json`
  - `... - transcript.json`
  - `... - transcript.txt`
  - `... - markers.json`
  - `... - notes.md`
  - `... - notes (Clean Copy N).rtf`
  - `... - notes (Clean Copy N).docx`

### Hotkeys (global)
Planned mapping (implemented in later milestones):
- Cmd+Shift+R: show/launch recording bar + start flow
- Cmd+Shift+S: stop
- Cmd+Shift+Space: pause/resume
- Cmd+Shift+M: mute toggle
- Cmd+Shift+1: add ⭐ marker
- Cmd+Shift+2: add ❓ marker
- Cmd+Shift+L: collapse/expand recording bar
- Cmd+Shift+D: open Dashboard
- Cmd+Shift+O: open most recent note

### Milestones
- **M1**: App shell, settings store, GRDB schema + migrations, seed classes + one sample note, Dashboard UI, Recording Bar overlay (simulated timer).
- **M2**: Real audio capture to `.m4a`, mute/pause/stop, segments + markers, `meta.json`.
- **M3**: whisper.cpp integration + model downloads, chunk transcription + refine pass, transcript files + FTS.
- **M4**: Playback + synced sentence highlighting + speed control + replay loop.
- **M5**: Organizer Option A generates `notes.md`.
- **M6**: Dyslexia supports 1–7 wired into Note Detail.
- **M7**: Clean copies + RTF/DOCX export + rename flow (keep `note_id` stable).
