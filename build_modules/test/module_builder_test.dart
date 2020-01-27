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
import 'package:build_modules/src/module_library.dart';

import 'matchers.dart';

void main() {
  final platform = DartPlatform.register('test', ['dart:async']);

  test('can serialize modules and only output for primary sources', () async {
    var assetA = AssetId('a', 'lib/a.dart');
    var assetB = AssetId('a', 'lib/b.dart');
    var assetC = AssetId('a', 'lib/c.dart');
    var assetD = AssetId('a', 'lib/d.dart');
    var assetE = AssetId('a', 'lib/e.dart');
    var moduleA = Module(assetA, [assetA], <AssetId>[], platform, true);
    var moduleB = Module(assetB, [assetB, assetC], <AssetId>[], platform, true);
    var moduleD =
        Module(assetD, [assetD, assetE], <AssetId>[], platform, false);
    var metaModule = MetaModule([moduleA, moduleB, moduleD]);
    await testBuilder(ModuleBuilder(platform), {
      'a|lib/a.dart': '',
      'a|lib/b.dart': '',
      'a|lib/c.dart': '',
      'a|lib/d.dart': '',
      'a|lib/e.dart': '',
      'a|lib/${metaModuleCleanExtension(platform)}':
          jsonEncode(metaModule.toJson()),
      'a|lib/c$moduleLibraryExtension':
          ModuleLibrary.fromSource(assetC, '').serialize(),
      'a|lib/e$moduleLibraryExtension':
          ModuleLibrary.fromSource(assetE, '').serialize(),
    }, outputs: {
      'a|lib/a${moduleExtension(platform)}': encodedMatchesModule(moduleA),
      'a|lib/b${moduleExtension(platform)}': encodedMatchesModule(moduleB),
      'a|lib/d${moduleExtension(platform)}': encodedMatchesModule(moduleD),
    });
  });
}
