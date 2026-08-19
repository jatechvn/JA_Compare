# JA Compare

A Windows desktop app that compares two documents and highlights the
differences between them, side by side.

## Supported formats

- Text/Markdown/CSV/JSON/LOG/XML/HTML (`.txt .md .csv .json .log .xml .html .htm .yaml .yml .ini`)
- Word (`.docx`)
- Excel (`.xlsx .xls`)
- PDF (`.pdf`)

## Features

- Pick a file via button or drag-and-drop straight onto the window.
- Side-by-side diff view with two scroll-synchronized panes.
- Added/removed/modified lines are color-coded, with a summary bar showing
  the counts.
- Select and copy text directly from either pane, or copy a whole side in
  one click.
- Export the result as Markdown (fenced ```diff block) or a color-coded
  Excel workbook, to save or share.
- Comparison history — revisit any past file pair with one click.
- EN/VI/CN language switcher (persisted across restarts) and a light/dark
  toggle that otherwise follows the Windows system theme.
- Glassmorphic UI built on the OS's own compositor — native Acrylic on
  Windows 11, Aero Blur on Windows 10 — with blur/opacity tunable from
  Settings.
- Single-instance: launching the app again just focuses the existing window.

## Running

```bash
flutter pub get
flutter run -d windows
```

Or use the bundled script:

```bash
run.bat
```

## Building a release

```bash
build_release.bat
```

Output lands in `dist/` (including a ready-to-ship `.zip`).

## Architecture

See the module layout under `lib/modules/` — follows the standard Flutter
Desktop blueprint (`ui/`, `native/`, `extractors/`, `models/`, `services/`).
Native Windows 10/11 theming lives in `windows/runner/theme_win10.*` and
`theme_win11.*`.

## Other languages

- [Tiếng Việt](i18n/README.vi.md)
