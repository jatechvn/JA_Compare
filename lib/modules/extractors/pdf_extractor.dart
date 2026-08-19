import 'dart:convert';
import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

/// Extracts text from every page of a PDF (via pdfium) and splits it into
/// comparable lines. Scanned/image-only PDFs have no embedded text layer
/// and will simply yield empty pages.
Future<List<String>> extractPdfLines(Uint8List bytes) async {
  final document = await PdfDocument.openData(bytes);
  try {
    final lines = <String>[];
    for (final page in document.pages) {
      final pageText = await page.loadText();
      lines.addAll(const LineSplitter().convert(pageText?.fullText ?? ''));
    }
    return lines;
  } finally {
    await document.dispose();
  }
}
