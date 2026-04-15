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
    expect(tester.readFileTree('root_pkg/.dart_tool/build'), {
      'lock/build_runner.lock': '',
    });

    // Clean --workspace deletes files in the workspace root.
    tester.writePackage(
      name: 'p1',
      dependencies: ['build_runner'],
      files: {},
      inWorkspace: true,
    );
    tester.writePackage(
      name: 'p2',
      dependencies: ['build_runner'],
      files: {},
      inWorkspace: true,
    );
    tester.writeWorkspacePubspec(packages: ['p1', 'p2']);

    await tester.run('p1', 'dart run build_runner build --workspace');

    // TODO(davidmorgan): `build --workspace` should put the entrypoint in the
    // workspace root when run from a subpackage. Currently it puts it in the
    // subpackage.
    expect(tester.read('p1/$entrypointScriptPath'), isNotNull);

    // Check if asset graph is created in the workspace root.
    expect(tester.read(assetGraphPath), isNotNull);

    await tester.run('p1', 'dart run build_runner clean --workspace');

    // Verify that clean --workspace deletes the asset graph.
    expect(tester.read(assetGraphPath), isNull);

    // TODO(davidmorgan): `clean --workspace` should delete the entrypoint in
    // the workspace root once it is moved there. Currently it does not delete
    // it because it is in the subpackage.
    expect(tester.read('p1/$entrypointScriptPath'), isNotNull);
  });
}
