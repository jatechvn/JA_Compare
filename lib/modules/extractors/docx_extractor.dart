import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Unzips a .docx (an OOXML package) and walks `word/document.xml`,
/// emitting one comparable string per `<w:p>` paragraph. Tabs and line
/// breaks embedded inside a paragraph are preserved so table cell text
/// stays readable.
List<String> extractDocxParagraphs(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final docFile = archive.files.firstWhere(
    (f) => f.name == 'word/document.xml',
    orElse: () => throw const FormatException(
      'Not a valid .docx file (missing word/document.xml)',
    ),
  );

  final content = docFile.content;
  final xmlContent = utf8.decode(content is List<int> ? content : <int>[]);
  final document = XmlDocument.parse(xmlContent);

  // `namespace: '*'` is required — without it, findAllElements compares the
  // *fully-qualified* name ("w:p"), which never matches since Word always
  // namespaces its elements. This flag makes it match on local name only,
  // regardless of whatever prefix a given document binds the namespace to.
  final paragraphs = <String>[];
  for (final paragraph in document.findAllElements('p', namespace: '*')) {
    final buffer = StringBuffer();
    for (final node in paragraph.descendantElements) {
      switch (node.name.local) {
        case 't':
          buffer.write(node.innerText);
        case 'tab':
          buffer.write('\t');
        case 'br':
        case 'cr':
          buffer.write('\n');
      }
    }
    paragraphs.add(buffer.toString());
  }
  return paragraphs;
}
