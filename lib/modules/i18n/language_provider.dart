import 'package:flutter/foundation.dart';

import '../services/settings_service.dart';

enum AppLanguage { en, vi, zh }

extension AppLanguageCode on AppLanguage {
  String get storageCode => switch (this) {
    AppLanguage.en => 'en',
    AppLanguage.vi => 'vi',
    AppLanguage.zh => 'zh',
  };

  static AppLanguage fromStorageCode(String code) => switch (code) {
    'en' => AppLanguage.en,
    'zh' => AppLanguage.zh,
    _ => AppLanguage.vi,
  };
}

/// Cycles en → vi → zh on each tap, per the flutter-windows-themer skill's
/// lightweight i18n pattern. The chosen language is persisted to
/// `config.ini` so the app reopens in whichever language was last used.
class LanguageProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguageCode.fromStorageCode(
    SettingsService.loadLanguage(),
  );

  AppLanguage get language => _language;

  String get badge => switch (_language) {
    AppLanguage.en => 'EN',
    AppLanguage.vi => 'VI',
    AppLanguage.zh => 'CN',
  };

  void cycle() {
    _language = switch (_language) {
      AppLanguage.en => AppLanguage.vi,
      AppLanguage.vi => AppLanguage.zh,
      AppLanguage.zh => AppLanguage.en,
    };
    SettingsService.saveLanguage(_language.storageCode);
    notifyListeners();
  }
}
