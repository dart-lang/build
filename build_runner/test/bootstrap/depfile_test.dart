// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build_runner/src/bootstrap/depfile.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Depfile', () {
    test('parses', () async {
      expect(Depfile.parse('output: input1 input2\n'), ['input1', 'input2']);
    });

    test('parses when filenames have spaces and backslashes', () async {
      expect(
        Depfile.parse(
          r'output: input1 input2 input\ with\ space input4 path\\input5'
          '\n',
        ),
        ['input1', 'input2', 'input with space', 'input4', r'path\input5'],
      );
    });

    group('checkFreshness', () {
      late Directory tempDir;
      late File outputFile;
      late File depsFile;
      late File digestFile;
      late File stampFile;
      late File input1;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('depfile_test');
        outputFile = File(p.join(tempDir.path, 'output.txt'))
          ..writeAsStringSync('output');
        input1 = File(p.join(tempDir.path, 'input1.txt'))
          ..writeAsStringSync('input1');

        depsFile = File(p.join(tempDir.path, 'deps.d'))
          ..writeAsStringSync('${outputFile.path}: ${input1.path}\n');

        digestFile = File(p.join(tempDir.path, 'deps.digest'));
        stampFile = File('${digestFile.path}.stamp');
      });

      tearDown(() {
        tempDir.deleteSync(recursive: true);
      });

      test('not fresh if input modified between stamp and digest', () async {
        stampFile.writeAsStringSync('');
        await Future<void>.delayed(const Duration(seconds: 2));
        input1.writeAsStringSync('input1');
        await Future<void>.delayed(const Duration(seconds: 2));
        final depfile = Depfile(
          outputPath: outputFile.path,
          depfilePath: depsFile.path,
          digestPath: digestFile.path,
        )..writeDigest();
        final result = depfile.checkFreshness(digestsAreFresh: false);

        // Digests are identical and would return "fresh", but mtime makes it
        // not fresh.
        expect(result.outputIsFresh, false);
      });

      test('checks content if modified after digest', () async {
        stampFile.writeAsStringSync('');
        await Future<void>.delayed(const Duration(seconds: 2));
        final depfile = Depfile(
          outputPath: outputFile.path,
          depfilePath: depsFile.path,
          digestPath: digestFile.path,
        )..writeDigest();
        var result = depfile.checkFreshness(digestsAreFresh: false);
        await Future<void>.delayed(const Duration(seconds: 2));
        input1.writeAsStringSync('input1');

        // Digests are identical and modification was after digests.
        expect(result.outputIsFresh, true);

        // Check again but with different content, digests no longer match.
        input1.writeAsStringSync('input1 modified');
        result = depfile.checkFreshness(digestsAreFresh: false);
        expect(result.outputIsFresh, false);
      });
    });
  });
}
