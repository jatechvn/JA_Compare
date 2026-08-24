import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../constants.dart';
import '../diff_engine.dart';
import '../file_service.dart';
import '../models/diff_result.dart';
import '../models/directory_diff_result.dart';
import '../utils.dart';

final _logger = Logger('DirectoryCompareService');

/// Ignored directory names to skip during recursive scan.
const Set<String> defaultIgnoredDirs = {
  '.git',
  '.github',
  '.svn',
  '.hg',
  '.dart_tool',
  'build',
  'node_modules',
  'obj',
  'bin',
  '.idea',
  '.vscode',
  '__pycache__',
  '.venv',
  'dist',
  'target',
  '.gradle',
  '.vs',
};

/// Runs the complete recursive scan/match/stat pass outside the Flutter UI
/// isolate. The record contains only isolate-sendable primitives.
Future<DirectoryDiffResult> compareDirectoriesInBackground({
  required String leftDirPath,
  required String rightDirPath,
  bool enableFuzzyMatching = true,
  double fuzzyThreshold = 0.65,
  DiffOptions diffOptions = const DiffOptions(),
}) {
  return compute(_compareDirectoriesEntry, (
    leftDirPath,
    rightDirPath,
    enableFuzzyMatching,
    fuzzyThreshold,
    diffOptions.ignoreWhitespace,
    diffOptions.ignoreCase,
    diffOptions.ignoreEmptyLines,
  ));
}

Future<DirectoryDiffResult> _compareDirectoriesEntry(
  (String, String, bool, double, bool, bool, bool) args,
) {
  return DirectoryCompareService().compareDirectories(
    leftDirPath: args.$1,
    rightDirPath: args.$2,
    enableFuzzyMatching: args.$3,
    fuzzyThreshold: args.$4,
    diffOptions: DiffOptions(
      ignoreWhitespace: args.$5,
      ignoreCase: args.$6,
      ignoreEmptyLines: args.$7,
    ),
  );
}

class DirectoryCompareService {
  final FileService _fileService;

  DirectoryCompareService({FileService? fileService})
    : _fileService = fileService ?? FileService();

