// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:build_runner/src/generate/exceptions.dart';
import 'package:build_runner/src/package_graph/apply_builders.dart';

import '../common/common.dart';
import '../common/package_graphs.dart';

void main() {
  test('fail with a nice error if the root package is not right', () async {
    String error;
    try {
      await testBuilders(
        [
          apply(
              '', '', [(_) => new CopyBuilder()], toPackage('not_root_package'))
        ],
        {},
        packageGraph: buildPackageGraph({
          rootPackage('root_package'): ['not_root_package'],
          package('not_root_package'): [],
        }),
      );
    } catch (e) {
      // TODO: Write a throwsAWith(...) matcher?
      error = e.toString();
    } finally {
      expect(error, isNotNull, reason: 'Did not throw!');
      expect(error, contains('operate on package "not_root_package"'));
      expect(error, contains('new BuilderApplication(..., toRoot())'));
    }
  });

  test('fail if an output is on disk and !deleteFilesByDefault', () async {
    expect(
      testBuilders(
        [
          apply('', '', [(_) => new CopyBuilder()], toRoot())
        ],
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
