# JA Compare

Windows-first document and folder comparison for fast, readable diffs.

![Flutter](https://img.shields.io/badge/Flutter-Windows-02569B?logo=flutter)
![Release](https://img.shields.io/badge/Release-v2.0.1-2563EB)
![License](https://img.shields.io/badge/License-MIT-green)

[Tiếng Việt](i18n/README.vi.md) · [Website](https://jatechvn.github.io/) · [GitHub](https://github.com/jatechvn/JA_Compare)

## Overview

JA Compare is a Windows desktop app for comparing documents and complete
directory trees. It presents synchronized side-by-side diffs, keeps a local
comparison history, and exports results for review or sharing.

## Features

- File comparison with drag-and-drop or file picker.
- Folder comparison with recursive scanning and optional similar-name groups.
- Side-by-side panes with synchronized scrolling and color-coded changes.
- Multi-format extraction: text, Markdown, CSV, JSON, LOG, XML, HTML, YAML,
  YML, INI, Word (`.docx`), Excel (`.xlsx`), and PDF (`.pdf`).
- Markdown diff and color-coded Excel export.
- Comparison history for both file and folder comparisons; folder entries can
  be reopened directly. Older file-only history remains compatible.
- English, Vietnamese, and Chinese UI, persisted between launches.
- Glassmorphism settings with Windows 10/11 native backdrop effects.
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
configuration, history, or log files. User settings, comparison history, and
logs are stored under `%LOCALAPPDATA%\JA Compare`.

## User guide

1. Choose or drag a file into the left and right panes, or switch to **Folders**
   and choose two directories.
2. Press **Compare** to calculate the result.
3. Review added, removed, modified, and similar-name entries. File panes scroll
   together automatically.
4. Copy either side or export the result as Markdown or Excel.
5. Open **Comparison history** to reopen a previous file or folder pair.
6. Use **Settings** to change language, theme, and glassmorphism values.

## Configuration

Visual settings and language are persisted in the user profile. The app keeps
runtime state outside the installation folder so a release directory can be
replaced safely during upgrades.

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
