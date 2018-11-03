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
    await runBuild();
  });

  group('PostProcessBuilder', () {
    test('creates expected outputs', () async {
      var generated =
          await readGeneratedFileAsString('_test/lib/hello.txt.post');
      var original = await File('lib/hello.txt').readAsString();
      expect(generated, equals(original));
    });

    test('can be configured with build.yaml', () async {
      await runBuild(trailingArgs: ['--config', 'post_process']);
      var generated =
          await readGeneratedFileAsString('_test/lib/hello.txt.post');
      expect(generated, equals('goodbye'));
    });

    test('can be configured with --define', () async {
      var content = 'cool';
      await runBuild(trailingArgs: [
        '--define',
        'provides_builder|some_post_process_builder=default_content=$content'
      ]);
      var generated =
          await readGeneratedFileAsString('_test/lib/hello.txt.post');
      expect(generated, equals(content));
    }, onPlatform: {
      'windows': const Skip('https://github.com/dart-lang/build/issues/1127')
    });

    test('rebuilds if the input file changes and not otherwise', () async {
      var result = await runBuild();
      expect(result.stdout, contains('with 0 outputs'));
      await replaceAllInFile('lib/hello.txt', 'hello', 'goodbye');
      result = await runBuild();
      expect(result.stdout, contains('with 1 outputs'));
      var content = await readGeneratedFileAsString('_test/lib/hello.txt.post');
      expect(content, contains('goodbye'));
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
          "import: 'package:_test/bad_file.dart';");
      final result = await runBuild(trailingArgs: ['--fail-on-severe']);
      expect(result.exitCode, isNot(0));
      expect(result.stdout, contains('Failed'));

      // Remove the import to the bad file so it is no longer a requirement for
      // the overall build
      await replaceAllInFile(testFile, "import: 'package:_test/bad_file.dart';",
          '//import_anchor');
      final nextBuild = await runBuild(trailingArgs: ['--fail-on-severe']);
      expect(nextBuild.exitCode, 0);
    });

    test(
        'Restores previously deleted outputs if they are not deleted in subsequent builds',
        () async {
      final dartSource =
          File(p.join('build', 'web', 'packages', '_test', 'app.dart'));
      await runBuild(trailingArgs: [
        '--define=build_web_compilers|dart_source_cleanup=enabled=true',
        '--output',
        'build'
      ]);
      expect(dartSource.existsSync(), false);

      await runBuild(trailingArgs: ['--output', 'build']);
      expect(dartSource.existsSync(), true);
    });
  });
}
