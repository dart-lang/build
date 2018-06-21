// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'package:test/test.dart';

import 'common/utils.dart';

void main() {
  test('Exceptions from the isolate are handled properly', () async {
    var asyncResult = runBuild(trailingArgs: ['--config', 'throws']);
    expect(asyncResult, completes,
        reason:
            'Wrapper script should not hang if the isolate has an unhandled '
            'error.');
    var result = await asyncResult;
    expect(
        result.stdout, contains('Throwing on purpose cause you asked for it!'),
        reason: 'Exceptions from the isolate should be logged.');
    expect(result.exitCode, isNot(0),
        reason:
            'The exit code should be non-zero if there is an unhandled error.');
  });
}
