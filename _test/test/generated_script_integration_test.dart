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

  // TODO: this test fails, because the "not_enabled_builder" still shows up...
  test('Generates a build script matching the golden', () {
    var generatedScript =
        File('.dart_tool/build/entrypoint/build.dart').readAsStringSync();
    var expected = File('test/goldens/generated_build_script.dart')
        .readAsStringSync()
        .replaceAll('\r', '');
    expect(generatedScript, expected);
  });


  /// Nog een ander probleem:
  ///  of zo lijkt toch:
  ///   - er worden té veel builders binnengepakt obv dependencies...
  ///   - maar nu: both scorekeeper_codege:serializer_generator and scorekeeper_codege:serializer_generator may output lib/proto.config.json
  ///
  /// ik DENK dat het probleem als volgt is:
  ///  - scorekeeper_example_domain wordt in tests / dev_dependencies van scorekeeper_codegen binnengetrokken
  ///  - scorekeeper_example_domain is ook een dependency van ????
  ///   -> kan ik dependency tree opzoeken van een dart project?


}
