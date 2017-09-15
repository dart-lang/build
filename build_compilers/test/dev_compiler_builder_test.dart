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
final hello = world;''',
      'a|web/index.dart': '''
import "package:a/a.dart";
main() {print(hello);}''',
    };
  });

  test("can compile ddc modules under lib and web", () async {
    // Use `testBuilder` to create unlinked summaries for the actual test.
    var writer = new InMemoryAssetWriter();
    await testBuilder(new UnlinkedSummaryBuilder(), assets, writer: writer);
    // Add the unlinked summaries to `assets`.
    writer.assets.forEach((id, datedValue) {
      assets['${id.package}|${id.path}'] = datedValue.bytesValue;
    });

    // Use `testBuilder` to create linked summaries for the actual test.
    writer = new InMemoryAssetWriter();
    await testBuilder(new LinkedSummaryBuilder(), assets, writer: writer);
    // Add the linked summaries to `assets`.
    writer.assets.forEach((id, datedValue) {
      assets['${id.package}|${id.path}'] = datedValue.bytesValue;
    });

    var expectedOutputs = {
      'b|lib/b.js': new Utf8Decoded(contains('world')),
      'a|lib/a.js': new Utf8Decoded(contains('hello')),
      'a|web/index.js': new Utf8Decoded(contains('main')),
    };
    await testBuilder(new DevCompilerBuilder(), assets,
        outputs: expectedOutputs);
  });
}
