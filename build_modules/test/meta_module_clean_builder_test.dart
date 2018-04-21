// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'package:build/build.dart';
import 'package:build_modules/src/meta_module_clean_builder.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_modules/build_modules.dart';
import 'package:build_modules/src/meta_module.dart';

import 'matchers.dart';

main() {
  test('unconnected components stay disjoint', () async {
    var assetA = new AssetId('a', 'lib/a.dart');
    var assetB = new AssetId('b', 'lib/b.dart');
    var moduleA = new Module(assetA, [assetA], []);
    var moduleB = new Module(assetB, [assetB], []);

    var metaA = new MetaModule([moduleA]);
    var metaB = new MetaModule([moduleB]);

    await testBuilder(new MetaModuleCleanBuilder(), {
      'a|lib/.meta_module': json.encode(metaA),
      'b|lib/.meta_module': json.encode(metaB),
      'a|lib/a.dart': 'import "package:b/b.dart"',
      'b|lib/b.dart': 'import "package:a/a.dart"',
    }, outputs: {
      'a|lib/.meta_module_clean': encodedMatchesMetaModule(metaA),
      'b|lib/.meta_module_clean': encodedMatchesMetaModule(metaB),
    });
  });

  test('can handle cycles', () async {
    var assetA = new AssetId('a', 'lib/a.dart');
    var assetB = new AssetId('b', 'lib/b.dart');
    var moduleA = new Module(assetA, [assetA], [assetB]);
    var moduleB = new Module(assetB, [assetB], [assetA]);

    var metaA = new MetaModule([moduleA]);
    var metaB = new MetaModule([moduleB]);
    var clean = new MetaModule([
      new Module(assetA, [assetA, assetB], [])
    ]);

    await testBuilder(new MetaModuleCleanBuilder(), {
      'a|lib/.meta_module': json.encode(metaA),
      'b|lib/.meta_module': json.encode(metaB),
      'a|lib/a.dart': 'import "package:b/b.dart"',
      'b|lib/b.dart': 'import "package:a/a.dart"',
    }, outputs: {
      'a|lib/.meta_module_clean': encodedMatchesMetaModule(clean),
      'b|lib/.meta_module_clean': encodedMatchesMetaModule(clean),
    });
  });
}
