// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_modules/build_modules.dart';
import 'package:build_modules/src/meta_module.dart';
import 'package:build_modules/src/module_library.dart';
import 'package:build_modules/src/platform.dart';

import 'matchers.dart';

void main() {
  var testPlatform = DartPlatform.register('test', ['dart:async']);

  test('can serialize meta modules', () async {
    var assetA = AssetId('a', 'lib/a.dart');
    var moduleA = Module(assetA, [assetA], <AssetId>[], testPlatform, true);
    var metaA = MetaModule([moduleA]);
    await testBuilder(MetaModuleBuilder(testPlatform), {
      'a|lib/a.module.library':
          ModuleLibrary.fromSource(assetA, '').serialize(),
    }, outputs: {
      'a|lib/${metaModuleExtension(testPlatform)}':
          encodedMatchesMetaModule(metaA),
    });
  });

  group('isSupported', () {
    test('is false for libraries that import dart:io on web', () async {
      var assetA = AssetId('a', 'lib/a.dart');
      var assetB = AssetId('a', 'lib/b.dart');
      var moduleA = Module(assetA, [assetA], <AssetId>[], testPlatform, true);
      var moduleB = Module(assetB, [assetB], <AssetId>[], testPlatform, false);
      var metaA = MetaModule([moduleA, moduleB]);
      await testBuilder(MetaModuleBuilder(testPlatform), {
        'a|lib/a.module.library':
            ModuleLibrary.fromSource(assetA, '').serialize(),
        'a|lib/b.module.library':
            ModuleLibrary.fromSource(assetB, "import 'dart:io';").serialize(),
      }, outputs: {
        'a|lib/${metaModuleExtension(testPlatform)}':
            encodedMatchesMetaModule(metaA),
      });
    });

    test('is false for connected components that import dart:io on web',
        () async {
      var assetA = AssetId('a', 'lib/a.dart');
      var assetB = AssetId('a', 'lib/b.dart');
      var moduleA =
          Module(assetA, [assetA, assetB], <AssetId>[], testPlatform, false);
      var metaA = MetaModule([moduleA]);
      await testBuilder(MetaModuleBuilder(testPlatform), {
        'a|lib/a.module.library':
            ModuleLibrary.fromSource(assetA, "import 'b.dart';").serialize(),
        'a|lib/b.module.library': ModuleLibrary.fromSource(
                assetB, "import 'dart:io';import 'a.dart';")
            .serialize(),
      }, outputs: {
        'a|lib/${metaModuleExtension(testPlatform)}':
            encodedMatchesMetaModule(metaA),
      });
    });

    test('is false for coarse modules that import dart:io on web', () async {
      var assetA = AssetId('a', 'lib/a.dart');
      var assetB = AssetId('a', 'lib/src/b.dart');
      var moduleA =
          Module(assetA, [assetA, assetB], <AssetId>[], testPlatform, false);
      var metaA = MetaModule([moduleA]);
      await testBuilder(MetaModuleBuilder(testPlatform), {
        'a|lib/a.module.library':
            ModuleLibrary.fromSource(assetA, "import 'src/b.dart';")
                .serialize(),
        'a|lib/src/b.module.library':
            ModuleLibrary.fromSource(assetB, "import 'dart:io';").serialize(),
      }, outputs: {
        'a|lib/${metaModuleExtension(testPlatform)}':
            encodedMatchesMetaModule(metaA),
      });
    });

    test('does not look at dependencies', () async {
      var assetA = AssetId('a', 'lib/a.dart');
      var assetB = AssetId('a', 'lib/b.dart');
      var moduleA =
          Module(assetA, [assetA], <AssetId>[assetB], testPlatform, true);
      var moduleB = Module(assetB, [assetB], <AssetId>[], testPlatform, false);
      var metaA = MetaModule([moduleA, moduleB]);
      await testBuilder(MetaModuleBuilder(testPlatform), {
        'a|lib/a.module.library':
            ModuleLibrary.fromSource(assetA, "import 'b.dart';").serialize(),
        'a|lib/b.module.library':
            ModuleLibrary.fromSource(assetB, "import 'dart:io';").serialize(),
      }, outputs: {
        'a|lib/${metaModuleExtension(testPlatform)}':
            encodedMatchesMetaModule(metaA),
      });
    });
  });
}
