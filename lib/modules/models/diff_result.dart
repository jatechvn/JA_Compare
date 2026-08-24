/// Classification of a single row in the side-by-side diff view.
enum DiffType {
  /// Present, identical, on both sides.
  equal,

  /// Present only on the right (new) side.
  insert,

  /// Present only on the left (old) side.
  delete,

  /// Present on both sides but with different content — an aligned
  /// delete+insert pair rendered on the same row.
  modify,
}

/// Intra-line diff segment type for word/character level highlighting.
enum DiffSegmentType { equal, insert, delete }

/// A slice of text inside a modified line with granular diff classification.
class DiffSegment {
  final DiffSegmentType type;
  final String text;

  const DiffSegment(this.type, this.text);
}

/// One row of the diff view. `leftText`/`rightText` are null when that side
/// has no counterpart for this row (pure insert/delete).
class DiffLine {
  final DiffType type;
  final String? leftText;
  final String? rightText;
  final int? leftLineNo;
  final int? rightLineNo;
  final List<DiffSegment>? leftSegments;
  final List<DiffSegment>? rightSegments;

  const DiffLine({
    required this.type,
    this.leftText,
    this.rightText,
    this.leftLineNo,
    this.rightLineNo,
    this.leftSegments,
    this.rightSegments,
  });
}

/// Comparison configuration options.
class DiffOptions {
  final bool ignoreWhitespace;
  final bool ignoreCase;
  final bool ignoreEmptyLines;

  const DiffOptions({
    this.ignoreWhitespace = false,
    this.ignoreCase = false,
    this.ignoreEmptyLines = false,
  });

  DiffOptions copyWith({
    bool? ignoreWhitespace,
    bool? ignoreCase,
    bool? ignoreEmptyLines,
  }) {
    return DiffOptions(
      ignoreWhitespace: ignoreWhitespace ?? this.ignoreWhitespace,
      ignoreCase: ignoreCase ?? this.ignoreCase,
      ignoreEmptyLines: ignoreEmptyLines ?? this.ignoreEmptyLines,
    );
  }
}

/// Aggregate counts shown in the comparison summary bar.
class DiffStats {
  final int added;
  final int removed;
  final int modified;
  final int unchanged;

  const DiffStats({
    required this.added,
    required this.removed,
    required this.modified,
    required this.unchanged,
  });

  bool get hasDifferences => added > 0 || removed > 0 || modified > 0;
  int get totalChanges => added + removed + modified;
}

class DiffResult {
  final List<DiffLine> lines;
  final DiffStats stats;

  const DiffResult({required this.lines, required this.stats});
}
