// Basic smoke test: the app boots and shows its own name in the header.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ja_compare/main.dart';
import 'package:ja_compare/modules/constants.dart';
import 'package:ja_compare/modules/i18n/language_provider.dart';
import 'package:ja_compare/modules/models/diff_result.dart';
import 'package:ja_compare/modules/ui/diff_view.dart';
import 'package:ja_compare/modules/ui/language_scope.dart';
import 'package:ja_compare/modules/ui/styles.dart';

void main() {
  testWidgets('JA Compare boots and shows the app name', (tester) async {
    await tester.pumpWidget(const JaCompareApp());
    await tester.pump();

    expect(find.text(appName), findsOneWidget);
    expect(find.textContaining('DEBUG • v'), findsOneWidget);
  });

  testWidgets('shows a clear status when compared files are identical', (
    tester,
  ) async {
    final theme = ThemeProvider();
    final language = LanguageProvider();
    addTearDown(() {
      theme.dispose();
      language.dispose();
    });

    const result = DiffResult(
      lines: [
        DiffLine(type: DiffType.equal, leftText: 'same', rightText: 'same'),
      ],
      stats: DiffStats(added: 0, removed: 0, modified: 0, unchanged: 1),
    );

    await tester.pumpWidget(
      ThemeScope(
        theme: theme,
        child: LanguageScope(
          language: language,
          child: MaterialApp(
            theme: theme.themeData,
            home: Scaffold(
              body: DiffView(
                result: result,
                leftLabel: 'Left',
                rightLabel: 'Right',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });
}
