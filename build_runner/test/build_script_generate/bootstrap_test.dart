// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@Timeout.factor(2)
library;

import 'package:build_runner/build_script_generate.dart';
import 'package:test/test.dart';

void main() {
  test('invokes custom error function', () async {
    Object? error;
    StackTrace? stackTrace;

    // TODO: https://github.com/dart-lang/sdk/issues/52469 Use IOOverrides to
    // run this is a tmp dir, this currently bashes over the actual cache dir.
    await expectLater(
      generateAndRun(
        [],
        generateBuildScript: () async {
          return '''
              void main() {
                throw 'expected error';
              }
              ''';
        },
        handleUncaughtError: (err, trace) {
          error = err;
          stackTrace = trace;
        },
      ),
      completion(1),
    );

    expect(error, 'expected error');
    expect(stackTrace, isNotNull);
  });
}
