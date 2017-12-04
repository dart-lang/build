// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:async';
import 'dart:io';

import 'package:build_runner/src/util/constants.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'common/utils.dart';

void main() {
  group('Manual build script changes', () {
    setUp(() async {
      ensureCleanGitClient();
      await startManualServer(ensureCleanBuild: true, verbose: true);
      addTearDown(() => stopServer(cleanUp: true));
    });

    test('while serving prompt the user to restart', () async {
      await testEditWhileServing(true);
    });

    test('while not serving invalidate the next build', () async {
      await testEditBetweenBuilds(true);
    });

    test('Invalid asset graph version causes a new full build', () async {
      await stopServer();
      var assetGraph = assetGraphPathFor(
          new File(p.join('tool', 'build.dart')).absolute.path);
      // Prepend a 1 to the version number
      await replaceAllInFile(assetGraph, '"version":', '"version":1');
      await startManualServer(extraExpects: [
        () => nextStdOutLine(
            'Throwing away cached asset graph due to version mismatch.'),
        () => nextStdOutLine('Building new asset graph'),
      ], verbose: true);
    });
  });

  group('Generated build script changes', () {
    setUp(() async {
      ensureCleanGitClient();
      await startAutoServer(ensureCleanBuild: true, verbose: true);
      addTearDown(() => stopServer(cleanUp: true));
    });

    test('while serving prompt the user to restart', () async {
      await testEditWhileServing(false);
    });

    test('while not serving invalidate the next build', () async {
      await testEditBetweenBuilds(false);
    });
  });
}

Future<Null> testEditWhileServing(bool manualScript) async {
  var filePath = manualScript
      ? 'tool/build.dart'
      : '.dart_tool/build/entrypoint/build.dart';
  var startServer = manualScript ? startManualServer : startAutoServer;
  var terminateLine =
      nextStdOutLine('Terminating. No further builds will be scheduled');
  await replaceAllInFile(filePath, 'Serving', 'Now serving');
  await terminateLine;
  await stopServer();
  await startServer(extraExpects: [
    () => nextStdOutLine('Invalidating asset graph due to build script update'),
    () => nextStdOutLine('Building new asset graph'),
  ], verbose: true);
}

Future<Null> testEditBetweenBuilds(bool manualScript) async {
  var filePath = manualScript
      ? 'tool/build.dart'
      : '.dart_tool/build/entrypoint/build.dart';
  var startServer = manualScript ? startManualServer : startAutoServer;
  await stopServer();
  await replaceAllInFile(filePath, 'Serving', 'Now serving');
  await startServer(extraExpects: [
    () => nextStdOutLine('Invalidating asset graph due to build script update'),
    () => nextStdOutLine('Building new asset graph'),
  ], verbose: true);
}
