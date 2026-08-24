// Exercises the real extraction + diff pipeline (the same code path the
// GUI uses) against a generated pair of files for each supported format,
// to verify the app produces correct results without needing to drive the
// UI interactively.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as xl;
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:ja_compare/modules/diff_engine.dart';
import 'package:ja_compare/modules/constants.dart';
import 'package:ja_compare/modules/extractors/text_extractor.dart';
import 'package:ja_compare/modules/file_service.dart';
import 'package:ja_compare/modules/models/diff_result.dart';

void main() {
  final tempDir = Directory.systemTemp.createTempSync('ja_compare_test_');
  final service = FileService();

  tearDownAll(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<DiffResult> compareFiles(String pathA, String pathB) async {
    final docA = await service.loadDocument(pathA);
    final docB = await service.loadDocument(pathB);
    return computeDiff(docA.lines, docB.lines);
  }

  void report(String label, DiffResult r) {
    // ignore: avoid_print
    print(
      '[$label] +${r.stats.added} added, -${r.stats.removed} removed, '
      '${r.stats.modified} modified, ${r.stats.unchanged} unchanged',
    );
  }

  test('Text (.txt): detects added/removed/modified lines', () async {
    final fileA = File('${tempDir.path}/a.txt')
      ..writeAsStringSync('Line 1\nLine 2\nLine 3\n');
    final fileB = File('${tempDir.path}/b.txt')
      ..writeAsStringSync('Line 1\nLine 2 modified\nLine 3\nLine 4\n');

    final result = await compareFiles(fileA.path, fileB.path);
    report('TXT', result);

    expect(result.stats.modified, 1);
    expect(result.stats.added, 1);
    expect(result.stats.removed, 0);
  });

  test('Word (.docx): paragraph-level diff', () async {
    final bytesA = _buildDocx([
      'Tieu de bao cao',
      'Doan van khong doi',
      'Doan van cu',
    ]);
    final bytesB = _buildDocx([
      'Tieu de bao cao',
      'Doan van khong doi',
      'Doan van moi',
      'Doan them vao',
    ]);
    final fileA = File('${tempDir.path}/a.docx')..writeAsBytesSync(bytesA);
    final fileB = File('${tempDir.path}/b.docx')..writeAsBytesSync(bytesB);

    final result = await compareFiles(fileA.path, fileB.path);
    report('DOCX', result);

    expect(result.stats.modified, 1);
    expect(result.stats.added, 1);
    expect(result.stats.unchanged, 2);
  });

  test('Excel (.xlsx): row-level diff', () async {
    final excelA = xl.Excel.createExcel();
    final sheetA = excelA[excelA.getDefaultSheet()!];
    sheetA.appendRow([xl.TextCellValue('Ten'), xl.TextCellValue('Diem')]);
    sheetA.appendRow([xl.TextCellValue('An'), xl.IntCellValue(8)]);
    sheetA.appendRow([xl.TextCellValue('Binh'), xl.IntCellValue(7)]);
    final bytesA = Uint8List.fromList(excelA.encode()!);

    final excelB = xl.Excel.createExcel();
    final sheetB = excelB[excelB.getDefaultSheet()!];
    sheetB.appendRow([xl.TextCellValue('Ten'), xl.TextCellValue('Diem')]);
    sheetB.appendRow([xl.TextCellValue('An'), xl.IntCellValue(9)]);
    sheetB.appendRow([xl.TextCellValue('Binh'), xl.IntCellValue(7)]);
    sheetB.appendRow([xl.TextCellValue('Chi'), xl.IntCellValue(10)]);
    final bytesB = Uint8List.fromList(excelB.encode()!);

    final fileA = File('${tempDir.path}/a.xlsx')..writeAsBytesSync(bytesA);
    final fileB = File('${tempDir.path}/b.xlsx')..writeAsBytesSync(bytesB);

    final result = await compareFiles(fileA.path, fileB.path);
    report('XLSX', result);

    expect(result.stats.modified, 1); // An's score changed
    expect(result.stats.added, 1); // Chi row added
  });

  test('does not advertise or load legacy binary .xls', () async {
    expect(supportedExtensions, isNot(contains('xls')));
    final legacyXls = File('${tempDir.path}/legacy.xls')
      ..writeAsBytesSync([0xD0, 0xCF, 0x11, 0xE0]);

    expect(
      () => service.loadDocument(legacyXls.path),
      throwsA(isA<UnsupportedFileTypeException>()),
    );
  });

  test('Text extractor reads UTF-16 LE files with a BOM', () {
    final text = 'Dòng một\nDòng hai';
    final units = <int>[0xFF, 0xFE];
    for (final unit in text.codeUnits) {
      units
        ..add(unit & 0xFF)
        ..add(unit >> 8);
    }

    expect(extractTextLines(Uint8List.fromList(units)), [
      'Dòng một',
      'Dòng hai',
    ]);
  });

  test('PDF (.pdf): extracted-text diff', () async {
    final pdfA = pw.Document();
    pdfA.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Hop dong so 001'),
            pw.Text('Ben A: Cong ty ABC'),
            pw.Text('Gia tri: 100.000.000 VND'),
          ],
        ),
      ),
    );
    final bytesA = await pdfA.save();

    final pdfB = pw.Document();
    pdfB.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Hop dong so 001'),
            pw.Text('Ben A: Cong ty ABC'),
            pw.Text('Gia tri: 150.000.000 VND'),
            pw.Text('Ghi chu: Da sua doi'),
          ],
        ),
      ),
    );
    final bytesB = await pdfB.save();

    final fileA = File('${tempDir.path}/a.pdf')..writeAsBytesSync(bytesA);
    final fileB = File('${tempDir.path}/b.pdf')..writeAsBytesSync(bytesB);

    final result = await compareFiles(fileA.path, fileB.path);
    report('PDF', result);

    expect(result.stats.hasDifferences, isTrue);
    expect(result.lines, isNotEmpty);
  });
}

/// Builds a minimal but valid .docx (OOXML package) containing one
/// paragraph per string in [paragraphs] — enough for docx_extractor.dart
/// to round-trip correctly.
List<int> _buildDocx(List<String> paragraphs) {
  final paragraphsXml = paragraphs
      .map((p) => '<w:p><w:r><w:t>${_escapeXml(p)}</w:t></w:r></w:p>')
      .join();
  final documentXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      '<w:body>$paragraphsXml</w:body></w:document>';

  final contentTypesXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
      '</Types>';

  final relsXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
      '</Relationships>';

  final archive = Archive()
    ..addFile(
      ArchiveFile(
        '[Content_Types].xml',
        contentTypesXml.length,
        utf8.encode(contentTypesXml),
      ),
    )
    ..addFile(ArchiveFile('_rels/.rels', relsXml.length, utf8.encode(relsXml)))
    ..addFile(
      ArchiveFile(
        'word/document.xml',
        documentXml.length,
        utf8.encode(documentXml),
      ),
    );

  return ZipEncoder().encode(archive)!;
}

String _escapeXml(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
