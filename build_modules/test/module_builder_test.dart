// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_modules/build_modules.dart';
import 'package:build_modules/src/meta_module.dart';
import 'package:build_modules/src/modules.dart';

import 'matchers.dart';

main() {
  test('can serialize fine modules and only output for primary sources',
      () async {
    var assetA = new AssetId('a', 'lib/a.dart');
    var assetB = new AssetId('a', 'lib/b.dart');
    var assetC = new AssetId('a', 'lib/c.dart');
    var assetD = new AssetId('a', 'lib/d.dart');
    var assetE = new AssetId('a', 'lib/e.dart');
    var moduleA = new Module(assetA, [assetA], <AssetId>[]);
    var moduleB = new Module(assetB, [assetB, assetC], <AssetId>[]);
    var moduleD = new Module(assetD, [assetD, assetE], <AssetId>[]);
    await testBuilder(new ModuleBuilder(), {
      'a|lib/a.dart': '',
      'a|lib/b.dart': 'part "c.dart";',
      'a|lib/c.dart': 'part of "b.dart";',
      'a|lib/d.dart': 'import "e.dart";',
      'a|lib/e.dart': 'import "d.dart";',
    }, outputs: {
      'a|lib/a.module': encodedMatchesModule(moduleA),
      'a|lib/b.module': encodedMatchesModule(moduleB),
      'a|lib/d.module': encodedMatchesModule(moduleD),
    });
  });
  test('can serialize course modules and only output for primary sources',
      () async {
    var assetA = new AssetId('a', 'lib/a.dart');
    var moduleA = new Module(assetA, [assetA], <AssetId>[]);
    var meta = new MetaModule([moduleA]);
    await testBuilder(new ModuleBuilder(isCourse: true), {
      'a|lib/.meta_module_clean': json.encode(meta),
      'a|lib/a.dart': '',
    }, outputs: {
      'a|lib/a.module': encodedMatchesModule(moduleA),
    });
  });
}
