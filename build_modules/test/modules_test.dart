// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_modules/src/errors.dart';
import 'package:build_modules/src/modules.dart';
import 'package:build_modules/src/module_builder.dart';

String serializeModule(Module module) => jsonEncode(module.toJson());

void main() {
  group('computeTransitiveDeps', () {
    final rootId = AssetId('a', 'lib/a.dart');
    final directDepId = AssetId('a', 'lib/src/dep.dart');
    final transitiveDepId = AssetId('b', 'lib/b.dart');
    final deepTransitiveDepId = AssetId('b', 'lib/src/dep.dart');
    final rootModule = Module(rootId, [rootId], [directDepId]);
    final directDepModule =
        Module(directDepId, [directDepId], [transitiveDepId]);
    final transitiveDepModule =
        Module(transitiveDepId, [transitiveDepId], [deepTransitiveDepId]);
    final deepTransitiveDepModule =
        Module(deepTransitiveDepId, [deepTransitiveDepId], []);
    InMemoryAssetReader reader;

    setUp(() {
      reader = InMemoryAssetReader();
      reader.cacheStringAsset(
          rootId.changeExtension(moduleExtension), serializeModule(rootModule));
      reader.cacheStringAsset(directDepId.changeExtension(moduleExtension),
          serializeModule(directDepModule));
      reader.cacheStringAsset(transitiveDepId.changeExtension(moduleExtension),
          serializeModule(transitiveDepModule));
      reader.cacheStringAsset(
          deepTransitiveDepId.changeExtension(moduleExtension),
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
      reader.assets
          .remove(deepTransitiveDepId.changeExtension(moduleExtension));
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
