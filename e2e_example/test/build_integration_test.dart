// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'package:test/test.dart';

import 'common/utils.dart';

void main() {
  group('--fail-on-severe', () {
    setUp(() async {
      ensureCleanGitClient();
      // Run a regular build in known clean state before creating a breaking
      // edit, this allows us to re-use most of the build to speed up these
      // tests.
      await runAutoBuild();
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
}
