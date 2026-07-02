import 'dart:io';

import 'package:build_runner/src/io/high_resolution_mtime.dart';
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

    test('isModifiedAfter correctly compares modification times', () async {
      final file1 = File('${tempDir.path}/file1')..writeAsStringSync('1');

      // Sleep slightly to allow the filesystem clock to advance
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final file2 = File('${tempDir.path}/file2')..writeAsStringSync('2');

      // file2 was modified after file1
      expect(HighResolutionMtime.isModifiedAfter(file2, file1), isTrue);
      // file1 was NOT modified after file2
      expect(HighResolutionMtime.isModifiedAfter(file1, file2), isFalse);
    });

    test('ensureDistinctMtime ensures a fresh modification time', () async {
      final file = File('${tempDir.path}/file')..writeAsStringSync('1');

      // Save the initial modification time
      final initialMtime = file.lastModifiedSync();

      // We don't sleep here, we just call ensureDistinctMtime.
      // It should internally sleep and spin until the high-res mtime changes.
      HighResolutionMtime.ensureDistinctMtime(file);

      // Verify that after ensureDistinctMtime, any subsequent file write
      // is considered distinct.
      // Actually, ensureDistinctMtime modifies the file itself to advance
      // the time.
      // So let's check that if we write a new file immediately afterwards,
      // the new file is modified after the original file's pre-spin state.
      // Wait, ensureDistinctMtime updates `file` until its mtime > initial.
      final newMtime = file.lastModifiedSync();

      // Due to Dart's truncated precision, newMtime might still equal
      // initialMtime in Dart's DateTime, but it MUST NOT be less.
      expect(newMtime.compareTo(initialMtime) >= 0, isTrue);

      // And more importantly, if we create a marker *before*
      // ensureDistinctMtime, the file should now be strictly modified after
      // the marker.
      final marker = File('${tempDir.path}/marker')
        ..writeAsStringSync('marker');

      // Write the file so it has exactly the same Dart mtime (potentially).
      file.writeAsStringSync('1');

      // Now spin
      HighResolutionMtime.ensureDistinctMtime(file);

      // The file should now be strictly modified *after* the marker,
      // even if Dart's mtime looks identical.
      expect(HighResolutionMtime.isModifiedAfter(file, marker), isTrue);
    });
  });
}
