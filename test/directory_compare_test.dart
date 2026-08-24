import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_compare/modules/logic.dart';
import 'package:ja_compare/modules/models/directory_diff_result.dart';
import 'package:ja_compare/modules/services/directory_compare_service.dart';
import 'package:ja_compare/modules/services/history_service.dart';

void main() {
  late Directory tempDir;
  late Directory leftDir;
  late Directory rightDir;
  late DirectoryCompareService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ja_compare_dir_test_');
    leftDir = Directory('${tempDir.path}${Platform.pathSeparator}dir_a');
    rightDir = Directory('${tempDir.path}${Platform.pathSeparator}dir_b');
    await leftDir.create();
    await rightDir.create();

    service = DirectoryCompareService();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('DirectoryCompareService', () {
    test('detects identical and modified files with exact paths', () async {
      // Create identical file
      final leftSame = File('${leftDir.path}${Platform.pathSeparator}same.txt');
      final rightSame = File(
        '${rightDir.path}${Platform.pathSeparator}same.txt',
      );
      await leftSame.writeAsString('Hello World\nLine 2');
      await rightSame.writeAsString('Hello World\nLine 2');

      // Create modified file
      final leftMod = File('${leftDir.path}${Platform.pathSeparator}mod.json');
      final rightMod = File(
        '${rightDir.path}${Platform.pathSeparator}mod.json',
      );
      await leftMod.writeAsString('{\n  "version": 1\n}');
      await rightMod.writeAsString('{\n  "version": 2\n}');

      final result = await service.compareDirectories(
        leftDirPath: leftDir.path,
        rightDirPath: rightDir.path,
      );

      expect(result.stats.totalFiles, equals(2));
      expect(result.stats.identical, equals(1));
      expect(result.stats.modified, equals(1));

      final samePair = result.pairs.firstWhere(
        (p) => p.displayName == 'same.txt',
      );
      expect(samePair.status, equals(FilePairStatus.identical));

      final modPair = result.pairs.firstWhere(
        (p) => p.displayName == 'mod.json',
      );
      expect(modPair.status, equals(FilePairStatus.modified));
      expect(modPair.diffStats?.modified, equals(1));
    });

    test(
      'performs smart fuzzy name matching for versioned / similar files',
      () async {
        // Left has config_v1.json, Right has config_v2.json
        final leftV1 = File(
          '${leftDir.path}${Platform.pathSeparator}config_v1.json',
        );
        final rightV2 = File(
          '${rightDir.path}${Platform.pathSeparator}config_v2.json',
        );
        await leftV1.writeAsString(
          '{\n  "host": "localhost",\n  "port": 8080\n}',
        );
        await rightV2.writeAsString(
          '{\n  "host": "localhost",\n  "port": 9090\n}',
        );

        // Left has report_2024.txt, Right has report_2025.txt
        final leftRep = File(
          '${leftDir.path}${Platform.pathSeparator}report_2024.txt',
        );
        final rightRep = File(
          '${rightDir.path}${Platform.pathSeparator}report_2025.txt',
        );
        await leftRep.writeAsString('Annual Report 2024\nRevenue: \$100k');
        await rightRep.writeAsString('Annual Report 2025\nRevenue: \$150k');

        final result = await service.compareDirectories(
          leftDirPath: leftDir.path,
          rightDirPath: rightDir.path,
          enableFuzzyMatching: true,
        );

        expect(result.stats.similarName, equals(2));
        expect(result.stats.leftOnly, equals(0));
        expect(result.stats.rightOnly, equals(0));

        final configPair = result.pairs.firstWhere(
          (p) => p.leftRelativePath == 'config_v1.json',
        );
        expect(configPair.rightRelativePath, equals('config_v2.json'));
        expect(configPair.status, equals(FilePairStatus.similarName));
        expect(configPair.similarityScore, greaterThanOrEqualTo(0.8));
      },
    );

    test('detects leftOnly and rightOnly files correctly', () async {
      final leftOnly = File(
        '${leftDir.path}${Platform.pathSeparator}deleted.txt',
      );
      await leftOnly.writeAsString('This file only exists in left');

      final rightOnly = File(
        '${rightDir.path}${Platform.pathSeparator}created.txt',
      );
      await rightOnly.writeAsString('This file only exists in right');

      final result = await service.compareDirectories(
        leftDirPath: leftDir.path,
        rightDirPath: rightDir.path,
        enableFuzzyMatching: false,
      );

      expect(result.stats.leftOnly, equals(1));
      expect(result.stats.rightOnly, equals(1));

      final leftPair = result.pairs.firstWhere(
        (p) => p.leftRelativePath == 'deleted.txt',
      );
      expect(leftPair.status, equals(FilePairStatus.leftOnly));

      final rightPair = result.pairs.firstWhere(
        (p) => p.rightRelativePath == 'created.txt',
      );
      expect(rightPair.status, equals(FilePairStatus.rightOnly));
    });

    test('ignores hidden/system directories like .git and build', () async {
      final gitDir = Directory('${leftDir.path}${Platform.pathSeparator}.git');
      await gitDir.create();
      final gitFile = File('${gitDir.path}${Platform.pathSeparator}config');
      await gitFile.writeAsString('git internal');

      final appFile = File('${leftDir.path}${Platform.pathSeparator}app.dart');
      await appFile.writeAsString('void main() {}');

      final rightAppFile = File(
        '${rightDir.path}${Platform.pathSeparator}app.dart',
      );
      await rightAppFile.writeAsString('void main() {}');

      final binaryLeft = File(
        '${leftDir.path}${Platform.pathSeparator}image.png',
      );
      final binaryRight = File(
        '${rightDir.path}${Platform.pathSeparator}image.png',
      );
      await binaryLeft.writeAsBytes([0, 1, 2, 255]);
      await binaryRight.writeAsBytes([0, 1, 2, 255]);

      final result = await service.compareDirectories(
        leftDirPath: leftDir.path,
        rightDirPath: rightDir.path,
      );

      expect(result.stats.totalFiles, equals(1));
      expect(result.pairs.first.displayName, equals('app.dart'));
    });
  });

  group('CompareController in Directory Mode', () {
    test(
      'supports folder selection, swapping and drill-down navigation',
      () async {
        final file1L = File(
          '${leftDir.path}${Platform.pathSeparator}file1.txt',
        );
        final file1R = File(
          '${rightDir.path}${Platform.pathSeparator}file1.txt',
        );
        await file1L.writeAsString('A\nB');
        await file1R.writeAsString('A\nC');

        final controller = CompareController();
        controller.setMode(CompareMode.folders);
        await controller.loadDirectory(ComparePaneSide.left, leftDir.path);
        await controller.loadDirectory(ComparePaneSide.right, rightDir.path);

        expect(controller.canCompare, isTrue);
        await controller.compare();

        expect(controller.hasResult, isTrue);
        expect(controller.directoryResult?.pairs.length, equals(1));

        final folderHistory = HistoryService.load()
            .where(
              (entry) =>
                  entry.leftPath == leftDir.path &&
                  entry.rightPath == rightDir.path,
            )
            .toList();
        expect(folderHistory, hasLength(1));
        expect(folderHistory.single.isFolder, isTrue);

        // Test drill-down
        final pair = controller.filteredDirectoryPairs.first;
        await controller.selectDrillDownPair(pair);

        expect(controller.activeDrillDownPair, equals(pair));
        expect(pair.diffResult, isNotNull);

        // Clear drill-down
        controller.clearDrillDown();
        expect(controller.activeDrillDownPair, isNull);

        // Test swap
        controller.swap();
        expect(controller.leftDirectoryPath, equals(rightDir.path));
        expect(controller.rightDirectoryPath, equals(leftDir.path));

        HistoryService.remove(folderHistory.single);
        controller.dispose();
      },
    );
  });
}
