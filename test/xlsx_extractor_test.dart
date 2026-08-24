import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as xl;
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

import 'package:ja_compare/modules/extractors/xlsx_extractor.dart';

void main() {
  test(
    'accepts Excel-compatible styles, duplicate strings, and distant rows',
    () {
      final source = xl.Excel.createExcel();
      final sheet = source[source.getDefaultSheet()!];
      sheet.appendRow([xl.TextCellValue('Item'), xl.IntCellValue(1)]);
      sheet.appendRow([xl.TextCellValue('Second'), xl.IntCellValue(2)]);

      final malformed = _patchWorkbook(Uint8List.fromList(source.encode()!));

      final lines = extractXlsxRows(malformed);

      expect(lines, contains('# Sheet: Sheet1'));
      expect(lines, contains('Item | 1'));
      expect(lines, contains('Second | 2'));
      expect(lines.length, lessThan(20));
    },
  );
}

Uint8List _patchWorkbook(Uint8List bytes) {
  final source = ZipDecoder().decodeBytes(bytes);
  final patched = Archive();
  final sharedStringsFile = source.findFile('xl/sharedStrings.xml')!
    ..decompress();
  final sharedStringsDocument = XmlDocument.parse(
    utf8.decode(sharedStringsFile.content as List<int>),
  );
  final stringTable = sharedStringsDocument.findAllElements('sst').first;
  final duplicateStringIndex = stringTable.findAllElements('si').length;
  stringTable.children.add(stringTable.findAllElements('si').first.copy());
  final patchedSharedStrings = utf8.encode(sharedStringsDocument.toXmlString());

  for (final file in source.files) {
    file.decompress();
    var content = List<int>.from(file.content as List<int>);

    if (file.name == 'xl/sharedStrings.xml') {
      content = patchedSharedStrings;
    } else if (file.name == 'xl/styles.xml') {
      final document = XmlDocument.parse(utf8.decode(content));
      final styleSheet = document.findAllElements('styleSheet').first;
      final numFmts = XmlElement(
        XmlName('numFmts'),
        [XmlAttribute(XmlName('count'), '1')],
        [
          XmlElement(XmlName('numFmt'), [
            XmlAttribute(XmlName('numFmtId'), '43'),
            XmlAttribute(
              XmlName('formatCode'),
              r'_(* #,##0.00_);_(* \(#,##0.00\);_(* "-"??_);_(@_)',
            ),
          ]),
        ],
      );
      styleSheet.children.insert(0, numFmts);
      styleSheet
          .findAllElements('cellXfs')
          .first
          .findElements('xf')
          .first
          .setAttribute('numFmtId', '43');
      content = utf8.encode(document.toXmlString());
    } else if (file.name == 'xl/worksheets/sheet1.xml') {
      final document = XmlDocument.parse(utf8.decode(content));
      final sheetData = document.findAllElements('sheetData').first;
      final firstTextCell = document
          .findAllElements('c')
          .firstWhere((cell) => cell.getAttribute('r') == 'A1');
      firstTextCell.findElements('v').first
        ..children.clear()
        ..children.add(XmlText('$duplicateStringIndex'));
      sheetData.children.add(
        XmlElement(
          XmlName('row'),
          [XmlAttribute(XmlName('r'), '999999')],
          [
            XmlElement(XmlName('c'), [
              XmlAttribute(XmlName('r'), 'A999999'),
              XmlAttribute(XmlName('s'), '0'),
            ]),
          ],
        ),
      );
      content = utf8.encode(document.toXmlString());
    }

    patched.addFile(ArchiveFile(file.name, content.length, content));
  }

  return Uint8List.fromList(ZipEncoder().encode(patched)!);
}
