// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_test_common/common.dart';
import 'package:build/build.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:test/test.dart';

void main() {
  test('uses builder options', () async {
    Builder copyBuilder(BuilderOptions options) => TestBuilder(
      buildExtensions: replaceExtension(
        options.config['inputExtension'] as String,
        '.copy',
      ),
    );

    await testPhases(
      [
        apply('a:optioned_builder', [copyBuilder], toRoot(), hideOutput: false),
      ],
      {
        'a|lib/file.nomatch': 'a',
        'a|lib/file.matches': 'b',
        'a|build.yaml': '''
targets:
  a:
    builders:
      a:optioned_builder:
        options:
          inputExtension: .matches
''',
      },
      outputs: {'a|lib/file.copy': 'b'},
    );
  });

  test('isRoot is applied correctly', () async {
    Builder copyBuilder(BuilderOptions options) => TestBuilder(
      buildExtensions: replaceExtension(
        '.txt',
        options.isRoot ? '.root.copy' : '.dep.copy',
      ),
    );
    var packageGraph = buildPackageGraph({
      rootPackage('a'): ['b'],
      package('b'): [],
    });
    await testPhases(
      [
        apply(
          'a:optioned_builder',
          [copyBuilder],
          toAllPackages(),
          hideOutput: true,
        ),
      ],
      {'a|lib/a.txt': 'a', 'b|lib/b.txt': 'b'},
      outputs: {r'$$a|lib/a.root.copy': 'a', r'$$b|lib/b.dep.copy': 'b'},
      packageGraph: packageGraph,
    );
  });
}
