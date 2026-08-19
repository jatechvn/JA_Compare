import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

import '../i18n/language_provider.dart';
import '../i18n/translations.dart';
import '../models/diff_result.dart';

/// Exports a [DiffResult] for the user to save/share — either as a
/// GitHub-style fenced ` ```diff ` Markdown block, or as an Excel workbook
/// with one row per compared line.
class ExportService {
  /// Shows a native "Save As" dialog and writes the Markdown export.
  /// Returns `true` if saved, `false` if the user cancelled.
  Future<bool> exportMarkdown({
    required DiffResult result,
    required String leftName,
    required String rightName,
    required AppLanguage language,
  }) async {
    final bytes = Uint8List.fromList(
      utf8.encode(_buildMarkdown(result, leftName, rightName, language)),
    );
    final path = await FilePicker.saveFile(
      dialogTitle: translate(language, 'export_save_dialog_title'),
      fileName: _suggestedFileName(leftName, rightName, 'md'),
      type: FileType.custom,
      allowedExtensions: ['md'],
      bytes: bytes,
    );
    return path != null;
  }

  /// Shows a native "Save As" dialog and writes the Excel export. Returns
  /// `true` if saved, `false` if the user cancelled.
  Future<bool> exportExcel({
    required DiffResult result,
    required String leftName,
    required String rightName,
    required AppLanguage language,
  }) async {
    final bytes = _buildExcel(result, leftName, rightName, language);
    final path = await FilePicker.saveFile(
      dialogTitle: translate(language, 'export_save_dialog_title'),
      fileName: _suggestedFileName(leftName, rightName, 'xlsx'),
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      bytes: bytes,
    );
    return path != null;
  }

  String _suggestedFileName(String left, String right, String extension) {
    String withoutExt(String name) {
      final dot = name.lastIndexOf('.');
      return dot <= 0 ? name : name.substring(0, dot);
    }

    return 'compare_${withoutExt(left)}_vs_${withoutExt(right)}.$extension';
  }

  String _buildMarkdown(
    DiffResult result,
    String leftName,
    String rightName,
    AppLanguage language,
  ) {
    final buffer = StringBuffer()
      ..writeln(
        '# ${translate(language, 'export_title')}: $leftName ↔ $rightName',
      )
      ..writeln()
      ..writeln(
        '- +${result.stats.added} ${translate(language, 'added_suffix')}',
      )
      ..writeln(
        '- -${result.stats.removed} ${translate(language, 'removed_suffix')}',
      )
      ..writeln(
        '- ${result.stats.modified} ${translate(language, 'modified_suffix')}',
      )
      ..writeln()
      ..writeln('```diff');

    for (final line in result.lines) {
      switch (line.type) {
        case DiffType.equal:
          buffer.writeln(' ${line.leftText}');
        case DiffType.delete:
          buffer.writeln('-${line.leftText}');
        case DiffType.insert:
          buffer.writeln('+${line.rightText}');
        case DiffType.modify:
          buffer.writeln('-${line.leftText}');
          buffer.writeln('+${line.rightText}');
      }
    }

    buffer.writeln('```');
    return buffer.toString();
  }

  Uint8List _buildExcel(
    DiffResult result,
    String leftName,
    String rightName,
    AppLanguage language,
  ) {
    final workbook = Excel.createExcel();
    final sheetName = workbook.getDefaultSheet() ?? 'Sheet1';
    final sheet = workbook[sheetName];

    sheet.appendRow([
      TextCellValue('#'),
      TextCellValue(leftName),
      TextCellValue(rightName),
      TextCellValue(translate(language, 'export_status_column')),
    ]);
    _styleRow(sheet, 0, ExcelColor.grey200, bold: true);

    var rowNumber = 1;
    for (final line in result.lines) {
      sheet.appendRow([
        IntCellValue(rowNumber),
        TextCellValue(line.leftText ?? ''),
        TextCellValue(line.rightText ?? ''),
        TextCellValue(_statusLabel(line.type, language)),
      ]);
      final rowColor = _rowColor(line.type);
      if (rowColor != null) _styleRow(sheet, rowNumber, rowColor);
      rowNumber++;
    }

    return Uint8List.fromList(workbook.encode() ?? const []);
  }

  /// Fills every cell in [rowIndex] (0-based) with [color] — matches the
  /// same green/red/amber semantics as the app's own diff view.
  void _styleRow(
    Sheet sheet,
    int rowIndex,
    ExcelColor color, {
    bool bold = false,
  }) {
    for (var col = 0; col < 4; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
      );
      cell.cellStyle = CellStyle(backgroundColorHex: color, bold: bold);
    }
  }

  ExcelColor? _rowColor(DiffType type) => switch (type) {
    DiffType.equal => null,
    DiffType.insert => ExcelColor.green100,
    DiffType.delete => ExcelColor.red100,
    DiffType.modify => ExcelColor.amber100,
  };

  String _statusLabel(DiffType type, AppLanguage language) => switch (type) {
    DiffType.equal => '',
    DiffType.insert => translate(language, 'added_suffix'),
    DiffType.delete => translate(language, 'removed_suffix'),
    DiffType.modify => translate(language, 'modified_suffix'),
  };
}
