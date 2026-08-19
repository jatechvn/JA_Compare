// Basic smoke test: the app boots and shows its own name in the header.

import 'package:flutter_test/flutter_test.dart';

import 'package:ja_compare/main.dart';
import 'package:ja_compare/modules/constants.dart';

void main() {
  testWidgets('JA Compare boots and shows the app name', (tester) async {
    await tester.pumpWidget(const JaCompareApp());
    await tester.pump();

    expect(find.text(appName), findsOneWidget);
  });
}
