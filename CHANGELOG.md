# Changelog

All notable changes to JA Compare are documented here.

## [v2.0.2] - 2026-08-24

### Enhancements

- Added one-step drag-and-drop for two files or two folders anywhere in the
  application.
- Added a clear green result banner when compared files are identical.
- Moved normal and debug runtime logs beside the application executable.
- Updated the About and User Guide content for the new comparison workflow.

### Fixed

- Made Excel parsing tolerant of built-in-style `numFmtId` values, duplicate
  shared strings, and distant style-only worksheet rows found in real files.

### Release

- Rebuilt the Windows x64 portable package as `v2.0.2`.

## [v2.0.1] - 2026-08-24

### Fixed

- Folder comparisons are now recorded in comparison history.
- Folder history entries are identified separately from file entries and can be
  reopened directly.
- Existing file-only history data remains backward compatible.
- The history dialog now shows a folder icon for directory comparisons.

### Documentation

- Updated the in-app User Guide and About metadata for folder comparison history.
- Added release and project documentation for the v2.0.1 Windows build.

## [v2.0.0]

- See the repository history for the preceding feature release.
