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
      final path = p.join('test', 'common', 'message.dart');
      await replaceAllInFile(path, "'Hello World!'", 'can not parse this');
      final result = await runAutoBuild(trailingArgs: ['--fail-on-severe']);
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('Failed'));

      // Run a build with dart2js that should also fail. Makes the failing DDC
      // outptus no longer necessary for the build but does not invalidate them
      // by changing the file.
      final nextBuild =
          await runAutoBuild(trailingArgs: ['--fail-on-severe', '--release']);
      expect(nextBuild.exitCode, isNot(0));
      expect(nextBuild.stderr, contains('Failed'));

      // Correct the build and build with dart2js that should
      await replaceAllInFile(path, 'can not parse this', "'Hello World!'");
      final successBuild =
          await runAutoBuild(trailingArgs: ['--fail-on-severe', '--release']);
      expect(successBuild.exitCode, 0);
    });
  });
}
