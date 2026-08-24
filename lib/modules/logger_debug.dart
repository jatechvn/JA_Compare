import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'services/app_storage_service.dart';

IOSink? _debugLogSink;

void setupDebugLogger() {
  Logger.root.level = Level.ALL;
  final logDir = AppStorageService.logsDirectory;
  if (!logDir.existsSync()) logDir.createSync(recursive: true);

  final now = DateTime.now();
  final logFileName =
      'debug_${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}.log';
  _debugLogSink = File(
    p.join(logDir.path, logFileName),
  ).openWrite(mode: FileMode.append);
  _debugLogSink?.writeln(
    '=== DEBUG LOG SESSION STARTED: ${now.toIso8601String()} ===',
  );

  Logger.root.onRecord.listen((record) {
    final buffer = StringBuffer()
      ..write(
        '[${record.time.toIso8601String()}] [DEBUG] ${record.level.name}: ${record.loggerName} - ${record.message}',
      );
    if (record.error != null) buffer.write('\n  ERROR: ${record.error}');
    if (record.stackTrace != null) {
      buffer.write('\n  STACKTRACE: ${record.stackTrace}');
    }
    final logText = buffer.toString();
    debugPrintLog(logText);
    _debugLogSink?.writeln(logText);
  });
  rotateDebugLogs(logDir);
}

/// Thin wrapper so tests/tools can intercept console output if needed.
void debugPrintLog(String text) {
  // ignore: avoid_print
  print(text);
}

void rotateDebugLogs(Directory logDir) {
  try {
    final limit = DateTime.now().subtract(const Duration(days: 7));
    for (final entity in logDir.listSync()) {
      if (entity is File && entity.path.endsWith('.log')) {
        if (entity.statSync().modified.isBefore(limit)) entity.deleteSync();
      }
    }
  } catch (_) {}
}

void disposeDebugLogger() {
  _debugLogSink?.writeln('=== DEBUG LOG SESSION ENDED ===');
  _debugLogSink?.close();
}
