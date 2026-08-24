import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TextEditingController;
import 'package:flutter/services.dart' show Clipboard;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'diff_engine.dart';
import 'file_service.dart';
import 'i18n/language_provider.dart';
import 'i18n/translations.dart';
import 'models/diff_result.dart';
import 'models/directory_diff_result.dart';
import 'models/history_entry.dart';
import 'sample_presets.dart';
import 'services/directory_compare_service.dart';
import 'services/history_service.dart';

enum ComparePaneSide { left, right }

enum CompareMode { files, folders, directText }

/// Orchestrates picking/loading documents, directories, or direct text buffers and running the diff.
/// UI widgets listen to this via [ChangeNotifier] and only ever read state
/// through its getters — no business logic lives in `build()`.
class CompareController extends ChangeNotifier {
  CompareController({
    FileService? fileService,
    DirectoryCompareService? directoryService,
  }) : _fileService = fileService ?? FileService(),
       _directoryService = directoryService ?? DirectoryCompareService(),
       _usesDefaultDirectoryService = directoryService == null {
    leftTextController.addListener(_onTextChanged);
    rightTextController.addListener(_onTextChanged);
  }

  final FileService _fileService;
  final DirectoryCompareService _directoryService;
  final bool _usesDefaultDirectoryService;
  final _logger = Logger('CompareController');
  int _compareGeneration = 0;

  CompareMode mode = CompareMode.files;

  // Single file mode
  LoadedDocument? leftDocument;
  LoadedDocument? rightDocument;
  DiffResult? diffResult;

  // Direct text mode
  final TextEditingController leftTextController = TextEditingController();
  final TextEditingController rightTextController = TextEditingController();

  // Directory mode
  String? leftDirectoryPath;
  String? rightDirectoryPath;
  DirectoryDiffResult? directoryResult;
  bool enableFuzzyMatching = true;
  double fuzzyThreshold = 0.65;
  MatchedFilePair? activeDrillDownPair;
  String directoryFilter =
      'all'; // 'all', 'modified', 'similar', 'leftOnly', 'rightOnly', 'identical'
  String directorySearchQuery = '';

  DiffOptions diffOptions = const DiffOptions();
  bool isLoading = false;
  String? errorMessage;
  int lastDiffDurationMs = 0;

