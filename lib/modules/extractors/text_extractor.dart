import 'dart:convert';
import 'dart:typed_data';

/// Splits plain-text-family files (.txt/.md/.csv/.json/.log/.xml/.html/...)
/// into comparable lines. Uses malformed-tolerant UTF-8 decoding so files
/// with stray non-UTF-8 bytes still load instead of throwing.
List<String> extractTextLines(Uint8List bytes) {
  final content = utf8.decode(bytes, allowMalformed: true);
  return const LineSplitter().convert(content);
}
