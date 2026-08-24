import 'diff_result.dart';

/// Status of a file pair in directory comparison.
enum FilePairStatus {
  /// Both files exist with identical content.
  identical,

  /// Both files exist at same or matched path, but contents differ.
  modified,

  /// Two files matched by fuzzy name similarity (e.g. `report_v1.docx` vs `report_v2.docx`).
  similarName,

  /// File only exists in the left directory (deleted or unique to left).
  leftOnly,

  /// File only exists in the right directory (newly added or unique to right).
  rightOnly,
}

/// A matched pair of files between left and right directories.
class MatchedFilePair {
  final String? leftRelativePath;
  final String? leftFullPath;
  final int? leftSizeBytes;

  final String? rightRelativePath;
  final String? rightFullPath;
  final int? rightSizeBytes;

  final FilePairStatus status;
  final double similarityScore; // 0.0 to 1.0 (1.0 = exact name match)

  DiffStats? diffStats;
  DiffResult? diffResult;

  MatchedFilePair({
    this.leftRelativePath,
    this.leftFullPath,
    this.leftSizeBytes,
    this.rightRelativePath,
    this.rightFullPath,
    this.rightSizeBytes,
    required this.status,
    this.similarityScore = 1.0,
    this.diffStats,
    this.diffResult,
  });

  String get displayName =>
      rightRelativePath ?? leftRelativePath ?? 'Unknown file';

  String get fileExtension {
    final path = rightRelativePath ?? leftRelativePath ?? '';
    final dot = path.lastIndexOf('.');
    return dot != -1 ? path.substring(dot + 1).toLowerCase() : '';
  }

  bool get hasDifferences =>
      status == FilePairStatus.modified ||
      status == FilePairStatus.similarName ||
      status == FilePairStatus.leftOnly ||
      status == FilePairStatus.rightOnly;
}

/// Aggregate statistics for directory comparison.
class DirectoryDiffStats {
  final int totalFiles;
  final int identical;
  final int modified;
  final int similarName;
  final int leftOnly;
  final int rightOnly;

  const DirectoryDiffStats({
    required this.totalFiles,
    required this.identical,
    required this.modified,
    required this.similarName,
    required this.leftOnly,
    required this.rightOnly,
  });

  bool get hasDifferences =>
      modified > 0 || similarName > 0 || leftOnly > 0 || rightOnly > 0;
}

/// Full result of comparing two directories.
class DirectoryDiffResult {
  final String leftDirectoryPath;
  final String rightDirectoryPath;
  final List<MatchedFilePair> pairs;
  final DirectoryDiffStats stats;
  final int durationMs;

  const DirectoryDiffResult({
    required this.leftDirectoryPath,
    required this.rightDirectoryPath,
    required this.pairs,
    required this.stats,
    required this.durationMs,
  });
}
