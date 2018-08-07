// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:io' show File;

import 'package:test/test.dart';

import 'common/utils.dart';

void main() {
  setUpAll(() async {
    await runCommand(['generate-build-script']);
  });

  test('Generates a build script matching the golden', () {
    var generatedScript =
        File('.dart_tool/build/entrypoint/build.dart').readAsStringSync();
    var expected = File('test/goldens/generated_build_script.dart')
        .readAsStringSync()
        .replaceAll('\r', '');
    expect(generatedScript, expected);
  });
}
