import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:xml/xml.dart';

const _firstCustomNumFmtId = 164;

/// Reads every sheet of an .xlsx workbook and emits one comparable line per
/// row (`col1 | col2 | col3 ...`), prefixed with a `# Sheet: <name>` marker
/// whenever a new sheet starts.
List<String> extractXlsxRows(Uint8List bytes) {
  // Some Excel-compatible producers write built-in number formats (for
  // example numFmtId=43) inside the custom <numFmts> collection. The
  // `excel` package rejects that form, so normalize the OOXML package before
  // decoding it. The same pass removes style-only rows whose row number can
  // otherwise be close to Excel's one-million-row limit.
  final workbook = Excel.decodeBytes(_normalizeXlsxPackage(bytes));
  final lines = <String>[];

  for (final sheetName in workbook.tables.keys) {
    final sheet = workbook.tables[sheetName];
    if (sheet == null) continue;

    lines.add('# Sheet: $sheetName');
    final rows = sheet.rows;
    final lastMeaningfulRow = _lastMeaningfulRow(rows);
    for (var rowIndex = 0; rowIndex <= lastMeaningfulRow; rowIndex++) {
      final cells = rows[rowIndex]
          .map((cell) => cell?.value?.toString() ?? '')
          .join(' | ');
      lines.add(cells);
    }
  }
  return lines;
}

/// Returns the last row containing a visible value, ignoring trailing rows
/// created only by empty cells or formatting.
int _lastMeaningfulRow(List<List<Data?>> rows) {
  for (var rowIndex = rows.length - 1; rowIndex >= 0; rowIndex--) {
    final row = rows[rowIndex];
    if (row.any((cell) => cell?.value?.toString().isNotEmpty ?? false)) {
      return rowIndex;
    }
  }
  return -1;
}

/// Normalizes the small OOXML subset that the `excel` package consumes.
///
/// The original workbook bytes are never modified on disk. A new in-memory
/// ZIP is returned only when a styles or worksheet XML part needs changing.
Uint8List _normalizeXlsxPackage(Uint8List bytes) {
  final source = ZipDecoder().decodeBytes(bytes);
  final normalized = Archive();
  var changed = false;

  final sharedStringsFile = source.findFile('xl/sharedStrings.xml');
  _NormalizedPart? normalizedSharedStrings;
  if (sharedStringsFile != null) {
    sharedStringsFile.decompress();
    normalizedSharedStrings = _normalizeSharedStrings(
      _archiveContent(sharedStringsFile),
    );
  }
  final sharedStringRemap =
      normalizedSharedStrings?.indexRemap ?? const <int, int>{};

  for (final file in source.files) {
    file.decompress();
    var content = _archiveContent(file);
    _NormalizedPart? normalizedPart;

    if (file.name == 'xl/sharedStrings.xml') {
      normalizedPart = normalizedSharedStrings;
    } else if (file.name == 'xl/styles.xml') {
      normalizedPart = _normalizeStyles(content);
    } else if (file.name.startsWith('xl/worksheets/') &&
        file.name.endsWith('.xml')) {
      normalizedPart = _normalizeWorksheet(content, sharedStringRemap);
    }

    if (normalizedPart != null) {
      content = normalizedPart.bytes;
      changed = changed || normalizedPart.changed;
    }
    normalized.addFile(ArchiveFile(file.name, content.length, content));
  }

  if (!changed) return bytes;
  return Uint8List.fromList(ZipEncoder().encode(normalized)!);
}

List<int> _archiveContent(ArchiveFile file) {
  final content = file.content;
  if (content is List<int>) return List<int>.from(content);
  return List<int>.from(content as Iterable<dynamic>);
}

