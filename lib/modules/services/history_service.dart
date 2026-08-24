import 'dart:convert';
import 'dart:io';

import '../models/history_entry.dart';
import 'app_storage_service.dart';

/// Persists the list of past comparisons to `history.json` (most recent
/// first), capped at [maxEntries] so the file can't grow unbounded.
class HistoryService {
  HistoryService._();

  static const int maxEntries = 50;

  static File get _historyFile => AppStorageService.file('history.json');

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

  /// Records a file or folder comparison, moving it to the front if the same
  /// pair and comparison type was already recorded.
  static void add(HistoryEntry entry) {
    final list = load()
      ..removeWhere(
        (e) =>
            e.leftPath == entry.leftPath &&
            e.rightPath == entry.rightPath &&
            e.isFolder == entry.isFolder,
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
            e.isFolder == entry.isFolder &&
            e.comparedAt == entry.comparedAt,
      );
    _save(list);
  }

  static void clear() {
    try {
      if (_historyFile.existsSync()) _historyFile.deleteSync();
    } catch (_) {}
  }

  static void _save(List<HistoryEntry> list) {
    try {
      _historyFile.writeAsStringSync(
        jsonEncode(list.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }
}
