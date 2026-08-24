import 'dart:io';

import 'package:path/path.dart' as p;

/// Provides writable locations for per-user data and application logs.
///
/// Settings and comparison history are kept outside the release folder. On
/// Windows this maps to `%LOCALAPPDATA%\\JA Compare`; logs intentionally live
/// beside the executable so a portable release can be diagnosed in place.
class AppStorageService {
  AppStorageService._();

  static Directory get rootDirectory {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null && localAppData.isNotEmpty) {
      return Directory(p.join(localAppData, 'JA Compare'));
    }

    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      return Directory(p.join(appData, 'JA Compare'));
    }

    final xdgDataHome = Platform.environment['XDG_DATA_HOME'];
    final base = xdgDataHome != null && xdgDataHome.isNotEmpty
        ? xdgDataHome
        : p.join(Directory.current.path, '.local', 'share');
    return Directory(p.join(base, 'ja_compare'));
  }

  static Directory get logsDirectory {
    final executablePath = Platform.resolvedExecutable;
    if (executablePath.isNotEmpty) {
      return Directory(p.join(File(executablePath).parent.path, 'logs'));
    }
    return Directory(p.join(rootDirectory.path, 'logs'));
  }

  static File file(String name) {
    ensureInitialized();
    return File(p.join(rootDirectory.path, name));
  }

  static void ensureInitialized() {
    final root = rootDirectory;
    try {
      if (!root.existsSync()) root.createSync(recursive: true);
      _migrateLegacyFile(root, 'config.ini');
      _migrateLegacyFile(root, 'history.json');
    } catch (_) {
      // Callers still have their normal read fallbacks if the directory is
      // unavailable, for example during an installation or locked profile.
    }
  }

  static void _migrateLegacyFile(Directory root, String name) {
    final destination = File(p.join(root.path, name));
    final legacy = File(p.join(Directory.current.path, name));
    if (!destination.existsSync() && legacy.existsSync()) {
      legacy.copySync(destination.path);
    }
  }
}
