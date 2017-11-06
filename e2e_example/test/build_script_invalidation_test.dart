// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'package:test/test.dart';

import 'common/utils.dart';

void main() {
  group('Build script changes', () {
    setUp(() async {
      ensureCleanGitClient();
    });

    test('while serving prompt the user to restart', () async {
      await startServer();
      var terminateLine =
          nextStdOutLine('Terminating. No further builds will be scheduled');
      await replaceAllInFile(
          'tool/build.dart', 'ThrowingBuilder', 'FailingBuilder');
      await terminateLine;
      await stopServer();
      await startServer(extraExpects: [
        () => nextStdOutLine(
            'Invalidating asset graph due to build script update'),
        () => nextStdOutLine('Building new asset graph'),
      ]);
      await stopServer();
    });

    test('while not serving invalidate the next build', () async {
      await startServer();
      await stopServer();
      await replaceAllInFile(
          'tool/build.dart', 'ThrowingBuilder', 'FailingBuilder');
      await startServer(extraExpects: [
        () => nextStdOutLine(
            'Invalidating asset graph due to build script update'),
        () => nextStdOutLine('Building new asset graph'),
      ]);
      await stopServer();
    });
  });
}
