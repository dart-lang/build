// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_modules/build_modules.dart';

void main() {
  final platform = DartPlatform.register('test', ['html']);

  group('computeTransitiveDeps', () {
    final rootId = AssetId('a', 'lib/a.dart');
    final directDepId = AssetId('a', 'lib/src/dep.dart');
    final transitiveDepId = AssetId('b', 'lib/b.dart');
    final deepTransitiveDepId = AssetId('b', 'lib/src/dep.dart');
    final rootModule = Module(rootId, [rootId], [directDepId], platform, true);
    final directDepModule =
        Module(directDepId, [directDepId], [transitiveDepId], platform, true);
    final transitiveDepModule = Module(transitiveDepId, [transitiveDepId],
        [deepTransitiveDepId], platform, true);
    final deepTransitiveDepModule =
        Module(deepTransitiveDepId, [deepTransitiveDepId], [], platform, true);

    test('finds transitive deps', () async {
      await testBuilder(
          TestBuilder(
              buildExtensions: {
                'lib/a${moduleExtension(platform)}': ['.transitive']
              },
              build: expectAsync2((buildStep, _) async {
                var transitiveDeps =
                    (await rootModule.computeTransitiveDependencies(buildStep))
                        .map((m) => m.primarySource)
                        .toList();
                expect(
                    transitiveDeps,
                    unorderedEquals([
                      directDepModule.primarySource,
                      transitiveDepModule.primarySource,
                      deepTransitiveDepModule.primarySource,
                    ]));
                expect(
                    transitiveDeps.indexOf(transitiveDepModule.primarySource),
                    lessThan(
                        transitiveDeps.indexOf(directDepModule.primarySource)));
                expect(
                    transitiveDeps
                        .indexOf(deepTransitiveDepModule.primarySource),
                    lessThan(transitiveDeps
                        .indexOf(transitiveDepModule.primarySource)));
              })),
          {
            'a|lib/a${moduleExtension(platform)}':
                jsonEncode(rootModule.toJson()),
            'a|lib/src/dep${moduleExtension(platform)}':
                jsonEncode(directDepModule.toJson()),
            'b|lib/b${moduleExtension(platform)}':
                jsonEncode(transitiveDepModule.toJson()),
            'b|lib/src/dep${moduleExtension(platform)}':
                jsonEncode(deepTransitiveDepModule.toJson()),
          });
    });

    test('missing modules report nice errors', () async {
      await testBuilder(
          TestBuilder(
              buildExtensions: {
                'lib/a${moduleExtension(platform)}': ['.transitive']
              },
              build: expectAsync2((buildStep, _) async {
                await expectLater(
                    () => rootModule.computeTransitiveDependencies(buildStep),
                    throwsA(isA<MissingModulesException>()
                        .having((e) => e.message, 'message', contains('''
Unable to find modules for some sources, this is usually the result of either a
bad import, a missing dependency in a package (or possibly a dev_dependency
needs to move to a real dependency), or a build failure (if importing a
generated file).

Please check the following imports:

`import 'src/dep.dart';` from b|lib/b.dart at 1:1
'''))));
              })),
          {
            'a|lib/a${moduleExtension(platform)}':
                jsonEncode(rootModule.toJson()),
            'a|lib/src/dep${moduleExtension(platform)}':
                jsonEncode(directDepModule.toJson()),
            'b|lib/b${moduleExtension(platform)}':
                jsonEncode(transitiveDepModule.toJson()),
            // No module for b|lib/src/dep.dart
            'b|lib/b.dart': 'import \'src/dep.dart\';',
          });
    });
  });
}
