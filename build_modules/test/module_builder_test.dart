// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_modules/src/meta_module.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'matchers.dart';

void main() {
  final platform = DartPlatform.register('test', ['dart:async']);

  test('can serialize modules and only output for primary sources', () async {
    final assetA = AssetId('a', 'lib/a.dart');
    final assetB = AssetId('a', 'lib/b.dart');
    final assetC = AssetId('a', 'lib/c.dart');
    final assetD = AssetId('a', 'lib/d.dart');
    final assetE = AssetId('a', 'lib/e.dart');
    final moduleA = Module(assetA, [assetA], <AssetId>[], platform, true);
    final moduleB = Module(
      assetB,
      [assetB, assetC],
      <AssetId>[],
      platform,
      true,
    );
    final moduleD = Module(
      assetD,
      [assetD, assetE],
      <AssetId>[],
      platform,
      false,
    );
    final metaModule = MetaModule([moduleA, moduleB, moduleD]);
    await testBuilder(
      ModuleBuilder(platform),
      {
        'a|lib/a.dart': '',
        'a|lib/b.dart': '',
        'a|lib/c.dart': '',
        'a|lib/d.dart': '',
        'a|lib/e.dart': '',
        'a|lib/${metaModuleCleanExtension(platform)}': jsonEncode(
          metaModule.toJson(),
        ),
        'a|lib/a$moduleLibraryExtension':
            ModuleLibrary.fromSource(assetA, '').serialize(),
        'a|lib/b$moduleLibraryExtension':
            ModuleLibrary.fromSource(assetB, '').serialize(),
        'a|lib/c$moduleLibraryExtension':
            ModuleLibrary.fromSource(assetC, '').serialize(),
        'a|lib/d$moduleLibraryExtension':
            ModuleLibrary.fromSource(assetD, '').serialize(),
        'a|lib/e$moduleLibraryExtension':
            ModuleLibrary.fromSource(assetE, '').serialize(),
      },
      outputs: {
        'a|lib/a${moduleExtension(platform)}': encodedMatchesModule(moduleA),
        'a|lib/b${moduleExtension(platform)}': encodedMatchesModule(moduleB),
        'a|lib/d${moduleExtension(platform)}': encodedMatchesModule(moduleD),
      },
    );
  });

  test('can serialize modules and output all modules when strongly connected '
      'components are disabled', () async {
    final assetA = AssetId('a', 'lib/a.dart');
    final assetB = AssetId('a', 'lib/b.dart');
    final assetC = AssetId('a', 'lib/c.dart');
    final assetD = AssetId('a', 'lib/d.dart');
    final assetE = AssetId('a', 'lib/e.dart');
    final moduleA = Module(assetA, [assetA], <AssetId>[], platform, true);
    final moduleB = Module(
      assetB,
      [assetB, assetC],
      <AssetId>[],
      platform,
      true,
    );
    final moduleC = Module(assetC, [assetC], <AssetId>[], platform, true);
    final moduleD = Module(
      assetD,
      [assetD, assetE],
      <AssetId>[],
      platform,
      false,
    );
    final moduleE = Module(assetE, [assetE], <AssetId>[], platform, true);
    final metaModule = MetaModule([
      moduleA,
      moduleB,
      moduleC,
      moduleD,
      moduleE,
    ]);
    await testBuilder(
      ModuleBuilder(platform, usesWebHotReload: true),
      {
        'a|lib/a.dart': '',
        'a|lib/b.dart': '',
        'a|lib/c.dart': '',
        'a|lib/d.dart': '',
        'a|lib/e.dart': '',
        'a|lib/${metaModuleExtension(platform)}': jsonEncode(
          metaModule.toJson(),
        ),
        'a|lib/a$moduleLibraryExtension':
            ModuleLibrary.fromSource(assetA, '').serialize(),
        'a|lib/b$moduleLibraryExtension':
            ModuleLibrary.fromSource(assetB, '').serialize(),
        'a|lib/c$moduleLibraryExtension':
            ModuleLibrary.fromSource(assetC, '').serialize(),
        'a|lib/d$moduleLibraryExtension':
            ModuleLibrary.fromSource(assetD, '').serialize(),
        'a|lib/e$moduleLibraryExtension':
            ModuleLibrary.fromSource(assetE, '').serialize(),
      },
      outputs: {
        'a|lib/a${moduleExtension(platform)}': encodedMatchesModule(moduleA),
        'a|lib/b${moduleExtension(platform)}': encodedMatchesModule(moduleB),
        'a|lib/c${moduleExtension(platform)}': encodedMatchesModule(moduleC),
        'a|lib/d${moduleExtension(platform)}': encodedMatchesModule(moduleD),
        'a|lib/e${moduleExtension(platform)}': encodedMatchesModule(moduleE),
      },
    );
  });
}
