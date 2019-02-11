// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_modules/build_modules.dart';

String serializeModule(Module module) => jsonEncode(module.toJson());

void main() {
  final platform = DartPlatform.dart2js;

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
    InMemoryAssetReader reader;

    setUp(() {
      reader = InMemoryAssetReader()
        ..cacheStringAsset(rootId.changeExtension(moduleExtension(platform)),
            serializeModule(rootModule))
        ..cacheStringAsset(
            directDepId.changeExtension(moduleExtension(platform)),
            serializeModule(directDepModule))
        ..cacheStringAsset(
            transitiveDepId.changeExtension(moduleExtension(platform)),
            serializeModule(transitiveDepModule))
        ..cacheStringAsset(
            deepTransitiveDepId.changeExtension(moduleExtension(platform)),
            serializeModule(deepTransitiveDepModule));
    });

    test('finds transitive deps', () async {
      var transitiveDeps =
          (await rootModule.computeTransitiveDependencies(reader))
              .map((m) => m.primarySource)
              .toList();
      expect(
          transitiveDeps,
          unorderedEquals([
            directDepModule.primarySource,
            transitiveDepModule.primarySource,
            deepTransitiveDepModule.primarySource,
          ]));
      expect(transitiveDeps.indexOf(transitiveDepModule.primarySource),
          lessThan(transitiveDeps.indexOf(directDepModule.primarySource)));
      expect(transitiveDeps.indexOf(deepTransitiveDepModule.primarySource),
          lessThan(transitiveDeps.indexOf(transitiveDepModule.primarySource)));
    });

    test('missing modules report nice errors', () {
      reader.assets.remove(
          deepTransitiveDepId.changeExtension(moduleExtension(platform)));
      reader.cacheStringAsset(transitiveDepId, '''
import 'src/dep.dart';
''');
      expect(
          () => rootModule.computeTransitiveDependencies(reader),
          allOf(throwsA(TypeMatcher<MissingModulesException>()), throwsA(
            predicate<MissingModulesException>(
              (error) {
                printOnFailure(error.message);
                return error.message.contains('''
Unable to find modules for some sources, this is usually the result of either a
bad import, a missing dependency in a package (or possibly a dev_dependency
needs to move to a real dependency), or a build failure (if importing a
generated file).

Please check the following imports:

`import 'src/dep.dart';` from b|lib/b.dart at 1:1
''');
              },
            ),
          )));
    });
  });
}
