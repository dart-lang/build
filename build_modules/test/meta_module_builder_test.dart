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

main() {
  test('can serialize meta modules', () async {
    var assetA = AssetId('a', 'lib/a.dart');
    var moduleA = Module(assetA, [assetA], <AssetId>[], DartPlatform.dart2js);
    var metaA = MetaModule([moduleA]);
    await testBuilder(MetaModuleBuilder(DartPlatform.dart2js), {
      'a|lib/a.module.library':
          ModuleLibrary.fromSource(assetA, '').serialize(),
    }, outputs: {
      'a|lib/${metaModuleExtension(DartPlatform.dart2js)}':
          encodedMatchesMetaModule(metaA),
    });
  });
}
