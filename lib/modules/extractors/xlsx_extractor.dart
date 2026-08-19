import 'dart:typed_data';

import 'package:excel/excel.dart';

/// Reads every sheet of an .xlsx workbook and emits one comparable line per
/// row (`col1 | col2 | col3 ...`), prefixed with a `# Sheet: <name>` marker
/// whenever a new sheet starts.
List<String> extractXlsxRows(Uint8List bytes) {
  final workbook = Excel.decodeBytes(bytes);
  final lines = <String>[];

  for (final sheetName in workbook.tables.keys) {
    final sheet = workbook.tables[sheetName];
    if (sheet == null) continue;

    lines.add('# Sheet: $sheetName');
    for (final row in sheet.rows) {
      final cells = row
          .map((cell) => cell?.value?.toString() ?? '')
          .join(' | ');
      lines.add(cells);
    }
  }
  return lines;
}
