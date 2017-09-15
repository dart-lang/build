// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_compilers/build_compilers.dart';

import 'matchers.dart';

main() {
  Map<String, dynamic> assets;

  setUp(() {
    assets = {
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
    // Use `testBuilder` to create unlinked summaries for the actual test.
    var writer = new InMemoryAssetWriter();
    await testBuilder(new UnlinkedSummaryBuilder(), assets, writer: writer);
    // Add the unlinked summaries to `assets`.
    writer.assets.forEach((id, datedValue) {
      assets['${id.package}|${id.path}'] = datedValue.bytesValue;
    });

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
