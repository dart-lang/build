// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_modules/build_modules.dart';
import 'package:build_modules/src/meta_module.dart';

import 'matchers.dart';

main() {
  test('can serialize meta modules', () async {
    var assetA = new AssetId('a', 'lib/a.dart');
    var moduleA = new Module(assetA, [assetA], <AssetId>[]);
    var metaA = new MetaModule([moduleA]);
    await testBuilder(new MetaModuleBuilder(), {
      'a|lib/a.module.library': 'a|lib/a.dart\n'
          'true\n'
          '\n',
    }, outputs: {
      'a|lib/$metaModuleExtension': encodedMatchesMetaModule(metaA),
    });
  });
}
