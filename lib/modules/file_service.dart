import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:logging/logging.dart';

import 'constants.dart';
import 'extractors/docx_extractor.dart';
import 'extractors/pdf_extractor.dart';
import 'extractors/text_extractor.dart';
import 'extractors/xlsx_extractor.dart';
import 'utils.dart';

final _logger = Logger('FileService');

/// A document picked/dropped by the user, already extracted into
/// comparable lines.
class LoadedDocument {
  final String path;
  final String name;
  final String extension;
  final int sizeBytes;
  final List<String> lines;

  const LoadedDocument({
    required this.path,
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.lines,
  });
}

class UnsupportedFileTypeException implements Exception {
  final String extension;
  const UnsupportedFileTypeException(this.extension);

  @override
  String toString() =>
      'Định dạng ".$extension" chưa được hỗ trợ. Hỗ trợ: ${supportedExtensions.join(', ')}';
}

class FileService {
  /// Opens the native file picker restricted to supported document types.
  /// Returns null if the user cancels.
  Future<String?> pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: supportedExtensions,
      dialogTitle: 'Chọn tài liệu để so sánh',
    );
    return result?.files.single.path;
  }

  /// Reads and extracts a document at [path] into comparable lines,
  /// dispatching to the extractor matching its extension.
  Future<LoadedDocument> loadDocument(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final ext = fileExtensionOf(path);
    final name = file.uri.pathSegments.last;

    _logger.info('Loading $name (.$ext, ${formatFileSize(bytes.length)})');

    final List<String> lines;
    if (textLikeExtensions.contains(ext)) {
      lines = extractTextLines(bytes);
    } else if (docxExtensions.contains(ext)) {
      lines = extractDocxParagraphs(bytes);
    } else if (xlsxExtensions.contains(ext)) {
      lines = extractXlsxRows(bytes);
    } else if (pdfExtensions.contains(ext)) {
      lines = await extractPdfLines(bytes);
    } else {
      throw UnsupportedFileTypeException(ext);
    }

    return LoadedDocument(
      path: path,
      name: name,
      extension: ext,
      sizeBytes: bytes.length,
      lines: lines,
    );
  }
}
