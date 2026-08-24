# JA Compare

Windows-first document and folder comparison for fast, readable diffs.

![Flutter](https://img.shields.io/badge/Flutter-Windows-02569B?logo=flutter)
![Release](https://img.shields.io/badge/Release-v2.0.2-2563EB)
![License](https://img.shields.io/badge/License-MIT-green)

[Tiếng Việt](i18n/README.vi.md) · [Website](https://jatechvn.github.io/) · [GitHub](https://github.com/jatechvn/JA_Compare)

## Overview

JA Compare is a Windows desktop app for comparing documents and complete
directory trees. It presents synchronized side-by-side diffs, keeps a local
comparison history, and exports results for review or sharing.

## Features

- File comparison with drag-and-drop or file picker.
- Drop two files or two folders anywhere in the app to populate both comparison
  sides automatically.
- Folder comparison with recursive scanning and optional similar-name groups.
- Side-by-side panes with synchronized scrolling and color-coded changes.
- Clear green confirmation when two compared files are identical.
- Multi-format extraction: text, Markdown, CSV, JSON, LOG, XML, HTML, YAML,
  YML, INI, Word (`.docx`), Excel (`.xlsx`), and PDF (`.pdf`).
- Tolerant Excel (`.xlsx`) parsing for real-world styles, duplicate shared
  strings, and distant style-only rows.
- Markdown diff and color-coded Excel export.
- Comparison history for both file and folder comparisons; folder entries can
  be reopened directly. Older file-only history remains compatible.
- English, Vietnamese, and Chinese UI, persisted between launches.
- Glassmorphism settings with Windows 10/11 native backdrop effects.
- Normal and debug logs are written beside the executable in `logs/`; use
  `debug.bat` to launch a packaged build with full diagnostic logging.
- Single-instance behavior that focuses the existing window.

## Quick start

```bash
flutter pub get
flutter run -d windows
```

For a local packaged build:

```bash
build_release.bat
```

The release ZIP is written to `dist/` with one parent folder and no runtime
configuration or history files. User settings and comparison history are
stored under `%LOCALAPPDATA%\JA Compare`; runtime logs are written beside the
application executable in `logs/`.

## User guide

1. Choose files individually, or drag two files / two folders anywhere into the
   app to fill both sides automatically.
2. Press **Compare** to calculate the result.
3. If files match exactly, the result bar shows **Files are identical**. For
   differences, review added, removed, modified, and similar-name entries.
4. Copy either side or export the result as Markdown or Excel.
5. Open **Comparison history** to reopen a previous file or folder pair.
6. Use **Settings** to change language, theme, and glassmorphism values.
7. For diagnostics, run `debug.bat`; logs are stored in the packaged app's
   `logs/` folder.

## Configuration

Visual settings and language are persisted in `%LOCALAPPDATA%\JA Compare`.
Comparison history is stored there as well. Runtime logs intentionally stay
beside the executable in `logs/` so a portable copy can be diagnosed in place.

## Architecture

```text
lib/
└── modules/
    ├── extractors/   document readers and format conversion
    ├── i18n/         language provider and translations
    ├── models/       comparison and history data models
    ├── native/       Windows/native integration boundaries
    ├── services/     storage, comparison, export, and platform services
    └── ui/            main window, dialogs, history, and diff views
test/                 unit and widget coverage
windows/              Windows runner and native backdrop integration
```

## Development checks

```bash
dart format lib test
flutter analyze
flutter test
```

## Changelog and license

See [CHANGELOG.md](CHANGELOG.md) for the permanent project history and
[RELEASE_NOTES.md](RELEASE_NOTES.md) for the current release draft. JA Compare
is distributed under the [MIT License](LICENSE).

Recent releases:

- **v2.0.2:** resilient Excel parsing, two-item drag-and-drop, identical-result
  feedback, and executable-local normal/debug logs.
- **v2.0.1:** folder comparison history and reopenable folder entries.
