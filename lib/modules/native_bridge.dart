import 'dart:io' show Platform;

import 'package:logging/logging.dart';

import 'native/win_core.dart';
import 'native/mac_core.dart';
import 'native/linux_core.dart';

final _logger = Logger('NativeBridge');

abstract class NativeEngine {
  dynamic heavyCompute(dynamic dataInput);
}

/// Cross-platform hook for future native-accelerated diff/extraction work.
/// Currently unused by the comparison pipeline (pure Dart is fast enough for
/// typical document sizes) but kept per the blueprint architecture so a
/// native core can be dropped in later without restructuring.
class NativeBridge {
  final String osName;
  NativeEngine? engine;

  NativeBridge() : osName = Platform.operatingSystem {
    _initializeEngine();
  }

  void _initializeEngine() {
    try {
      if (Platform.isWindows) {
        engine = WindowsNativeEngine();
      } else if (Platform.isMacOS) {
        engine = MacNativeEngine();
      } else if (Platform.isLinux) {
        engine = LinuxNativeEngine();
      } else {
        _logger.warning(
          '[BRIDGE] OS $osName is not supported by Hybrid Core. Using fallback.',
        );
      }
    } catch (e) {
      _logger.severe('[BRIDGE] Failed to initialize engine for $osName: $e');
    }
  }

  dynamic executeHeavyTask(dynamic dataInput) {
    if (engine != null) {
      return engine!.heavyCompute(dataInput);
    }
    return _pureDartFallback(dataInput);
  }

  dynamic _pureDartFallback(dynamic dataInput) {
    _logger.info('[BRIDGE] Processing using pure Dart algorithm (slower).');
    return dataInput;
  }
}

final nativeAgent = NativeBridge();
