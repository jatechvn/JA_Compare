import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter/foundation.dart' show compute;

import 'models/diff_result.dart';

/// Runs [computeDiff] on a background isolate via [compute] so a large
/// document pair doesn't block the UI thread while diffing.
Future<DiffResult> computeDiffInBackground(
  List<String> leftLines,
  List<String> rightLines, {
  DiffOptions options = const DiffOptions(),
}) {
  return compute(_computeDiffEntry, (leftLines, rightLines, options));
}

DiffResult _computeDiffEntry((List<String>, List<String>, DiffOptions) args) =>
    computeDiff(args.$1, args.$2, options: args.$3);

String _normalizeLine(String line, DiffOptions options) {
  var s = line;
  if (options.ignoreWhitespace) {
    s = s.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
  if (options.ignoreCase) {
    s = s.toLowerCase();
  }
  return s;
}

class _LineTokenizer {
  final Map<String, int> _normToIndex = {};
  int _nextIndex = 0;

  String tokenize(List<String> input, DiffOptions options) {
    final buffer = StringBuffer();
    for (final line in input) {
      final norm = _normalizeLine(line, options);
      var index = _normToIndex[norm];
      if (index == null) {
        index = _nextIndex++;
        _normToIndex[norm] = index;
      }
      buffer.writeCharCode(_codeUnitForIndex(index));
    }
    return buffer.toString();
  }

  static int _codeUnitForIndex(int index) {
    const start = 0x0021; // skip C0 control range
    var code = start + index;
    if (code >= 0xD800) code += 0xE000 - 0xD800; // jump over surrogates
    return code;
  }
}

class _RawLine {
  final DiffType type;
  final String leftText;
  final String? rightText;
  const _RawLine(this.type, this.leftText, {this.rightText});
}

(List<DiffSegment>, List<DiffSegment>) _computeIntraLineSegments(
  String left,
  String right,
) {
  final dmp = diff(left, right, checklines: false);
  cleanupSemantic(dmp);

  final leftSegments = <DiffSegment>[];
  final rightSegments = <DiffSegment>[];

  for (final d in dmp) {
    if (d.text.isEmpty) continue;
    if (d.operation == DIFF_EQUAL) {
      leftSegments.add(DiffSegment(DiffSegmentType.equal, d.text));
      rightSegments.add(DiffSegment(DiffSegmentType.equal, d.text));
    } else if (d.operation == DIFF_DELETE) {
      leftSegments.add(DiffSegment(DiffSegmentType.delete, d.text));
    } else if (d.operation == DIFF_INSERT) {
      rightSegments.add(DiffSegment(DiffSegmentType.insert, d.text));
    }
  }

  return (leftSegments, rightSegments);
}

/// Runs a line-level diff between [leftLines] and [rightLines] with optional [options]
/// and returns a [DiffResult] with intra-line segments ready for the diff view.
DiffResult computeDiff(
  List<String> leftLines,
  List<String> rightLines, {
  DiffOptions options = const DiffOptions(),
}) {
  var effectiveLeft = leftLines;
  var effectiveRight = rightLines;

  if (options.ignoreEmptyLines) {
    effectiveLeft = effectiveLeft.where((l) => l.trim().isNotEmpty).toList();
    effectiveRight = effectiveRight.where((l) => l.trim().isNotEmpty).toList();
  }

  final tokenizer = _LineTokenizer();
  final encodedLeft = tokenizer.tokenize(effectiveLeft, options);
  final encodedRight = tokenizer.tokenize(effectiveRight, options);

  final rawDiffs = diff(encodedLeft, encodedRight, checklines: false);

  var leftCursor = 0;
  var rightCursor = 0;
  final flat = <_RawLine>[];

  for (final d in rawDiffs) {
    final len = d.text.length;
    if (d.operation == DIFF_EQUAL) {
      for (var k = 0; k < len; k++) {
        flat.add(
          _RawLine(
            DiffType.equal,
            effectiveLeft[leftCursor + k],
            rightText: effectiveRight[rightCursor + k],
          ),
        );
      }
      leftCursor += len;
      rightCursor += len;
    } else if (d.operation == DIFF_DELETE) {
      for (var k = 0; k < len; k++) {
        flat.add(_RawLine(DiffType.delete, effectiveLeft[leftCursor + k]));
      }
      leftCursor += len;
    } else if (d.operation == DIFF_INSERT) {
      for (var k = 0; k < len; k++) {
        flat.add(_RawLine(DiffType.insert, effectiveRight[rightCursor + k]));
      }
      rightCursor += len;
    }
  }

  return _buildResult(flat);
}

DiffResult _buildResult(List<_RawLine> flat) {
  final lines = <DiffLine>[];
  var leftNo = 0;
  var rightNo = 0;
  var added = 0;
  var removed = 0;
  var modified = 0;
  var unchanged = 0;

  var i = 0;
  while (i < flat.length) {
    final current = flat[i];
    if (current.type == DiffType.equal) {
      leftNo++;
      rightNo++;
      unchanged++;
      lines.add(
        DiffLine(
          type: DiffType.equal,
          leftText: current.leftText,
          rightText: current.rightText ?? current.leftText,
          leftLineNo: leftNo,
          rightLineNo: rightNo,
        ),
      );
      i++;
      continue;
    }

    final deletes = <String>[];
    final inserts = <String>[];
    while (i < flat.length && flat[i].type != DiffType.equal) {
      if (flat[i].type == DiffType.delete) {
        deletes.add(flat[i].leftText);
      } else {
        inserts.add(flat[i].leftText); // holds the insert text
      }
      i++;
    }

    final pairCount = deletes.length < inserts.length
        ? deletes.length
        : inserts.length;
    for (var k = 0; k < pairCount; k++) {
      leftNo++;
      rightNo++;
      final isActuallyEqual = deletes[k] == inserts[k];
      if (isActuallyEqual) {
        unchanged++;
        lines.add(
          DiffLine(
            type: DiffType.equal,
            leftText: deletes[k],
            rightText: inserts[k],
            leftLineNo: leftNo,
            rightLineNo: rightNo,
          ),
        );
      } else {
        modified++;
        final (leftSegs, rightSegs) = _computeIntraLineSegments(
          deletes[k],
          inserts[k],
        );
        lines.add(
          DiffLine(
            type: DiffType.modify,
            leftText: deletes[k],
            rightText: inserts[k],
            leftLineNo: leftNo,
            rightLineNo: rightNo,
            leftSegments: leftSegs,
            rightSegments: rightSegs,
          ),
        );
      }
    }
    for (var k = pairCount; k < deletes.length; k++) {
      leftNo++;
      removed++;
      lines.add(
        DiffLine(
          type: DiffType.delete,
          leftText: deletes[k],
          leftLineNo: leftNo,
        ),
      );
    }
    for (var k = pairCount; k < inserts.length; k++) {
      rightNo++;
      added++;
      lines.add(
        DiffLine(
          type: DiffType.insert,
          rightText: inserts[k],
          rightLineNo: rightNo,
        ),
      );
    }
  }

  return DiffResult(
    lines: lines,
    stats: DiffStats(
      added: added,
      removed: removed,
      modified: modified,
      unchanged: unchanged,
    ),
  );
}
