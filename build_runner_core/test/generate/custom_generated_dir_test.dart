// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_test_common/common.dart';
import 'package:build/build.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:test/test.dart';

void main() {
  final customGeneratedDir = 'my-custom-dir';
  overrideGeneratedOutputDirectory(customGeneratedDir);

  test('can output files to a custom generated dir', () async {
    final result = await testBuilders(
      [TestBuilder(buildExtensions: appendExtension('.copy', from: '.txt'))],
      {'a|lib/a.txt': 'a'},
    );
    expect(
      result.readerWriter.testing.exists(
        AssetId('a', '.dart_tool/build/$customGeneratedDir/a/lib/a.txt.copy'),
      ),
      isTrue,
    );
  });
}
