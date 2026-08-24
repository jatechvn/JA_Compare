import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'services/app_storage_service.dart';

IOSink? _releaseLogSink;

void setupReleaseLogger() {
  Logger.root.level = Level.INFO;
  final logDir = AppStorageService.logsDirectory;
  if (!logDir.existsSync()) logDir.createSync(recursive: true);

  final now = DateTime.now();
  final logFileName =
      '${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}.log';
  _releaseLogSink = File(
    p.join(logDir.path, logFileName),
  ).openWrite(mode: FileMode.append);

  Logger.root.onRecord.listen((record) {
    if (record.level < Level.INFO) return;
    final buffer = StringBuffer()
      ..write(
        '[${record.time.toIso8601String()}] ${record.level.name}: ${record.loggerName} - ${record.message}',
      );
    if (record.error != null) buffer.write('\n  ERROR: ${record.error}');
    _releaseLogSink?.writeln(buffer.toString());
  });
  rotateReleaseLogs(logDir);
}

void rotateReleaseLogs(Directory logDir) {
  try {
    final limit = DateTime.now().subtract(const Duration(days: 30));
    for (final entity in logDir.listSync()) {
      if (entity is File && entity.path.endsWith('.log')) {
        if (entity.statSync().modified.isBefore(limit)) entity.deleteSync();
      }
    }
  } catch (_) {}
}

void disposeReleaseLogger() {
  _releaseLogSink?.close();
}
