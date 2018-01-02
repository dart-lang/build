// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:io';

import 'package:test/test.dart';

import 'common/utils.dart';

void main() {
  var dart2JsBuildFile = new File('build.yaml.dart2js');
  var actualBuildFile = new File('build.yaml');

  setUpAll(() async {
    expect(await dart2JsBuildFile.exists(), isTrue);
    expect(await actualBuildFile.exists(), isFalse);
    await actualBuildFile.writeAsString(await dart2JsBuildFile.readAsString());
  });

  tearDownAll(() async {
    await actualBuildFile.delete();
  });

  test('Can run tests using dart2js', () async {
    await expectTestsPass(usePrecompiled: true, useManualScript: false);
  });
}
