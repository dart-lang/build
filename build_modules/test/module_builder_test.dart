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
  test('can serialize modules and only output for primary sources', () async {
    var assetA = AssetId('a', 'lib/a.dart');
    var assetB = AssetId('a', 'lib/b.dart');
    var assetC = AssetId('a', 'lib/c.dart');
    var assetD = AssetId('a', 'lib/d.dart');
    var assetE = AssetId('a', 'lib/e.dart');
    var moduleA = Module(assetA, [assetA], <AssetId>[]);
    var moduleB = Module(assetB, [assetB, assetC], <AssetId>[]);
    var moduleD = Module(assetD, [assetD, assetE], <AssetId>[]);
    var metaModule = MetaModule([moduleA, moduleB, moduleD]);
    await testBuilder(ModuleBuilder(), {
      'a|lib/a.dart': '',
      'a|lib/b.dart': '',
      'a|lib/c.dart': '',
      'a|lib/d.dart': '',
      'a|lib/e.dart': '',
      'a|lib/.meta_module.clean': jsonEncode(metaModule.toJson()),
    }, outputs: {
      'a|lib/a.module': encodedMatchesModule(moduleA),
      'a|lib/b.module': encodedMatchesModule(moduleB),
      'a|lib/d.module': encodedMatchesModule(moduleD),
    });
  });
}
