// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_web_compilers/build_web_compilers.dart';

import 'matchers.dart';
import 'util.dart';

main() {
  Map<String, dynamic> assets;

  setUp(() async {
    assets = {
      'build_web_compilers|lib/src/analysis_options.default.yaml': '',
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
  });

  test("can output unlinked analyzer summaries for modules under lib and web",
      () async {
    var expectedOutputs = <String, Matcher>{
      'b|lib/b.unlinked.sum': new HasUnlinkedUris(['package:b/b.dart']),
      'a|lib/a.unlinked.sum': new HasUnlinkedUris(['package:a/a.dart']),
      'a|web/index.unlinked.sum':
          new HasUnlinkedUris([endsWith('web/index.dart')]),
    };
    await testBuilder(new UnlinkedSummaryBuilder(), assets,
        outputs: expectedOutputs);
  });

  test("can output linked analyzer summaries for modules under lib and web",
      () async {
    // Build the unlinked summaries first.
    await testBuilderAndCollectAssets(new UnlinkedSummaryBuilder(), assets);

    // Actual test for LinkedSummaryBuilder;
    var expectedOutputs = <String, Matcher>{
      'b|lib/b.linked.sum': allOf(new HasLinkedUris(['package:b/b.dart']),
          new HasUnlinkedUris(['package:b/b.dart'])),
      'a|lib/a.linked.sum': allOf(
          new HasLinkedUris(
              unorderedEquals(['package:b/b.dart', 'package:a/a.dart'])),
          new HasUnlinkedUris(['package:a/a.dart'])),
      'a|web/index.linked.sum': allOf(
          new HasLinkedUris(unorderedEquals([
            'package:b/b.dart',
            'package:a/a.dart',
            endsWith('web/index.dart')
          ])),
          new HasUnlinkedUris([endsWith('web/index.dart')])),
    };
    await testBuilder(new LinkedSummaryBuilder(), assets,
        outputs: expectedOutputs);
  });
}
