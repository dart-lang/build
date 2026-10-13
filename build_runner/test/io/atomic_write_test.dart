// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:build_runner/src/io/atomic_write.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('writeAtomically', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('atomic_write_test');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('writes the bytes', () async {
      final file = File(p.join(tempDir.path, 'file.txt'));
      await writeAtomically(file, utf8.encode('hello'));
      expect(file.readAsStringSync(), 'hello');
    });

    test('creates missing directories', () async {
      final file = File(p.join(tempDir.path, 'missing', 'file.txt'));
      await writeAtomically(file, utf8.encode('hello'));
      expect(file.readAsStringSync(), 'hello');
    });

    test('overwrites an existing file', () async {
      final file = File(p.join(tempDir.path, 'file.txt'))
        ..writeAsStringSync('old');
      await writeAtomically(file, utf8.encode('hello'));
      expect(file.readAsStringSync(), 'hello');
    });

    test('leaves no temporary files behind', () async {
      final file = File(p.join(tempDir.path, 'file.txt'));
      await writeAtomically(file, utf8.encode('hello'));
      expect(tempDir.listSync().map((entity) => entity.path), [file.path]);
    });

    test('does not create the file until it has the full content', () async {
      final file = File(p.join(tempDir.path, 'file.txt'));
      final written = writeAtomically(file, utf8.encode('hello'));

      // Watch for the file appearing. It must already have the full content:
      // another process that sees it must not see it partially written.
      final stopwatch = Stopwatch()..start();
      while (!file.existsSync() &&
          stopwatch.elapsed < const Duration(seconds: 30)) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(file.existsSync(), true);
      expect(file.readAsStringSync(), 'hello');

      await written;
    });
  });
}