  void _onTextChanged() {
    if (mode == CompareMode.directText) _invalidatePendingCompare();
    if (mode == CompareMode.directText && diffResult != null) {
      diffResult = null;
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    leftTextController.removeListener(_onTextChanged);
    rightTextController.removeListener(_onTextChanged);
    leftTextController.dispose();
    rightTextController.dispose();
    super.dispose();
  }

  void setMode(CompareMode newMode) {
    if (mode == newMode) return;
    _invalidatePendingCompare();
    mode = newMode;
    diffResult = null;
    directoryResult = null;
    activeDrillDownPair = null;
    errorMessage = null;
    notifyListeners();
  }

  void updateDiffOptions(DiffOptions options) {
    diffOptions = options;
    if (hasResult) {
      compare();
    } else {
      notifyListeners();
    }
  }

  bool get canCompare {
    if (isLoading) return false;
    if (mode == CompareMode.files) {
      return leftDocument != null && rightDocument != null;
    } else if (mode == CompareMode.folders) {
      return leftDirectoryPath != null && rightDirectoryPath != null;
    } else {
      // An empty side is meaningful in a diff: it represents a complete
      // insertion or deletion. Only disable Compare when both sides are empty.
      return leftTextController.text.isNotEmpty ||
          rightTextController.text.isNotEmpty;
    }
  }

  bool get hasResult {
    if (mode == CompareMode.folders) {
      return directoryResult != null;
    }
    return diffResult != null;
  }

  bool get hasAnyContent {
    if (mode == CompareMode.files) {
      return leftDocument != null || rightDocument != null;
    } else if (mode == CompareMode.folders) {
      return leftDirectoryPath != null || rightDirectoryPath != null;
    } else {
      return leftTextController.text.isNotEmpty ||
          rightTextController.text.isNotEmpty;
    }
  }

  // --- Single File actions ---
  Future<void> pickFile(ComparePaneSide side) async {
    final path = await _fileService.pickFile();
    if (path == null) return;
    await loadFile(side, path);
  }

  Future<void> loadFile(ComparePaneSide side, String path) async {
    _invalidatePendingCompare();
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
      diffResult = null;
    } catch (e) {
      _logger.warning('Failed to load $path: $e');
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Loads a pair dropped anywhere in the app and selects the matching mode.
  /// A pair must contain two files or two directories; mixed pairs are not
  /// comparable in one operation.
  Future<void> loadDroppedPair(Iterable<String> rawPaths) async {
    final paths = rawPaths
        .where((path) => path.trim().isNotEmpty)
        .toSet()
        .toList();
    if (paths.length != 2) {
      errorMessage = 'Hãy thả đúng 2 tệp hoặc 2 thư mục để so sánh';
      notifyListeners();
      return;
    }

    final types = paths
        .map((path) => FileSystemEntity.typeSync(path, followLinks: false))
        .toList();
    final areFiles = types.every((type) => type == FileSystemEntityType.file);
    final areDirectories = types.every(
      (type) => type == FileSystemEntityType.directory,
    );
    if (!areFiles && !areDirectories) {
      errorMessage = 'Hãy thả 2 tệp hoặc 2 thư mục cùng loại';
      notifyListeners();
      return;
    }

    if (areFiles) {
      if (mode != CompareMode.files) setMode(CompareMode.files);
      await _loadDroppedFilePair(paths);
      return;
    }

    if (mode != CompareMode.folders) setMode(CompareMode.folders);
    _invalidatePendingCompare();
    errorMessage = null;
    leftDirectoryPath = paths[0];
    rightDirectoryPath = paths[1];
    directoryResult = null;
    activeDrillDownPair = null;
    notifyListeners();
  }

  Future<void> _loadDroppedFilePair(List<String> paths) async {
    _invalidatePendingCompare();
    errorMessage = null;
    isLoading = true;
    notifyListeners();
    try {
      final documents = await Future.wait(
        paths.map((path) => _fileService.loadDocument(path)),
      );
      leftDocument = documents[0];
      rightDocument = documents[1];
      diffResult = null;
    } catch (e) {
      _logger.warning('Failed to load dropped file pair: $e');
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- Directory actions ---
  Future<void> pickDirectory(ComparePaneSide side) async {
    final path = await _fileService.pickDirectory();
    if (path == null) return;
    await loadDirectory(side, path);
  }

  Future<void> loadDirectory(ComparePaneSide side, String path) async {
    _invalidatePendingCompare();
    errorMessage = null;
    final type = FileSystemEntity.typeSync(path, followLinks: false);
    if (type != FileSystemEntityType.directory) {
      errorMessage = 'Đường dẫn không phải là thư mục hợp lệ';
      notifyListeners();
      return;
    }
    if (side == ComparePaneSide.left) {
      leftDirectoryPath = path;
    } else {
      rightDirectoryPath = path;
    }
    directoryResult = null;
    activeDrillDownPair = null;
    notifyListeners();
  }

  void toggleFuzzyMatching(bool enabled) {
    enableFuzzyMatching = enabled;
    if (directoryResult != null) {
      compare();
    } else {
      notifyListeners();
    }
  }

  void setFuzzyThreshold(double val) {
    fuzzyThreshold = val;
    if (directoryResult != null) {
      compare();
    } else {
      notifyListeners();
    }
  }

  void setDirectoryFilter(String filter) {
    directoryFilter = filter;
    notifyListeners();
  }

  void setDirectorySearchQuery(String query) {
    directorySearchQuery = query;
    notifyListeners();
  }

  List<MatchedFilePair> get filteredDirectoryPairs {
    if (directoryResult == null) return const [];
    var list = directoryResult!.pairs;

    // Filter by status tab
    if (directoryFilter == 'modified') {
      list = list.where((p) => p.status == FilePairStatus.modified).toList();
    } else if (directoryFilter == 'similar') {
      list = list.where((p) => p.status == FilePairStatus.similarName).toList();
    } else if (directoryFilter == 'leftOnly') {
      list = list.where((p) => p.status == FilePairStatus.leftOnly).toList();
    } else if (directoryFilter == 'rightOnly') {
      list = list.where((p) => p.status == FilePairStatus.rightOnly).toList();
    } else if (directoryFilter == 'identical') {
      list = list.where((p) => p.status == FilePairStatus.identical).toList();
    }

    // Filter by search query
    if (directorySearchQuery.trim().isNotEmpty) {
      final q = directorySearchQuery.trim().toLowerCase();
      list = list.where((p) {
        final l = p.leftRelativePath?.toLowerCase() ?? '';
        final r = p.rightRelativePath?.toLowerCase() ?? '';
        return l.contains(q) || r.contains(q);
      }).toList();
    }

    return list;
  }

  Future<void> selectDrillDownPair(MatchedFilePair pair) async {
    if (pair.diffResult != null) {
      activeDrillDownPair = pair;
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final leftPath = pair.leftFullPath;
      final rightPath = pair.rightFullPath;

      List<String> leftLines = const [];
      List<String> rightLines = const [];

      if (leftPath != null && File(leftPath).existsSync()) {
        final leftDoc = await _fileService.loadDocument(leftPath);
        leftLines = leftDoc.lines;
      }

      if (rightPath != null && File(rightPath).existsSync()) {
        final rightDoc = await _fileService.loadDocument(rightPath);
        rightLines = rightDoc.lines;
      }

      final diff = await computeDiffInBackground(
        leftLines,
        rightLines,
        options: diffOptions,
      );

      pair.diffResult = diff;
      pair.diffStats = diff.stats;
      activeDrillDownPair = pair;
    } catch (e) {
      _logger.warning('Failed to compute drill-down diff: $e');
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearDrillDown() {
    activeDrillDownPair = null;
    notifyListeners();
  }

  Future<void> nextDrillDownPair() async {
    final list = filteredDirectoryPairs;
    if (list.isEmpty || activeDrillDownPair == null) return;
    final idx = list.indexOf(activeDrillDownPair!);
    if (idx != -1 && idx < list.length - 1) {
      await selectDrillDownPair(list[idx + 1]);
    }
  }

  Future<void> prevDrillDownPair() async {
    final list = filteredDirectoryPairs;
    if (list.isEmpty || activeDrillDownPair == null) return;
    final idx = list.indexOf(activeDrillDownPair!);
    if (idx > 0) {
      await selectDrillDownPair(list[idx - 1]);
    }
  }

  // --- Clipboard & Presets ---
  Future<void> pasteFromClipboard(ComparePaneSide side) async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text == null || text.isEmpty) return;

      if (mode == CompareMode.files) {
        final lines = text.split(RegExp(r'\r?\n'));
        final doc = LoadedDocument(
          path: '',
          name: side == ComparePaneSide.left
              ? 'Clipboard (Left)'
              : 'Clipboard (Right)',
          extension: 'txt',
          sizeBytes: text.length,
          lines: lines,
        );
        if (side == ComparePaneSide.left) {
          leftDocument = doc;
        } else {
          rightDocument = doc;
        }
        diffResult = null;
        notifyListeners();
      } else if (mode == CompareMode.directText) {
        if (side == ComparePaneSide.left) {
          leftTextController.text = text;
        } else {
          rightTextController.text = text;
        }
      }
    } catch (e) {
      _logger.warning('Failed to paste from clipboard: $e');
    }
  }

  void swap() {
    _invalidatePendingCompare();
    if (mode == CompareMode.files) {
      final temp = leftDocument;
      leftDocument = rightDocument;
      rightDocument = temp;
      diffResult = null;
    } else if (mode == CompareMode.folders) {
      final temp = leftDirectoryPath;
      leftDirectoryPath = rightDirectoryPath;
      rightDirectoryPath = temp;
      directoryResult = null;
      activeDrillDownPair = null;
    } else {
      final temp = leftTextController.text;
      leftTextController.text = rightTextController.text;
      rightTextController.text = temp;
      diffResult = null;
    }
    notifyListeners();
  }

  void clearSide(ComparePaneSide side) {
    _invalidatePendingCompare();
    if (mode == CompareMode.files) {
      if (side == ComparePaneSide.left) {
        leftDocument = null;
      } else {
        rightDocument = null;
      }
      diffResult = null;
    } else if (mode == CompareMode.folders) {
      if (side == ComparePaneSide.left) {
        leftDirectoryPath = null;
      } else {
        rightDirectoryPath = null;
      }
      directoryResult = null;
      activeDrillDownPair = null;
    } else {
      if (side == ComparePaneSide.left) {
        leftTextController.clear();
      } else {
        rightTextController.clear();
      }
      diffResult = null;
    }
    notifyListeners();
  }

  void clearBoth() {
    _invalidatePendingCompare();
    leftDocument = null;
    rightDocument = null;
    leftDirectoryPath = null;
    rightDirectoryPath = null;
    leftTextController.clear();
    rightTextController.clear();
    diffResult = null;
    directoryResult = null;
    activeDrillDownPair = null;
    errorMessage = null;
    notifyListeners();
  }

  void loadPreset(SamplePreset preset) {
    if (mode == CompareMode.directText) {
      leftTextController.text = preset.leftContent;
      rightTextController.text = preset.rightContent;
    } else {
      mode = CompareMode.files;
      leftDocument = LoadedDocument(
        path: preset.leftName,
        name: preset.leftName,
        extension: preset.leftName.split('.').last,
        sizeBytes: preset.leftContent.length,
        lines: preset.leftContent.split(RegExp(r'\r?\n')),
      );
      rightDocument = LoadedDocument(
        path: preset.rightName,
        name: preset.rightName,
        extension: preset.rightName.split('.').last,
        sizeBytes: preset.rightContent.length,
        lines: preset.rightContent.split(RegExp(r'\r?\n')),
      );
    }
    compare();
  }

  Future<void> compare() async {
    if (!canCompare) return;

    final requestId = ++_compareGeneration;
    final compareMode = mode;
    final compareLeftDirectory = leftDirectoryPath;
    final compareRightDirectory = rightDirectoryPath;
    errorMessage = null;
    isLoading = true;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    try {
      if (compareMode == CompareMode.folders) {
        final result = _usesDefaultDirectoryService
            ? await compareDirectoriesInBackground(
                leftDirPath: compareLeftDirectory!,
                rightDirPath: compareRightDirectory!,
                enableFuzzyMatching: enableFuzzyMatching,
                fuzzyThreshold: fuzzyThreshold,
                diffOptions: diffOptions,
              )
            : await _directoryService.compareDirectories(
                leftDirPath: compareLeftDirectory!,
                rightDirPath: compareRightDirectory!,
                enableFuzzyMatching: enableFuzzyMatching,
                fuzzyThreshold: fuzzyThreshold,
                diffOptions: diffOptions,
              );
        if (requestId != _compareGeneration) return;
        directoryResult = result;
        stopwatch.stop();
        lastDiffDurationMs = directoryResult!.durationMs;
        HistoryService.add(
          HistoryEntry(
            leftPath: result.leftDirectoryPath,
            rightPath: result.rightDirectoryPath,
            leftName: _directoryDisplayName(result.leftDirectoryPath),
            rightName: _directoryDisplayName(result.rightDirectoryPath),
            comparedAt: DateTime.now(),
            added: result.stats.rightOnly,
            removed: result.stats.leftOnly,
            modified: result.stats.modified + result.stats.similarName,
            isFolder: true,
          ),
        );
      } else {
        List<String> leftLines;
        List<String> rightLines;
        String leftName;
        String rightName;
        String leftPath;
        String rightPath;

        if (compareMode == CompareMode.files) {
          leftLines = leftDocument!.lines;
          rightLines = rightDocument!.lines;
          leftName = leftDocument!.name;
          rightName = rightDocument!.name;
          leftPath = leftDocument!.path;
          rightPath = rightDocument!.path;
        } else {
          leftLines = leftTextController.text.split(RegExp(r'\r?\n'));
          rightLines = rightTextController.text.split(RegExp(r'\r?\n'));
          leftName = 'Direct Text (Left)';
          rightName = 'Direct Text (Right)';
          leftPath = '';
          rightPath = '';
        }

        final result = await computeDiffInBackground(
          leftLines,
          rightLines,
          options: diffOptions,
        );
        if (requestId != _compareGeneration) return;
        diffResult = result;

        stopwatch.stop();
        lastDiffDurationMs = stopwatch.elapsedMilliseconds;

        if (leftPath.isNotEmpty && rightPath.isNotEmpty) {
          HistoryService.add(
            HistoryEntry(
              leftPath: leftPath,
              rightPath: rightPath,
              leftName: leftName,
              rightName: rightName,
              comparedAt: DateTime.now(),
              added: diffResult!.stats.added,
              removed: diffResult!.stats.removed,
              modified: diffResult!.stats.modified,
            ),
          );
        }
      }
    } catch (e) {
      if (requestId != _compareGeneration) return;
      _logger.severe('Diff failed: $e');
      errorMessage = e.toString();
    } finally {
      if (requestId == _compareGeneration) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> reopenFromHistory(
    HistoryEntry entry, {
    required AppLanguage language,
  }) async {
    if (entry.isFolder) {
      if (!Directory(entry.leftPath).existsSync() ||
          !Directory(entry.rightPath).existsSync()) {
        errorMessage = translate(language, 'history_folder_missing');
        notifyListeners();
        return;
      }
      setMode(CompareMode.folders);
      await loadDirectory(ComparePaneSide.left, entry.leftPath);
      await loadDirectory(ComparePaneSide.right, entry.rightPath);
      await compare();
      return;
    }

    if (!File(entry.leftPath).existsSync() ||
        !File(entry.rightPath).existsSync()) {
      errorMessage = translate(language, 'history_file_missing');
      notifyListeners();
      return;
    }
    setMode(CompareMode.files);
    await loadFile(ComparePaneSide.left, entry.leftPath);
    if (errorMessage != null) return;
    await loadFile(ComparePaneSide.right, entry.rightPath);
    if (errorMessage != null) return;
    await compare();
  }

  void reset() {
    _invalidatePendingCompare();
    diffResult = null;
    directoryResult = null;
    activeDrillDownPair = null;
    errorMessage = null;
    notifyListeners();
  }

  void _invalidatePendingCompare() {
    _compareGeneration++;
    isLoading = false;
  }
}

String _directoryDisplayName(String path) {
  final normalized = p.normalize(path);
  final name = p.basename(normalized);
  return name.isEmpty ? normalized : name;
}
