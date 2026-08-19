import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter/foundation.dart' show compute;

import 'models/diff_result.dart';

/// Runs [computeDiff] on a background isolate via [compute] so a large
/// document pair doesn't block the UI thread while diffing.
Future<DiffResult> computeDiffInBackground(
  List<String> leftLines,
  List<String> rightLines,
) {
  return compute(_computeDiffEntry, (leftLines, rightLines));
}

DiffResult _computeDiffEntry((List<String>, List<String>) args) =>
    computeDiff(args.$1, args.$2);

/// Maps each distinct line of text to a single opaque UTF-16 code unit so
/// the character-oriented [diff] algorithm can be reused to diff whole
/// lines instead of characters — the classic "diff on lines" technique.
/// Surrogate-pair code units (0xD800-0xDFFF) are skipped since they cannot
/// stand alone in a String; this leaves ~63.7k distinct lines addressable,
/// far beyond what a real document comparison needs.
class _LineTokenizer {
  final Map<String, int> _lineIndex = {};
  final List<String> _lines = [];
  final Map<int, String> _codeUnitToLine = {};

  String tokenize(List<String> input) {
    final buffer = StringBuffer();
    for (final line in input) {
      var index = _lineIndex[line];
      if (index == null) {
        index = _lines.length;
        _lines.add(line);
        _lineIndex[line] = index;
        _codeUnitToLine[_codeUnitForIndex(index)] = line;
      }
      buffer.writeCharCode(_codeUnitForIndex(index));
    }
    return buffer.toString();
  }

  String lineForCodeUnit(int codeUnit) => _codeUnitToLine[codeUnit]!;

  static int _codeUnitForIndex(int index) {
    const start = 0x0021; // skip C0 control range
    var code = start + index;
    if (code >= 0xD800) code += 0xE000 - 0xD800; // jump over surrogates
    return code;
  }
}

class _RawLine {
  final DiffType type;
  final String text;
  const _RawLine(this.type, this.text);
}

/// Runs a line-level diff between [leftLines] and [rightLines] and returns
/// a [DiffResult] ready for the side-by-side view. Adjacent delete/insert
/// runs are paired up row-by-row as [DiffType.modify] so changed lines show
/// up on the same row in both panes instead of as a delete block followed
/// by an unrelated insert block.
DiffResult computeDiff(List<String> leftLines, List<String> rightLines) {
  final tokenizer = _LineTokenizer();
  final encodedLeft = tokenizer.tokenize(leftLines);
  final encodedRight = tokenizer.tokenize(rightLines);

  // Deliberately no cleanupSemantic() here: it's designed to reshape
  // character-level diffs for human readability, and applied to
  // whole-line tokens it can absorb a genuinely-unchanged line sitting
  // between two edits into the surrounding delete/insert run — which
  // _buildResult below would then misreport as "modified" content that
  // is actually identical on both sides.
  final rawDiffs = diff(encodedLeft, encodedRight, checklines: false);

  final flat = <_RawLine>[];
  for (final d in rawDiffs) {
    final type = switch (d.operation) {
      DIFF_INSERT => DiffType.insert,
      DIFF_DELETE => DiffType.delete,
      _ => DiffType.equal,
    };
    for (final codeUnit in d.text.codeUnits) {
      flat.add(_RawLine(type, tokenizer.lineForCodeUnit(codeUnit)));
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
          leftText: current.text,
          rightText: current.text,
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
        deletes.add(flat[i].text);
      } else {
        inserts.add(flat[i].text);
      }
      i++;
    }

    final pairCount = deletes.length < inserts.length
        ? deletes.length
        : inserts.length;
    for (var k = 0; k < pairCount; k++) {
      leftNo++;
      rightNo++;
      // Defensive: a paired delete/insert should differ by construction,
      // but if the algorithm ever emits identical text on both sides,
      // report it as unchanged rather than a misleading "modified" row.
      final isActuallyEqual = deletes[k] == inserts[k];
      if (isActuallyEqual) {
        unchanged++;
      } else {
        modified++;
      }
      lines.add(
        DiffLine(
          type: isActuallyEqual ? DiffType.equal : DiffType.modify,
          leftText: deletes[k],
          rightText: inserts[k],
          leftLineNo: leftNo,
          rightLineNo: rightNo,
        ),
      );
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
