// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_compilers/build_compilers.dart';

import 'util.dart';

main() {
  Map<String, dynamic> assets;

  setUp(() async {
    assets = {
      'build_compilers|lib/src/analysis_options.default.yaml': '',
      'b|lib/b.dart': '''final world = 'world';''',
      'a|lib/a.dart': '''
        import 'package:b/b.dart';
        final hello = world;
      ''',
      'a|web/index.dart': '''
        import "package:a/a.dart";
        main() {
          print(hello);
        }
      ''',
    };

    // Set up all the other required inputs for this test.
    await testBuilderAndCollectAssets(new ModuleBuilder(), assets);
    await testBuilderAndCollectAssets(new UnlinkedSummaryBuilder(), assets);
    await testBuilderAndCollectAssets(new LinkedSummaryBuilder(), assets);
  });

  test("can compile ddc modules under lib and web", () async {
    var expectedOutputs = {
      'b|lib/b.js': decodedMatches(contains('world')),
      'b|lib/b.js.map': decodedMatches(contains('b.dart')),
      'a|lib/a.js': decodedMatches(contains('hello')),
      'a|lib/a.js.map': decodedMatches(contains('a.dart')),
      'a|web/index.js': decodedMatches(contains('main')),
      'a|web/index.js.map': decodedMatches(contains('index.dart')),
    };
    await testBuilder(new DevCompilerBuilder(), assets,
        outputs: expectedOutputs);
  });
}
