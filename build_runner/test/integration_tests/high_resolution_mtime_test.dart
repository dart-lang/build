import 'dart:io';

import 'package:build_runner/src/bootstrap/high_resolution_mtime.dart';
import 'package:test/test.dart';

void main() {
  group('HighResolutionMtime', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('mtime_test');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('high resolution mtime', () async {
      // High res mtimes are close to SDK mtimes.
      final file = File('${tempDir.path}/file')..writeAsStringSync('1');
      final dartMtime = file.lastModifiedSync().nanosecondsSinceEpoch;
      final highResMtime = HighResolutionMtime.getHighResMtimeOrNull(
        file.path,
      )!;
      expect((highResMtime - dartMtime).abs(), lessThan(1_000_000_000));

      // Can wait for clock advance.
      final stamp = File('${tempDir.path}/stamp')..writeAsStringSync('1');
      await HighResolutionMtime.waitForNewMtime(stamp.path);
      final newFile = File('${tempDir.path}/new')..writeAsStringSync('2');
      final stampMtime = HighResolutionMtime.getHighResMtimeOrNull(stamp.path)!;
      final newFileMtime = HighResolutionMtime.getHighResMtimeOrNull(
        newFile.path,
      )!;
      expect(newFileMtime, greaterThan(stampMtime));

      // Can determine "modified between".
      final file1 = File('${tempDir.path}/file1')..writeAsStringSync('1');
      await HighResolutionMtime.waitForNewMtime(file1.path);
      final file2 = File('${tempDir.path}/file2')..writeAsStringSync('2');
      await HighResolutionMtime.waitForNewMtime(file2.path);
      final file3 = File('${tempDir.path}/file3')..writeAsStringSync('3');
      expect(
        HighResolutionMtime.hasModifiedBetween(
          paths: [file2.path],
          startStampPath: file1.path,
          endStampPath: file3.path,
        ),
        isTrue,
      );
      expect(
        HighResolutionMtime.hasModifiedBetween(
          paths: [file3.path],
          startStampPath: file1.path,
          endStampPath: file2.path,
        ),
        isFalse,
      );
    });
  });
}
