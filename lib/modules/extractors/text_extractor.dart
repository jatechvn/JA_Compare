import 'dart:convert';
import 'dart:typed_data';

/// Splits plain-text-family files (.txt/.md/.csv/.json/.log/.xml/.html/...)
/// into comparable lines. Handles UTF-8, UTF-16 BOM files and falls back to
/// Latin-1 when malformed bytes would otherwise become replacement glyphs.
List<String> extractTextLines(Uint8List bytes) {
  final content = _decodeText(bytes);
  return const LineSplitter().convert(content);
}

String _decodeText(Uint8List bytes) {
  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
    return _decodeUtf16(bytes, littleEndian: true, offset: 2);
  }
  if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
    return _decodeUtf16(bytes, littleEndian: false, offset: 2);
  }

  final utf8Text = utf8
      .decode(bytes, allowMalformed: true)
      .replaceFirst('\uFEFF', '');
  final hasReplacementGlyph = utf8Text.contains('\uFFFD');
  if (!hasReplacementGlyph) return utf8Text;

  // This is a pragmatic Windows-first fallback for legacy ANSI exports. It
  // preserves every byte for comparison instead of silently replacing it.
  return latin1.decode(bytes);
}

String _decodeUtf16(
  Uint8List bytes, {
  required bool littleEndian,
  required int offset,
}) {
  final units = <int>[];
  for (var i = offset; i + 1 < bytes.length; i += 2) {
    final unit = littleEndian
        ? bytes[i] | (bytes[i + 1] << 8)
        : (bytes[i] << 8) | bytes[i + 1];
    units.add(unit);
  }
  return String.fromCharCodes(units);
}