  /// Recursively compares two directories and returns a [DirectoryDiffResult].
  Future<DirectoryDiffResult> compareDirectories({
    required String leftDirPath,
    required String rightDirPath,
    bool enableFuzzyMatching = true,
    double fuzzyThreshold = 0.65,
    DiffOptions diffOptions = const DiffOptions(),
    Set<String> ignoredDirectories = defaultIgnoredDirs,
  }) async {
    final sw = Stopwatch()..start();
    _logger.info('Comparing directories: "$leftDirPath" vs "$rightDirPath"');

    final leftDir = Directory(leftDirPath);
    final rightDir = Directory(rightDirPath);

    if (!await leftDir.exists()) {
      throw FileSystemException('Thư mục gốc không tồn tại', leftDirPath);
    }
    if (!await rightDir.exists()) {
      throw FileSystemException('Thư mục so sánh không tồn tại', rightDirPath);
    }

    // 1. Scan both directories recursively
    final leftFiles = await _scanDirectory(leftDir, ignoredDirectories);
    final rightFiles = await _scanDirectory(rightDir, ignoredDirectories);

    _logger.fine(
      'Scanned left: ${leftFiles.length} files, right: ${rightFiles.length} files',
    );

    final pairs = <MatchedFilePair>[];
    final remainingLeft = Map<String, FileSystemEntityInfo>.from(leftFiles);
    final remainingRight = Map<String, FileSystemEntityInfo>.from(rightFiles);

    // 2. Exact relative path matches
    final exactKeys = remainingLeft.keys
        .where((rel) => remainingRight.containsKey(rel))
        .toList();

    for (final rel in exactKeys) {
      final leftInfo = remainingLeft.remove(rel)!;
      final rightInfo = remainingRight.remove(rel)!;

      final isSame = await _areFilesIdentical(leftInfo, rightInfo);
      if (isSame) {
        pairs.add(
          MatchedFilePair(
            leftRelativePath: rel,
            leftFullPath: leftInfo.fullPath,
            leftSizeBytes: leftInfo.sizeBytes,
            rightRelativePath: rel,
            rightFullPath: rightInfo.fullPath,
            rightSizeBytes: rightInfo.sizeBytes,
            status: FilePairStatus.identical,
            similarityScore: 1.0,
          ),
        );
      } else {
        // Compute diff stats
        final stats = await _computeQuickDiffStats(
          leftInfo.fullPath,
          rightInfo.fullPath,
          diffOptions,
        );

        pairs.add(
          MatchedFilePair(
            leftRelativePath: rel,
            leftFullPath: leftInfo.fullPath,
            leftSizeBytes: leftInfo.sizeBytes,
            rightRelativePath: rel,
            rightFullPath: rightInfo.fullPath,
            rightSizeBytes: rightInfo.sizeBytes,
            status: FilePairStatus.modified,
            similarityScore: 1.0,
            diffStats: stats,
          ),
        );
      }
    }

    // 3. Fuzzy name matching for remaining files
    if (enableFuzzyMatching &&
        remainingLeft.isNotEmpty &&
        remainingRight.isNotEmpty) {
      final matchedLeftKeys = <String>{};
      final matchedRightKeys = <String>{};

      for (final leftEntry in remainingLeft.entries) {
        final leftRel = leftEntry.key;
        final leftInfo = leftEntry.value;
        final leftExt = fileExtensionOf(leftRel);

        String? bestRightKey;
        double bestScore = 0.0;

        for (final rightEntry in remainingRight.entries) {
          if (matchedRightKeys.contains(rightEntry.key)) continue;

          final rightRel = rightEntry.key;
          final rightExt = fileExtensionOf(rightRel);

          final bothTextLike =
              textLikeExtensions.contains(leftExt) &&
              textLikeExtensions.contains(rightExt);

          // Only compare if extensions match or both are text-like
          if (leftExt != rightExt && !bothTextLike) {
            continue;
          }

          final score = _calculateFilenameSimilarity(
            p.basename(leftRel),
            p.basename(rightRel),
          );

          if (score > bestScore && score >= fuzzyThreshold) {
            bestScore = score;
            bestRightKey = rightRel;
          }
        }

        if (bestRightKey != null) {
          matchedLeftKeys.add(leftRel);
          matchedRightKeys.add(bestRightKey);

          final rightInfo = remainingRight[bestRightKey]!;
          final isSame = await _areFilesIdentical(leftInfo, rightInfo);
          final stats = await _computeQuickDiffStats(
            leftInfo.fullPath,
            rightInfo.fullPath,
            diffOptions,
          );

          pairs.add(
            MatchedFilePair(
              leftRelativePath: leftRel,
              leftFullPath: leftInfo.fullPath,
              leftSizeBytes: leftInfo.sizeBytes,
              rightRelativePath: bestRightKey,
              rightFullPath: rightInfo.fullPath,
              rightSizeBytes: rightInfo.sizeBytes,
              status: isSame
                  ? FilePairStatus.identical
                  : FilePairStatus.similarName,
              similarityScore: bestScore,
              diffStats: stats,
            ),
          );
        }
      }

      for (final k in matchedLeftKeys) {
        remainingLeft.remove(k);
      }
      for (final k in matchedRightKeys) {
        remainingRight.remove(k);
      }
    }

    // 4. Left Only files
    for (final entry in remainingLeft.entries) {
      pairs.add(
        MatchedFilePair(
          leftRelativePath: entry.key,
          leftFullPath: entry.value.fullPath,
          leftSizeBytes: entry.value.sizeBytes,
          status: FilePairStatus.leftOnly,
          similarityScore: 0.0,
        ),
      );
    }

    // 5. Right Only files
    for (final entry in remainingRight.entries) {
      pairs.add(
        MatchedFilePair(
          rightRelativePath: entry.key,
          rightFullPath: entry.value.fullPath,
          rightSizeBytes: entry.value.sizeBytes,
          status: FilePairStatus.rightOnly,
          similarityScore: 0.0,
        ),
      );
    }

    // Sort pairs: modified/similarName first, then left/right only, then identical
    pairs.sort((a, b) {
      final orderA = _statusOrder(a.status);
      final orderB = _statusOrder(b.status);
      if (orderA != orderB) return orderA.compareTo(orderB);
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });

    // 6. Aggregate stats
    int identicalCount = 0;
    int modifiedCount = 0;
    int similarCount = 0;
    int leftOnlyCount = 0;
    int rightOnlyCount = 0;

    for (final p in pairs) {
      switch (p.status) {
        case FilePairStatus.identical:
          identicalCount++;
        case FilePairStatus.modified:
          modifiedCount++;
        case FilePairStatus.similarName:
          similarCount++;
        case FilePairStatus.leftOnly:
          leftOnlyCount++;
        case FilePairStatus.rightOnly:
          rightOnlyCount++;
      }
    }

    sw.stop();
    _logger.info(
      'Directory comparison finished in ${sw.elapsedMilliseconds}ms: '
      '${pairs.length} total pairs ($modifiedCount modified, $similarCount similar, '
      '$leftOnlyCount left-only, $rightOnlyCount right-only, $identicalCount identical)',
    );

    return DirectoryDiffResult(
      leftDirectoryPath: leftDirPath,
      rightDirectoryPath: rightDirPath,
      pairs: pairs,
      stats: DirectoryDiffStats(
        totalFiles: pairs.length,
        identical: identicalCount,
        modified: modifiedCount,
        similarName: similarCount,
        leftOnly: leftOnlyCount,
        rightOnly: rightOnlyCount,
      ),
      durationMs: sw.elapsedMilliseconds,
    );
  }

