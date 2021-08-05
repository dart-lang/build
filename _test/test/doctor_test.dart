// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'package:test/test.dart';

import 'common/utils.dart';

void main() {
  test('doctor command reports no issues', () async {
    var result = await runCommand(['doctor']);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('No problems found'));
  });
}
