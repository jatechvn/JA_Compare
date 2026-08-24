import 'dart:io';

import 'app_storage_service.dart';

/// Reads and writes app preferences from a simple section-based
/// `config.ini` — glassmorphism blur/opacity (`[glassmorphism]`) and the
/// last-used UI language (`[general]`). Hand-rolled rather than pulling in
/// an INI package — there are only a handful of keys to persist, split
/// across two sections that must survive independent read/write cycles.
class SettingsService {
  SettingsService._();

  static const Map<String, double> _glassDefaults = {
    'bg_blur': 10.0,
    'bg_opacity': 0.6,
    'dialog_blur': 2.0,
    'dialog_opacity': 0.8,
  };
  static const String _defaultLanguageCode = 'vi';

  static File get _configFile => AppStorageService.file('config.ini');

  static Map<String, double> get defaultSettings =>
      Map<String, double>.from(_glassDefaults);

  /// Parses `config.ini` into `{section: {key: value}}`. Keys that appear
  /// before any `[section]` header are dropped (the file always starts
  /// with a section header in practice).
  static Map<String, Map<String, String>> _readAll() {
    final result = <String, Map<String, String>>{};
    final file = _configFile;
    if (!file.existsSync()) return result;

    var section = '';
    try {
      for (final rawLine in file.readAsLinesSync()) {
        final line = rawLine.trim();
        if (line.isEmpty || line.startsWith('#') || line.startsWith(';')) {
          continue;
        }
        if (line.startsWith('[') && line.endsWith(']')) {
          section = line.substring(1, line.length - 1).trim();
          result.putIfAbsent(section, () => {});
          continue;
        }
        final sep = line.indexOf('=');
        if (sep == -1) continue;
        final key = line.substring(0, sep).trim();
        final value = line.substring(sep + 1).trim();
        result.putIfAbsent(section, () => {})[key] = value;
      }
    } catch (_) {}
    return result;
  }

  static void _writeAll(Map<String, Map<String, String>> data) {
    final buffer = StringBuffer();
    for (final section in data.keys) {
      buffer.writeln('[$section]');
      for (final entry in data[section]!.entries) {
        buffer.writeln('${entry.key}=${entry.value}');
      }
      buffer.writeln();
    }
    try {
      _configFile.writeAsStringSync(buffer.toString());
    } catch (_) {
      // Settings are optional; keep the current session usable when the
      // profile directory is temporarily unavailable or read-only.
    }
  }

  /// Loads persisted glassmorphism settings, falling back to defaults for
  /// any missing or malformed key.
  static Map<String, double> loadSettings() {
    final glass = _readAll()['glassmorphism'] ?? const {};
    final result = Map<String, double>.from(_glassDefaults);
    for (final key in result.keys) {
      final parsed = double.tryParse(glass[key] ?? '');
      if (parsed != null) result[key] = parsed;
    }
    return result;
  }

  /// Merges [values] into the persisted glassmorphism settings and writes
  /// `config.ini`, preserving the `[general]` section untouched.
  static void saveSettings(Map<String, double> values) {
    final all = _readAll();
    final merged = {...loadSettings(), ...values};
    all['glassmorphism'] = merged.map((k, v) => MapEntry(k, v.toString()));
    _writeAll(all);
  }

  static void resetToDefaults() =>
      saveSettings(Map<String, double>.from(_glassDefaults));

  /// Loads the last-used UI language code (`en`/`vi`/`zh`), defaulting to
  /// `vi` if never set.
  static String loadLanguage() =>
      _readAll()['general']?['language'] ?? _defaultLanguageCode;

  /// Persists the current UI language, preserving `[glassmorphism]`
  /// untouched.
  static void saveLanguage(String code) {
    final all = _readAll();
    all.putIfAbsent('general', () => {})['language'] = code;
    _writeAll(all);
  }
}
