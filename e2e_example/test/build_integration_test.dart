// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import 'common/utils.dart';

void main() {
  setUp(() async {
    ensureCleanGitClient();
    // Run a regular build in known clean state to speed up these tests.
    await runAutoBuild();
  });

  group('PostProcessBuilder', () {
    test('creates expected outputs', () async {
      var generated =
          await readGeneratedFileAsString('e2e_example/lib/hello.txt.post');
      var original = await new File('lib/hello.txt').readAsString();
      expect(generated, equals(original));
    });

    test('can be configured with build.yaml', () async {
      await runAutoBuild(trailingArgs: ['--config', 'post_process']);
      var generated =
          await readGeneratedFileAsString('e2e_example/lib/hello.txt.post');
      expect(generated, equals('goodbye'));
    });

    test('can be configured with --define', () async {
      var content = 'cool';
      await runAutoBuild(trailingArgs: [
        '--define',
        'provides_builder|some_post_process_builder=default_content=$content'
      ]);
      var generated =
          await readGeneratedFileAsString('e2e_example/lib/hello.txt.post');
      expect(generated, equals(content));
    }, onPlatform: {
      'windows': const Skip('https://github.com/dart-lang/build/issues/1127')
    });

    test('rebuilds if the input file changes and not otherwise', () async {
      var result = await runAutoBuild();
      expect(result.stdout, contains('with 0 outputs'));
      await replaceAllInFile('lib/hello.txt', 'hello', 'goodbye');
      result = await runAutoBuild();
      expect(result.stdout, contains('with 1 outputs'));
      var content =
          await readGeneratedFileAsString('e2e_example/lib/hello.txt.post');
      expect(content, contains('goodbye'));
    });
  });

  group('--fail-on-severe', () {
    setUp(() async {
      // Perform an edit that should cause a failure.
      await deleteFile('test/common/message.dart');
    });

    test('causes builds to return a non-zero exit code on errors', () async {
      var result = await runAutoBuild(trailingArgs: ['--fail-on-severe']);
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('Failed'));
    });

    test('causes tests to return a non-zero exit code on errors', () async {
      var result = await runAutoTests(buildArgs: ['--fail-on-severe']);
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('Failed'));
      expect(result.stdout, contains('Skipping tests due to build failure'));
    });
  });

  group('regression tests', () {
    test('Failing optional outputs which are required during the next build',
        () async {
      // Run a build with DDC that should fail
      final path = p.join('lib', 'bad_file.dart');
      await createFile(path, 'not valid dart syntax');
      final testFile = p.join('test', 'hello_world_test.dart');
      await replaceAllInFile(testFile, '//import_anchor',
          "import: 'package:e2e_example/bad_file.dart'");
      final result = await runAutoBuild(trailingArgs: ['--fail-on-severe']);
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('Failed'));

      // Remove the import to the bad file so it is no longer a requirement for
      // the overall build
      await replaceAllInFile(testFile,
          "import: 'package:e2e_example/bad_file.dart'", '//import_anchor');
      final nextBuild = await runAutoBuild(trailingArgs: ['--fail-on-severe']);
      expect(nextBuild.exitCode, 0);
    });
  });
}
