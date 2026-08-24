import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'styles_win10.dart';
import 'styles_win11.dart';

/// Semantic color palette consumed by every widget — never hardcode a
/// `Colors.*` value in a widget; add a field here instead.
class AppColors {
  final Color bgPrimary;
  final Color bgSecondary;
  final Color sidebarBg;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderDefault;
  final Color accent;
  final Color diffAdded;
  final Color diffRemoved;
  final Color diffModified;
  final Color diffWordAdded;
  final Color diffWordRemoved;
  final Color diffWordModified;
  final Color cardHoverBg;
  final Color accentGlow;

  const AppColors({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.sidebarBg,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderDefault,
    required this.accent,
    required this.diffAdded,
    required this.diffRemoved,
    required this.diffModified,
    required this.diffWordAdded,
    required this.diffWordRemoved,
    required this.diffWordModified,
    required this.cardHoverBg,
    required this.accentGlow,
  });
}

class ThemePalette {
  final AppColors light;
  final AppColors dark;
  const ThemePalette({required this.light, required this.dark});
}

/// Detects Win10 vs Win11 and light/dark mode, and dispatches to the
/// matching translucency palette so the native backdrop blur reads
/// correctly underneath. See flutter-windows-themer skill §1 and §4.
///
/// Light/dark defaults to — and stays synced with — the Windows system
/// setting (`didChangePlatformBrightness`) unless the user manually
/// toggles it via [toggleTheme], which overrides the system default for
/// the rest of this session only; the next launch re-syncs from Windows.
class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const _themeChannel = MethodChannel('ja_compare/theme');

  late bool isDark;
  bool _followSystem = true;
  bool _isWin11 = true;

  ThemeProvider() {
    isDark = _systemIsDark();
    _detectWindowsVersion();
    WidgetsBinding.instance.addObserver(this);
  }

  static bool _systemIsDark() =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
      Brightness.dark;

  void _syncNativeTheme() {
    if (!Platform.isWindows) return;
    try {
      _themeChannel.invokeMethod<void>('setTheme', {'isDark': isDark});
    } catch (_) {}
  }

  @override
  void didChangePlatformBrightness() {
    if (!_followSystem) return;
    isDark = _systemIsDark();
    _syncNativeTheme();
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get isWin11 => _isWin11;

  void _detectWindowsVersion() {
    if (!Platform.isWindows) return;
    try {
      final versionStr = Platform.operatingSystemVersion;
      final match = RegExp(r'Build\s+(\d+)').firstMatch(versionStr);
      if (match != null) {
        final buildNumber = int.tryParse(match.group(1) ?? '') ?? 0;
        _isWin11 = buildNumber >= 22000;
      }
    } catch (_) {}
  }

  AppColors get colors {
    final palette = _isWin11 ? win11Palette : win10Palette;
    return isDark ? palette.dark : palette.light;
  }

  void toggleTheme() {
    _followSystem = false;
    isDark = !isDark;
    _syncNativeTheme();
    notifyListeners();
  }

  ThemeData get themeData {
    final c = colors;
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.accent,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontFamily: 'Outfit'),
        bodySmall: TextStyle(fontFamily: 'Outfit'),
        bodyLarge: TextStyle(fontFamily: 'Outfit'),
        titleMedium: TextStyle(fontFamily: 'Outfit'),
        titleLarge: TextStyle(fontFamily: 'Outfit'),
      ),
      useMaterial3: true,
    );
  }
}

/// Attaches [ThemeProvider] to the widget tree so any descendant can read
/// `context.appColors` without prop-drilling.
class ThemeScope extends InheritedNotifier<ThemeProvider> {
  const ThemeScope({
    super.key,
    required ThemeProvider theme,
    required super.child,
  }) : super(notifier: theme);

  static ThemeProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found in context');
    return scope!.notifier!;
  }
}

extension AppColorsContext on BuildContext {
  AppColors get appColors => ThemeScope.of(this).colors;
  ThemeProvider get themeProvider => ThemeScope.of(this);
}
