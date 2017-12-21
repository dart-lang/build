// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:build_runner/src/generate/exceptions.dart';
import 'package:build_runner/src/package_graph/apply_builders.dart';

import '../common/common.dart';
import '../common/package_graphs.dart';

void main() {
  test('fail if an output is on disk and !deleteFilesByDefault', () async {
    expect(
      testBuilders(
        [applyToRoot(new CopyBuilder())],
        {
          'a|lib/a.dart': '',
          'a|lib/a.dart.copy': '',
        },
        packageGraph: buildPackageGraph({rootPackage('a'): []}),
        deleteFilesByDefault: false,
      ),
      throwsA(const isInstanceOf<UnexpectedExistingOutputsException>()),
    );
  });
}
