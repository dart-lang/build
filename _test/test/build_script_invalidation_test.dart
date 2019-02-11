// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:io';

import 'package:build_runner_core/src/util/constants.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'common/utils.dart';

void main() {
  setUp(() async {
    ensureCleanGitClient();
    await startServer(ensureCleanBuild: true, buildArgs: ['lib']);
    addTearDown(() => stopServer(cleanUp: true));
  });

  group('Build script changes', () {
    test('while serving prompt the user to restart', () async {
      var filePath = p.join('pkgs', 'provides_builder', 'lib', 'builders.dart');
      var expectedLines = [
        'Terminating builds due to build script update',
        'Creating build script snapshot',
        'Building new asset graph',
      ];
      expect(stdOutLines, isNotNull);
      for (var line in expectedLines) {
        expect(stdOutLines, emitsThrough(contains(line)));
      }
      await replaceAllInFile(filePath, RegExp(r'$'), '// do a build');
    });

    test('while not serving invalidate the next build', () async {
      // Create a random file in the generated dir, this should get cleaned up.
      var extraFilePath =
          p.join('.dart_tool', 'build', 'generated', 'foo', 'foo.txt');
      await createFile(extraFilePath, 'bar');
      expect(await File(extraFilePath).exists(), isTrue);

      var filePath = p.join('pkgs', 'provides_builder', 'lib', 'builders.dart');
      await stopServer();
      await replaceAllInFile(filePath, RegExp(r'$'), '// do a build');
      await startServer(buildArgs: [
        'lib'
      ], extraExpects: [
        () => nextStdOutLine(
            'Invalidating asset graph due to build script update'),
        () => nextStdOutLine('Creating build script snapshot'),
        () => nextStdOutLine('Building new asset graph'),
        () => nextStdOutLine('Succeeded after'),
      ]);
      expect(await File(extraFilePath).exists(), isFalse,
          reason: 'The cache dir should get deleted when the build '
              'script changes.');
    }, onPlatform: {'windows': const Skip('flaky on windows')});

    test('Invalid asset graph version causes a new full build', () async {
      await stopServer();
      var assetGraph = assetGraphPathFor(p.url
          .join('.dart_tool', 'build', 'entrypoint', 'build.dart.snapshot'));
      // Prepend a 1 to the version number
      await replaceAllInFile(assetGraph, '"version":', '"version":1');

      // Create a random file in the generated dir, this should get cleaned up.
      var extraFilePath =
          p.join('.dart_tool', 'build', 'generated', 'foo', 'foo.txt');
      await createFile(extraFilePath, 'bar');
      expect(await File(extraFilePath).exists(), isTrue);

      await startServer(buildArgs: [
        'lib'
      ], extraExpects: [
        () => nextStdOutLine(
            'Throwing away cached asset graph due to version mismatch'),
        () => nextStdOutLine('Building new asset graph'),
        () => nextStdOutLine('Succeeded after'),
      ]);
      expect(await File(extraFilePath).exists(), isFalse,
          reason: 'The cache dir should get deleted when the asset graph '
              'can\'t be parsed');
    });
  });

  test('Build config changes rerun but dont invalidate the build', () async {
    var expectedLines = [
      'Terminating builds due to _test:build.yaml update',
      'Builds finished. Safe to exit',
      'Running build completed',
      'with 0 outputs',
    ];
    expect(stdOutLines, isNotNull);
    for (var line in expectedLines) {
      expect(stdOutLines, emitsThrough(contains(line)));
    }
    await replaceAllInFile('build.yaml', '''
targets:''', '''
# Test Edit
targets:''');
  });
}
