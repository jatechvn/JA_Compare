import 'package:flutter_test/flutter_test.dart';
import 'package:ja_compare/modules/diff_engine.dart';
import 'package:ja_compare/modules/logic.dart';
import 'package:ja_compare/modules/models/diff_result.dart';
import 'package:ja_compare/modules/sample_presets.dart';

void main() {
  group('Diff Engine & Intra-line Highlighting', () {
    test('computes intra-line word segments for modified lines', () {
      final left = ['final String oldName = "Alpha";'];
      final right = ['final String newName = "Beta";'];

      final result = computeDiff(left, right);
      expect(result.lines.length, 1);
      expect(result.lines.first.type, DiffType.modify);

      final line = result.lines.first;
      expect(line.leftSegments, isNotNull);
      expect(line.rightSegments, isNotNull);

      // Left should have delete segments containing 'old'
      final hasDelete = line.leftSegments!.any(
        (s) => s.type == DiffSegmentType.delete && s.text.contains('old'),
      );
      expect(hasDelete, isTrue);

      // Right should have insert segments containing 'new'
      final hasInsert = line.rightSegments!.any(
        (s) => s.type == DiffSegmentType.insert && s.text.contains('new'),
      );
      expect(hasInsert, isTrue);
    });

    test('respects DiffOptions: ignoreWhitespace', () {
      final left = ['  hello world  '];
      final right = ['hello   world'];

      // Without option: modified
      final resNormal = computeDiff(left, right);
      expect(resNormal.lines.first.type, DiffType.modify);

      // With ignoreWhitespace: equal
      final resIgnore = computeDiff(
        left,
        right,
        options: const DiffOptions(ignoreWhitespace: true),
      );
      expect(resIgnore.lines.first.type, DiffType.equal);
    });

    test('respects DiffOptions: ignoreCase', () {
      final left = ['HELLO WORLD'];
      final right = ['hello world'];

      final resIgnore = computeDiff(
        left,
        right,
        options: const DiffOptions(ignoreCase: true),
      );
      expect(resIgnore.lines.first.type, DiffType.equal);
    });

    test('respects DiffOptions: ignoreEmptyLines', () {
      final left = ['Line 1', '', '  ', 'Line 2'];
      final right = ['Line 1', 'Line 2'];

      final resIgnore = computeDiff(
        left,
        right,
        options: const DiffOptions(ignoreEmptyLines: true),
      );
      expect(resIgnore.lines.length, 2);
      expect(resIgnore.stats.hasDifferences, isFalse);
    });
  });

  group('CompareController features', () {
    test('supports Direct Text mode comparison', () async {
      final controller = CompareController();
      controller.setMode(CompareMode.directText);

      controller.leftTextController.text = 'Alpha\nBeta';
      controller.rightTextController.text = 'Alpha\nGamma';

      expect(controller.canCompare, isTrue);
      await controller.compare();

      expect(controller.hasResult, isTrue);
      expect(controller.diffResult!.stats.modified, 1);
      expect(controller.diffResult!.stats.unchanged, 1);

      controller.dispose();
    });

    test('allows comparing one empty direct-text side', () async {
      final controller = CompareController();
      controller.setMode(CompareMode.directText);
      controller.rightTextController.text = 'New content';

      expect(controller.canCompare, isTrue);
      await controller.compare();

      expect(controller.diffResult?.stats.hasDifferences, isTrue);
      controller.dispose();
    });

    test('supports swap() in direct text mode', () {
      final controller = CompareController();
      controller.setMode(CompareMode.directText);

      controller.leftTextController.text = 'Left Text';
      controller.rightTextController.text = 'Right Text';

      controller.swap();

      expect(controller.leftTextController.text, 'Right Text');
      expect(controller.rightTextController.text, 'Left Text');

      controller.dispose();
    });

    test('loads SamplePresets seamlessly', () async {
      final controller = CompareController();
      controller.setMode(CompareMode.directText);

      final preset = SamplePresets.jsonConfig;
      controller.loadPreset(preset);

      // Wait a tick for background diff
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(controller.leftTextController.text, preset.leftContent);
      expect(controller.rightTextController.text, preset.rightContent);

      controller.dispose();
    });
  });
}
