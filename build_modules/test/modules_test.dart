// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_modules/src/errors.dart';
import 'package:build_modules/src/modules.dart';
import 'package:build_modules/src/module_builder.dart';

void main() {
  LibraryElement libCycle;
  LibraryElement libSecondaryInCycle;
  LibraryElement libNoCycle;
  LibraryElement libCycleWithB;
  LibraryElement libCycleWithA;
  LibraryElement libDepOnNonSdk;
  LibraryElement libAImportsBNoCycle;
  LibraryElement libBImportsANoCycle;
  LibraryElement libBSecondImportsANoCycle;
  final assetCycle = makeAssetId('a|lib/a_cycle.dart');
  final assetSecondaryInCycle = makeAssetId('a|lib/a_secondary_in_cycle.dart');
  final assetPartInCycle = makeAssetId('a|lib/a_part_in_cycle.dart');
  final assetNoCycle = makeAssetId('a|lib/a_no_cycle.dart');
  final assetCycleWithB = makeAssetId('a|lib/a_cycle_with_b.dart');
  final assetCycleWithA = makeAssetId('b|lib/b_cycle_with_a.dart');
  final assetDepOnNonSdk = makeAssetId('a|lib/a_dep_on_non_sdk.dart');
  final assetNonSdk = makeAssetId('a|lib/a_non_sdk.dart');
  final assetAImportsBNoCycle = makeAssetId('a|lib/a_imports_b_no_cycle.dart');
  final assetAPartLibraryName = makeAssetId('a|lib/a_part_library_name.dart');
  final assetBImportsANoCycle = makeAssetId('b|lib/b_imports_a_no_cycle.dart');
  final assetBSecondImportsANoCycle =
      makeAssetId('b|lib/b_second_import_to_a_no_cycle.dart');

  setUpAll(() async {
    await resolveAsset(assetCycle, (resolver) async {
      libCycle = await resolver.libraryFor(assetCycle);
      libSecondaryInCycle = await resolver.libraryFor(assetSecondaryInCycle);
    });
    await resolveAsset(assetNoCycle, (resolver) async {
      libNoCycle = await resolver.libraryFor(assetNoCycle);
    });
    await resolveAsset(assetCycleWithB, (resolver) async {
      libCycleWithB = await resolver.libraryFor(assetCycleWithB);
      libCycleWithA = await resolver.libraryFor(assetCycleWithA);
    });
    await resolveAsset(assetDepOnNonSdk, (resolver) async {
      libDepOnNonSdk = await resolver.libraryFor(assetDepOnNonSdk);
    });
    await resolveAsset(assetAImportsBNoCycle, (resolver) async {
      libAImportsBNoCycle = await resolver.libraryFor(assetAImportsBNoCycle);
    });
    await resolveAsset(assetBImportsANoCycle, (resolver) async {
      libBImportsANoCycle = await resolver.libraryFor(assetBImportsANoCycle);
    });
    await resolveAsset(assetBSecondImportsANoCycle, (resolver) async {
      libBSecondImportsANoCycle =
          await resolver.libraryFor(assetBSecondImportsANoCycle);
    });
  });

  group('defineModule.sources', () {
    test('Finds the assets in a cycle', () {
      var sources = Module.forLibrary(libCycle).sources;
      expect(
          sources,
          unorderedEquals(
              [assetCycle, assetSecondaryInCycle, assetPartInCycle]));
    });

    test('Finds a single asset with no cycle', () {
      var sources = Module.forLibrary(libNoCycle).sources;
      expect(sources, unorderedEquals([assetNoCycle]));
    });

    test('Finds the assets in a cycle across packages', () {
      var sources = Module.forLibrary(libCycleWithB).sources;
      expect(sources, unorderedEquals([assetCycleWithA, assetCycleWithB]));
    });
  });

  group('defineModule.directDependencies', () {
    test('Chooses primary from cycle for dependency', () {
      var dependencies = Module.forLibrary(libCycle).directDependencies;
      expect(dependencies, unorderedEquals([assetCycleWithB]));
    });

    test('Includes libraries that have names starting with "dart."', () {
      // https://github.com/dart-lang/sdk/issues/31045
      // `library.isInSdk` is broken - we shouldn't use it
      var dependencies = Module.forLibrary(libDepOnNonSdk).directDependencies;
      expect(dependencies, unorderedEquals([assetNonSdk]));
    });
  });

  group('isPrimary', () {
    group('within package', () {
      test('Marks library with no cycle as primary', () {
        expect(isPrimary(libNoCycle), true);
      });

      test('Marks library with lowest alpha sort as primary', () {
        expect(isPrimary(libCycle), true);
      });

      test('Does not mark library with higher alpha sort as primary', () {
        expect(isPrimary(libSecondaryInCycle), false);
      });
    });
    group('across packages', () {
      test('Marks library with lowest alpha sort as primary', () {
        expect(isPrimary(libCycleWithB), true);
      });
      test('Does not mark library with later alpha sort as primary', () {
        expect(isPrimary(libCycleWithA), false);
      });
    });
  });

  group('computeTransitiveDeps', () {
    Module rootModule;
    Module immediateDep;
    Module immediateDep2;
    Module transitiveDep;
    InMemoryAssetReader reader;

    setUp(() {
      rootModule = Module.forLibrary(libAImportsBNoCycle);
      immediateDep = Module.forLibrary(libBImportsANoCycle);
      immediateDep2 = Module.forLibrary(libBSecondImportsANoCycle);
      transitiveDep = Module.forLibrary(libNoCycle);
      reader = InMemoryAssetReader();
      reader.cacheStringAsset(
          assetAImportsBNoCycle,
          File('test/fixtures/a/${assetAImportsBNoCycle.path}')
              .readAsStringSync());
      reader.cacheStringAsset(
          assetAPartLibraryName,
          File('test/fixtures/a/${assetAPartLibraryName.path}')
              .readAsStringSync());
      reader.cacheStringAsset(
          assetBImportsANoCycle,
          File('test/fixtures/b/${assetBImportsANoCycle.path}')
              .readAsStringSync());
      reader.cacheStringAsset(
          assetBSecondImportsANoCycle,
          File('test/fixtures/b/${assetBSecondImportsANoCycle.path}')
              .readAsStringSync());
      reader.cacheStringAsset(assetCycle,
          File('test/fixtures/a/${assetCycle.path}').readAsStringSync());
      reader.cacheStringAsset(
          assetSecondaryInCycle,
          File('test/fixtures/a/${assetSecondaryInCycle.path}')
              .readAsStringSync());
    });

    test('finds transitive deps', () async {
      reader.cacheStringAsset(
          assetBImportsANoCycle.changeExtension(moduleExtension),
          json.encode(immediateDep.toJson()));
      reader.cacheStringAsset(
          assetBSecondImportsANoCycle.changeExtension(moduleExtension),
          json.encode(immediateDep2.toJson()));
      reader.cacheStringAsset(assetNoCycle.changeExtension(moduleExtension),
          json.encode(transitiveDep.toJson()));

      var transitiveDeps =
          (await rootModule.computeTransitiveDependencies(reader))
              .map((m) => m.primarySource)
              .toList();
      expect(
          transitiveDeps,
          unorderedEquals([
            immediateDep.primarySource,
            immediateDep2.primarySource,
            transitiveDep.primarySource
          ]));
      expect(transitiveDeps.indexOf(transitiveDep.primarySource),
          lessThan(transitiveDeps.indexOf(immediateDep.primarySource)));
      expect(transitiveDeps.indexOf(transitiveDep.primarySource),
          lessThan(transitiveDeps.indexOf(immediateDep2.primarySource)));
    });

    test('missing modules report nice errors', () {
      reader.cacheStringAsset(assetCycle.changeExtension(moduleExtension),
          json.encode(immediateDep.toJson()));
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

`import 'package:b/b_second_import_to_a_no_cycle.dart';` from a|lib/a_imports_b_no_cycle.dart at 5:1
`import 'package:b/b_imports_a_no_cycle.dart';` from a|lib/a_imports_b_no_cycle.dart at 4:1
''');
              },
            ),
          )));
    });
  });
}
