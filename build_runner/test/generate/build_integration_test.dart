// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../common/common.dart';

main() {
  group('build integration tests', () {
    group('build script', () {
      String originalBuildContent = '''
import 'package:build_runner/build_runner.dart';
import 'package:build_test/build_test.dart';

main() async {
  await build(
    [new BuildAction(new CopyBuilder(), 'a')], deleteFilesByDefault: true);
}
''';
      setUp(() async {
        await d.dir('a', [
          await pubspec('a', currentIsolateDependencies: [
            'build',
            'build_runner',
            'build_test',
            'glob'
          ]),
          d.dir('tool', [d.file('build.dart', originalBuildContent)]),
          d.dir('web', [
            d.file('a.txt', 'a'),
          ]),
        ]).create();

        await pubGet('a');

        // Run a build and validate the output.
        var result = await runDart('a', 'tool/build.dart');
        expect(result.exitCode, 0, reason: result.stderr as String);
        await d.dir('a', [
          d.dir('web', [d.file('a.txt.copy', 'a')])
        ]).validate();
      });

      test('updates cause a rebuild', () async {
        // Append a newline to the build script!
        await d.dir('a', [
          d.dir('tool', [d.file('build.dart', '$originalBuildContent\n')])
        ]).create();

        // Run a build and validate the full rebuild output.
        var result = await runDart('a', 'tool/build.dart');
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(
            result.stdout,
            contains('BuildDefinition: Invalidating asset graph due to '
                'build script update'));
        await d.dir('a', [
          d.dir('web', [d.file('a.txt.copy', 'a')])
        ]).validate();
      });
    });

    group('findAssets', () {
      setUp(() async {
        await d.dir('a', [
          await pubspec('a', currentIsolateDependencies: [
            'build',
            'build_runner',
            'build_test',
            'glob'
          ]),
          d.dir('tool', [
            d.file('build.dart', '''
import 'package:build_runner/build_runner.dart';
import 'package:build_test/build_test.dart';
import 'package:glob/glob.dart';

main() async {
  await build(
    [new BuildAction(new GlobbingBuilder(new Glob('**.txt')), 'a')]);
}
''')
          ]),
          d.dir('web', [
            d.file('a.globPlaceholder'),
            d.file('a.txt', ''),
            d.file('b.txt', ''),
          ]),
        ]).create();

        await pubGet('a');

        // Run a build and validate the output.
        var result = await runDart('a', 'tool/build.dart');
        expect(result.exitCode, 0, reason: result.stderr as String);
        await d.dir('a', [
          d.dir('web', [d.file('a.matchingFiles', 'a|web/a.txt\na|web/b.txt')])
        ]).validate();
      });

      test('picks up new files that match the glob', () async {
        // Add a new file matching the glob.
        await d.dir('a', [
          d.dir('web', [d.file('c.txt', '')])
        ]).create();

        // Run a new build and validate.
        var result = await runDart('a', 'tool/build.dart');
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('with 1 outputs'));
        await d.dir('a', [
          d.dir('web', [
            d.file('a.matchingFiles', 'a|web/a.txt\na|web/b.txt\na|web/c.txt')
          ])
        ]).validate();
      });

      test('picks up deleted files that match the glob', () async {
        // Delete a file matching the glob.
        var aTxtFile = new File(p.join(d.sandbox, 'a', 'web', 'a.txt'));
        aTxtFile.deleteSync();

        // Run a new build and validate.
        var result = await runDart('a', 'tool/build.dart');
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('with 1 outputs'));
        await d.dir('a', [
          d.dir('web', [d.file('a.matchingFiles', 'a|web/b.txt')])
        ]).validate();
      });

      test(
          'doesn\'t cause new builds for files that don\'t match '
          'any globs', () async {
        // Add a new file not matching the glob.
        await d.dir('a', [
          d.dir('web', [d.file('c.other', '')])
        ]).create();

        // Run a new build and validate.
        var result = await runDart('a', 'tool/build.dart');
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('with 0 outputs'));
        await d.dir('a', [
          d.dir('web', [d.file('a.matchingFiles', 'a|web/a.txt\na|web/b.txt')])
        ]).validate();
      });

      test('doesn\'t cause new builds for file changes', () async {
        // Change a file matching the glob.
        await d.dir('a', [
          d.dir('web', [d.file('a.txt', 'changed!')])
        ]).create();

        // Run a new build and validate.
        var result = await runDart('a', 'tool/build.dart');
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('with 0 outputs'));
        await d.dir('a', [
          d.dir('web', [d.file('a.matchingFiles', 'a|web/a.txt\na|web/b.txt')])
        ]).validate();
      });
    });

    group('findAssets with no initial output', () {
      setUp(() async {
        await d.dir('a', [
          await pubspec('a', currentIsolateDependencies: [
            'build',
            'build_runner',
            'build_test',
            'glob'
          ]),
          d.dir('tool', [
            d.file('build.dart', '''
import 'package:build_runner/build_runner.dart';
import 'package:build_test/build_test.dart';
import 'package:glob/glob.dart';

main() async {
  await build(
    [new BuildAction(new OverDeclaringGlobbingBuilder(
        new Glob('**.txt')), 'a')]);
}

class OverDeclaringGlobbingBuilder extends GlobbingBuilder {
  OverDeclaringGlobbingBuilder(Glob glob) : super(glob);

  @override
  Future build(BuildStep buildStep) async {
    var assets = await buildStep.findAssets(glob).toList();
    // Only output if we have a 'web/b.txt' file.
    if (assets.any((id) => id.path == 'web/b.txt')) {
      await super.build(buildStep);
    }
  }
}
''')
          ]),
          d.dir('web', [
            d.file('a.globPlaceholder'),
            d.file('a.txt', ''),
          ]),
        ]).create();

        await pubGet('a');

        // Run a build and validate the output.
        var result = await runDart('a', 'tool/build.dart');
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('with 0 outputs'));
        await d.dir('a', [
          d.dir('web', [d.nothing('a.matchingFiles')])
        ]).validate();
      });

      test('picks up new files that match the glob', () async {
        // Add a new file matching the glob which causes a real output.
        await d.dir('a', [
          d.dir('web', [d.file('b.txt', '')])
        ]).create();

        // Run a new build and validate.
        var result = await runDart('a', 'tool/build.dart');
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('with 1 outputs'));
        await d.dir('a', [
          d.dir('web', [d.file('a.matchingFiles', 'a|web/a.txt\na|web/b.txt')])
        ]).validate();
      });
    });
  });

  group('regression tests', () {
    test(
        'checking for existing outputs works with deleted '
        'intermediate outputs', () async {
      await d.dir('a', [
        await pubspec('a', currentIsolateDependencies: [
          'build',
          'build_runner',
          'build_test',
          'glob'
        ]),
        d.dir('tool', [
          d.file('build.dart', '''
import 'package:build_runner/build_runner.dart';
import 'package:build_test/build_test.dart';

main() async {
  await build([
    new BuildAction(new CopyBuilder(), 'a'),
    new BuildAction(new CopyBuilder(), 'a', inputs: ['**.txt.copy']),
  ]);
}
''')
        ]),
        d.dir('web', [
          d.file('a.txt', 'a'),
          d.file('a.txt.copy.copy', 'a'),
        ]),
      ]).create();

      await pubGet('a');

      var result = await runDart('a', 'tool/build.dart');

      expect(result.exitCode, isNot(0),
          reason: 'build should fail due to conflicting outputs');
      expect(
          result.stderr,
          allOf(contains('Found 1 outputs already on disk'),
              contains('a|web/a.txt.copy.copy')));
    });
  });
}
