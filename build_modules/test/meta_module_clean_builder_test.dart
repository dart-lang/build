// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_modules/src/meta_module_clean_builder.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:build_modules/build_modules.dart';
import 'package:build_modules/src/meta_module.dart';
import 'package:build_modules/src/platform.dart';

import 'matchers.dart';

void main() {
  final assetA = AssetId('a', 'lib/a.dart');
  final assetB = AssetId('b', 'lib/b.dart');
  final platform = DartPlatform.register('test', ['dart:async']);

  test('unconnected components stay disjoint', () async {
    var moduleA = Module(assetA, [assetA], [], platform, true);
    var moduleB = Module(assetB, [assetB], [], platform, true);

    var metaA = MetaModule([moduleA]);
    var metaB = MetaModule([moduleB]);

    await testBuilder(MetaModuleCleanBuilder(platform), {
      'a|lib/${metaModuleExtension(platform)}': json.encode(metaA),
      'b|lib/${metaModuleExtension(platform)}': json.encode(metaB),
      'a|lib/a.dart': 'import "package:b/b.dart"',
      'b|lib/b.dart': 'import "package:a/a.dart"',
    }, outputs: {
      'a|lib/${metaModuleCleanExtension(platform)}':
          encodedMatchesMetaModule(metaA),
      'b|lib/${metaModuleCleanExtension(platform)}':
          encodedMatchesMetaModule(metaB),
    });
  });

  test('can handle cycles', () async {
    var moduleA = Module(assetA, [assetA], [assetB], platform, true);
    var moduleB = Module(assetB, [assetB], [assetA], platform, true);

    var metaA = MetaModule([moduleA]);
    var metaB = MetaModule([moduleB]);
    var clean = MetaModule([
      Module(assetA, [assetA, assetB], [], platform, true)
    ]);

    await testBuilder(MetaModuleCleanBuilder(platform), {
      'a|lib/${metaModuleExtension(platform)}': json.encode(metaA),
      'b|lib/${metaModuleExtension(platform)}': json.encode(metaB),
      'a|lib/a.dart': 'import "package:b/b.dart"',
      'b|lib/b.dart': 'import "package:a/a.dart"',
    }, outputs: {
      'a|lib/${metaModuleCleanExtension(platform)}':
          encodedMatchesMetaModule(clean),
      'b|lib/${metaModuleCleanExtension(platform)}':
          encodedMatchesMetaModule(MetaModule([])),
    });
  });

  test('Warns about missing .meta_module.raw files from dependencies',
      () async {
    var moduleA = Module(assetA, [assetA], [assetB], platform, true);
    var metaA = MetaModule([moduleA]);
    var logs = <LogRecord>[];
    await testBuilder(MetaModuleCleanBuilder(platform), {
      'a|lib/${metaModuleExtension(platform)}': json.encode(metaA),
      'a|lib/a.dart': 'import "package:b/b.dart"',
    }, outputs: {
      'a|lib/${metaModuleCleanExtension(platform)}':
          encodedMatchesMetaModule(metaA),
    }, onLog: (r) {
      if (r.level >= Level.WARNING) logs.add(r);
    });
    expect(
        logs,
        orderedEquals([
          predicate((LogRecord r) => r.message
              .startsWith('Unable to read module information for package:b'))
        ]));
  });
}
