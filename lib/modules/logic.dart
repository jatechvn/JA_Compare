import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'diff_engine.dart';
import 'file_service.dart';
import 'i18n/language_provider.dart';
import 'i18n/translations.dart';
import 'models/diff_result.dart';
import 'models/history_entry.dart';
import 'services/history_service.dart';

enum ComparePaneSide { left, right }

/// Orchestrates picking/loading the two documents and running the diff.
/// UI widgets listen to this via [ChangeNotifier] and only ever read state
/// through its getters — no business logic lives in `build()`.
class CompareController extends ChangeNotifier {
  CompareController({FileService? fileService})
    : _fileService = fileService ?? FileService();

  final FileService _fileService;
  final _logger = Logger('CompareController');

  LoadedDocument? leftDocument;
  LoadedDocument? rightDocument;
  DiffResult? diffResult;
  bool isLoading = false;
  String? errorMessage;

  bool get canCompare =>
      leftDocument != null && rightDocument != null && !isLoading;
  bool get hasResult => diffResult != null;

  Future<void> pickFile(ComparePaneSide side) async {
    final path = await _fileService.pickFile();
    if (path == null) return;
    await loadFile(side, path);
  }

  Future<void> loadFile(ComparePaneSide side, String path) async {
    errorMessage = null;
    isLoading = true;
    notifyListeners();
    try {
      final doc = await _fileService.loadDocument(path);
      if (side == ComparePaneSide.left) {
        leftDocument = doc;
      } else {
        rightDocument = doc;
      }
      diffResult = null; // a new pick invalidates any previous comparison
    } catch (e) {
      _logger.warning('Failed to load $path: $e');
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> compare() async {
    final left = leftDocument;
    final right = rightDocument;
    if (left == null || right == null) return;

    errorMessage = null;
    isLoading = true;
    notifyListeners();
    try {
      diffResult = await computeDiffInBackground(left.lines, right.lines);
      HistoryService.add(
        HistoryEntry(
          leftPath: left.path,
          rightPath: right.path,
          leftName: left.name,
          rightName: right.name,
          comparedAt: DateTime.now(),
          added: diffResult!.stats.added,
          removed: diffResult!.stats.removed,
          modified: diffResult!.stats.modified,
        ),
      );
    } catch (e) {
      _logger.severe('Diff failed: $e');
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Re-loads both files from a past [HistoryEntry] and re-runs the diff —
  /// used by the History dialog's "open again" action. Files are re-read
  /// (not cached) since they may have changed since the original comparison.
  Future<void> reopenFromHistory(
    HistoryEntry entry, {
    required AppLanguage language,
  }) async {
    if (!File(entry.leftPath).existsSync() ||
        !File(entry.rightPath).existsSync()) {
      errorMessage = translate(language, 'history_file_missing');
      notifyListeners();
      return;
    }
    await loadFile(ComparePaneSide.left, entry.leftPath);
    if (errorMessage != null) return;
    await loadFile(ComparePaneSide.right, entry.rightPath);
    if (errorMessage != null) return;
    await compare();
  }

  void reset() {
    leftDocument = null;
    rightDocument = null;
    diffResult = null;
    errorMessage = null;
    notifyListeners();
  }
}
