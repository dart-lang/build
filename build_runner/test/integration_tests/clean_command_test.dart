// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration2'])
library;

import 'package:build_runner/src/constants.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('clean command', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      files: {},
    );

    await tester.run('root_pkg', 'dart run build_runner build');
    expect(tester.read('root_pkg/$entrypointScriptPath'), isNotNull);
    await tester.run('root_pkg', 'dart run build_runner clean');
    expect(tester.readFileTree('root_pkg/.dart_tool/build'), isNull);
  });
}
