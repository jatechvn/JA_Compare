import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'modules/build_info.dart';
import 'modules/constants.dart';
import 'modules/i18n/language_provider.dart';
import 'modules/logger_config.dart';
import 'modules/services/app_storage_service.dart';
import 'modules/ui/language_scope.dart';
import 'modules/ui/main_window.dart';
import 'modules/ui/styles.dart';

Future<void> main(List<String> args) async {
  if (args.contains('-debug') ||
      args.contains('--debug') ||
      args.contains('-d')) {
    BuildInfo.isCliDebug = true;
  }

  WidgetsFlutterBinding.ensureInitialized();
  AppStorageService.ensureInitialized();
  setupLogger();

  await windowManager.ensureInitialized();

  // Deliberately no titleBarStyle / backgroundColor here — window_manager is
  // only used for size/position/focus/close-prevention. Composition (blur,
  // acrylic, dark-mode title bar) is owned entirely by the native
  // theme_win10.cpp / theme_win11.cpp runner code. See flutter-windows-themer
  // skill: window_manager's own native plugin resets the glass extension if
  // you hand it a titleBarStyle, silently breaking the native blur.
  const windowOptions = WindowOptions(
    size: Size(1180, 820),
    minimumSize: Size(860, 560),
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setPreventClose(false);
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const JaCompareApp());
}

class JaCompareApp extends StatefulWidget {
  const JaCompareApp({super.key});

  @override
  State<JaCompareApp> createState() => _JaCompareAppState();
}

class _JaCompareAppState extends State<JaCompareApp> {
  final _theme = ThemeProvider();
  final _language = LanguageProvider();

  @override
  void dispose() {
    disposeLogger();
    _theme.dispose();
    _language.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      theme: _theme,
      child: LanguageScope(
        language: _language,
        child: ListenableBuilder(
          listenable: Listenable.merge([_theme, _language]),
          builder: (context, _) {
            return MaterialApp(
              title: appName,
              debugShowCheckedModeBanner: false,
              theme: _theme.themeData,
              home: const MainWindow(),
            );
          },
        ),
      ),
    );
  }
}