  int _statusOrder(FilePairStatus s) => switch (s) {
    FilePairStatus.modified => 0,
    FilePairStatus.similarName => 1,
    FilePairStatus.leftOnly => 2,
    FilePairStatus.rightOnly => 3,
    FilePairStatus.identical => 4,
  };

  /// Scans a directory recursively, returning a map of normalized relative paths -> [FileSystemEntityInfo].
  Future<Map<String, FileSystemEntityInfo>> _scanDirectory(
    Directory dir,
    Set<String> ignoredDirs,
  ) async {
    final result = <String, FileSystemEntityInfo>{};
    final rootPath = p.normalize(dir.path);

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;

      final normPath = p.normalize(entity.path);
      final rel = p.relative(normPath, from: rootPath).replaceAll('\\', '/');

      // Check if any path segment is in ignoredDirs
      final segments = rel.split('/');
      if (segments.any((s) => ignoredDirs.contains(s))) {
        continue;
      }

      // Ignore unsupported/binary files before they enter matching or
      // drill-down. Otherwise a .png/.dll can appear in the list and fail
      // later when FileService tries to extract document text.
      final ext = fileExtensionOf(rel);
      if (supportedExtensions.contains(ext)) {
        try {
          final stat = await entity.stat();
          result[rel] = FileSystemEntityInfo(
            fullPath: normPath,
            sizeBytes: stat.size,
          );
        } catch (_) {}
      }
    }

    return result;
  }

  /// Fast identity check: size check + cryptographic SHA-256 hash comparison.
  Future<bool> _areFilesIdentical(
    FileSystemEntityInfo left,
    FileSystemEntityInfo right,
  ) async {
    if (left.sizeBytes != right.sizeBytes) return false;
    if (left.sizeBytes == 0 && right.sizeBytes == 0) return true;

    try {
      final leftBytes = await File(left.fullPath).readAsBytes();
      final rightBytes = await File(right.fullPath).readAsBytes();

      if (leftBytes.length != rightBytes.length) return false;

      final leftHash = sha256.convert(leftBytes).toString();
      final rightHash = sha256.convert(rightBytes).toString();
      return leftHash == rightHash;
    } catch (_) {
      return false;
    }
  }

  /// Computes quick DiffStats (added, removed, modified line counts).
  Future<DiffStats?> _computeQuickDiffStats(
    String leftPath,
    String rightPath,
    DiffOptions options,
  ) async {
    try {
      final leftDoc = await _fileService.loadDocument(leftPath);
      final rightDoc = await _fileService.loadDocument(rightPath);

      final diff = computeDiff(leftDoc.lines, rightDoc.lines, options: options);
      return diff.stats;
    } catch (_) {
      return null;
    }
  }

  /// Calculates string similarity between two filenames (0.0 to 1.0)
  /// using normalized token Levenshtein & Dice coefficient.
  double _calculateFilenameSimilarity(String nameA, String nameB) {
    if (nameA.toLowerCase() == nameB.toLowerCase()) return 1.0;

    final normA = _normalizeName(nameA);
    final normB = _normalizeName(nameB);

    if (normA == normB) return 0.95;

    final levDist = _levenshtein(normA, normB);
    final maxLen = max(normA.length, normB.length);
    if (maxLen == 0) return 1.0;

    final levScore = 1.0 - (levDist / maxLen);

    // Bigram Dice score for substring matches
    final diceScore = _diceCoefficient(normA, normB);

    return (levScore * 0.6) + (diceScore * 0.4);
  }

  String _normalizeName(String filename) {
    var name = p.withoutExtension(filename).toLowerCase();
    // Strip common version & timestamp tags: _v1, -v2, _old, _new, _final, -2026, etc.
    name = name.replaceAll(RegExp(r'[-_]v?\d+'), '');
    name = name.replaceAll(
      RegExp(r'[-_](old|new|final|draft|copy|backup)'),
      '',
    );
    name = name.replaceAll(RegExp(r'[-_]\d{4}[-_]?\d{2}[-_]?\d{2}'), '');
    name = name.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return name.isEmpty ? filename.toLowerCase() : name;
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i <= t.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[t.length];
  }

  double _diceCoefficient(String s1, String s2) {
    if (s1.length < 2 || s2.length < 2) return s1 == s2 ? 1.0 : 0.0;

    final bigrams1 = <String, int>{};
    for (int i = 0; i < s1.length - 1; i++) {
      final bigram = s1.substring(i, i + 2);
      bigrams1[bigram] = (bigrams1[bigram] ?? 0) + 1;
    }

    int matches = 0;
    for (int i = 0; i < s2.length - 1; i++) {
      final bigram = s2.substring(i, i + 2);
      final count = bigrams1[bigram] ?? 0;
      if (count > 0) {
        matches++;
        bigrams1[bigram] = count - 1;
      }
    }

    return (2.0 * matches) / ((s1.length - 1) + (s2.length - 1));
  }
}

class FileSystemEntityInfo {
  final String fullPath;
  final int sizeBytes;

  const FileSystemEntityInfo({required this.fullPath, required this.sizeBytes});
}
