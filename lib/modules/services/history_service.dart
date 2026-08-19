import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/history_entry.dart';

/// Persists the list of past comparisons to `history.json` (most recent
/// first), capped at [maxEntries] so the file can't grow unbounded.
class HistoryService {
  HistoryService._();

  static const int maxEntries = 50;

  static File get _historyFile =>
      File(p.join(Directory.current.path, 'history.json'));

  static List<HistoryEntry> load() {
    final file = _historyFile;
    if (!file.existsSync()) return [];
    try {
      final raw = jsonDecode(file.readAsStringSync()) as List;
      return raw
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Records a comparison, moving it to the front if the same file pair
  /// was already recorded.
  static void add(HistoryEntry entry) {
    final list = load()
      ..removeWhere(
        (e) => e.leftPath == entry.leftPath && e.rightPath == entry.rightPath,
      )
      ..insert(0, entry);
    if (list.length > maxEntries) list.removeRange(maxEntries, list.length);
    _save(list);
  }

  static void remove(HistoryEntry entry) {
    final list = load()
      ..removeWhere(
        (e) =>
            e.leftPath == entry.leftPath &&
            e.rightPath == entry.rightPath &&
            e.comparedAt == entry.comparedAt,
      );
    _save(list);
  }

  static void clear() {
    if (_historyFile.existsSync()) _historyFile.deleteSync();
  }

  static void _save(List<HistoryEntry> list) {
    _historyFile.writeAsStringSync(
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }
}