/// Deduplicates shared-string items before handing the workbook to
/// `excel`. That package stores shared strings in a value-keyed map, while
/// worksheet cells still refer to their original indexes. Duplicate `<si>`
/// items therefore make valid indexes point past the package's compacted list.
_NormalizedPart _normalizeSharedStrings(List<int> bytes) {
  final document = XmlDocument.parse(utf8.decode(bytes));
  final stringTable = document.findAllElements('sst').first;
  final items = stringTable.findElements('si').toList();
  final seen = <String, int>{};
  final indexRemap = <int, int>{};
  final uniqueItems = <XmlElement>[];

  for (var index = 0; index < items.length; index++) {
    final key = items[index].toXmlString();
    final compactIndex = seen.putIfAbsent(key, () {
      uniqueItems.add(items[index]);
      return uniqueItems.length - 1;
    });
    indexRemap[index] = compactIndex;
  }

  if (uniqueItems.length == items.length) {
    return _NormalizedPart(bytes, false);
  }

  for (final item in items) {
    stringTable.children.remove(item);
  }
  stringTable.children.addAll(uniqueItems.map((item) => item.copy()));
  stringTable.setAttribute('uniqueCount', '${uniqueItems.length}');

  return _NormalizedPart(utf8.encode(document.toXmlString()), true, indexRemap);
}

_NormalizedPart _normalizeStyles(List<int> bytes) {
  final document = XmlDocument.parse(utf8.decode(bytes));
  final remappedIds = <int, int>{};
  final usedIds = <int>{};
  var nextId = _firstCustomNumFmtId;

  for (final numFmts in document.findAllElements('numFmts')) {
    final numFormats = numFmts.findElements('numFmt').toList();
    for (final numFormat in numFormats) {
      final originalId = int.tryParse(numFormat.getAttribute('numFmtId') ?? '');
      if (originalId == null) continue;
      usedIds.add(originalId);
    }
  }

  for (final numFmts in document.findAllElements('numFmts')) {
    final numFormats = numFmts.findElements('numFmt').toList();
    for (final numFormat in numFormats) {
      final originalId = int.tryParse(numFormat.getAttribute('numFmtId') ?? '');
      if (originalId == null || originalId >= _firstCustomNumFmtId) {
        continue;
      }

      final replacementId = remappedIds.putIfAbsent(originalId, () {
        while (usedIds.contains(nextId)) {
          nextId++;
        }
        usedIds.add(nextId);
        return nextId++;
      });
      numFormat.setAttribute('numFmtId', '$replacementId');
    }
    if (numFormats.any(
      (numFormat) =>
          int.tryParse(numFormat.getAttribute('numFmtId') ?? '') != null,
    )) {
      numFmts.setAttribute('count', '${numFmts.findElements('numFmt').length}');
    }
  }

  if (remappedIds.isEmpty) {
    return _NormalizedPart(bytes, false);
  }

  for (final xf in document.findAllElements('xf')) {
    final originalId = int.tryParse(xf.getAttribute('numFmtId') ?? '');
    final replacementId = remappedIds[originalId];
    if (replacementId != null) {
      xf.setAttribute('numFmtId', '$replacementId');
    }
  }

  return _NormalizedPart(utf8.encode(document.toXmlString()), true);
}

_NormalizedPart _normalizeWorksheet(
  List<int> bytes,
  Map<int, int> sharedStringRemap,
) {
  final document = XmlDocument.parse(utf8.decode(bytes));
  var changed = false;

  for (final sheetData in document.findAllElements('sheetData')) {
    final rows = sheetData.findElements('row').toList();
    for (final row in rows) {
      for (final cell in row.findElements('c')) {
        if (cell.getAttribute('t') != 's') continue;
        final value = cell.findElements('v');
        if (value.isEmpty) continue;
        final originalIndex = int.tryParse(value.first.innerText);
        final compactIndex = originalIndex == null
            ? null
            : sharedStringRemap[originalIndex];
        if (compactIndex != null && compactIndex != originalIndex) {
          value.first.children
            ..clear()
            ..add(XmlText('$compactIndex'));
          changed = true;
        }
      }

      final hasPayload = row
          .findElements('c')
          .any(
            (cell) =>
                cell.findElements('v').isNotEmpty ||
                cell.findElements('f').isNotEmpty ||
                cell.findElements('is').isNotEmpty,
          );
      if (!hasPayload) {
        sheetData.children.remove(row);
        changed = true;
      }
    }
  }

  if (!changed) return _NormalizedPart(bytes, false);
  return _NormalizedPart(utf8.encode(document.toXmlString()), true);
}

class _NormalizedPart {
  final List<int> bytes;
  final bool changed;
  final Map<int, int> indexRemap;

  const _NormalizedPart(
    this.bytes,
    this.changed, [
    this.indexRemap = const <int, int>{},
  ]);
}
