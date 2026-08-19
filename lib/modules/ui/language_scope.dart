import 'package:flutter/material.dart';

import '../i18n/language_provider.dart';
import '../i18n/translations.dart';

/// Attaches [LanguageProvider] to the widget tree so any descendant can
/// read `context.tr('key')` without prop-drilling — mirrors [ThemeScope].
class LanguageScope extends InheritedNotifier<LanguageProvider> {
  const LanguageScope({
    super.key,
    required LanguageProvider language,
    required super.child,
  }) : super(notifier: language);

  static LanguageProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LanguageScope>();
    assert(scope != null, 'LanguageScope not found in context');
    return scope!.notifier!;
  }
}

extension TranslationContext on BuildContext {
  LanguageProvider get languageProvider => LanguageScope.of(this);
  String tr(String key) => translate(languageProvider.language, key);
}
