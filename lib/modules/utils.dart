import 'dart:io';

import 'package:path/path.dart' as p;

/// Returns the lowercase file extension without the leading dot.
/// e.g. `report.DOCX` -> `docx`, `noext` -> ``.
String fileExtensionOf(String path) {
  final ext = p.extension(path);
  return ext.isEmpty ? '' : ext.substring(1).toLowerCase();
}

/// Human-readable file size, e.g. `1.4 MB`.
String formatFileSize(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  double size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  return '${size.toStringAsFixed(size < 10 && unitIndex > 0 ? 1 : 0)} ${units[unitIndex]}';
}

/// Opens the file or containing directory in Windows File Explorer and selects it.
Future<void> revealInExplorer(String? filePath) async {
  if (filePath == null || filePath.trim().isEmpty) return;
  final normalized = filePath.replaceAll('/', '\\');
  try {
    if (Platform.isWindows) {
      final file = File(filePath);
      if (await file.exists()) {
        await Process.run('explorer.exe', ['/select,', normalized]);
        return;
      }
      final dir = Directory(filePath);
      if (await dir.exists()) {
        await Process.run('explorer.exe', [normalized]);
        return;
      }
      final parent = file.parent;
      if (await parent.exists()) {
        await Process.run('explorer.exe', [parent.path.replaceAll('/', '\\')]);
      }
    }
  } catch (_) {}
}
