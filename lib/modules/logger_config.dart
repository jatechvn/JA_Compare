import 'build_info.dart';
import 'logger_release.dart';
import 'logger_debug.dart';

export 'logger_release.dart';
export 'logger_debug.dart';

void setupLogger() {
  if (BuildInfo.isDebug) {
    setupDebugLogger();
  } else {
    setupReleaseLogger();
  }
}

void disposeLogger() {
  if (BuildInfo.isDebug) {
    disposeDebugLogger();
  } else {
    disposeReleaseLogger();
  }
}
