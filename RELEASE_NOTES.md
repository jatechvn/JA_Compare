TAG=v2.0.2
TITLE=JA Compare v2.0.2
BODY=
## Highlights

- Real-world Excel files with non-standard styles, duplicate shared strings, and
  distant style-only rows now parse successfully.
- Drop two files or two folders anywhere in the app to populate both comparison
  sides automatically.
- Identical file comparisons show a clear green confirmation banner.
- Normal and debug logs are written beside the packaged executable in `logs/`.
- Updated About, User Guide, README, and Vietnamese documentation.

## Verification

- `flutter analyze` — passed
- `flutter test` — passed
- `flutter build windows --release` — passed
- Windows x64 ZIP package generated with one parent folder and no runtime state.

## Links

- Website: https://jatechvn.github.io/
- Repository: https://github.com/jatechvn/JA_Compare
