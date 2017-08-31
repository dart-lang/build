// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_compilers/src/modules.dart';

void main() {
  LibraryElement libCycle;
  LibraryElement libSecondaryInCycle;
  LibraryElement libNoCycle;
  LibraryElement libCycleWithB;
  LibraryElement libCycleWithA;
  final assetCycle = makeAssetId('a|lib/a_cycle.dart');
  final assetSecondaryInCycle = makeAssetId('a|lib/a_secondary_in_cycle.dart');
  final assetNoCycle = makeAssetId('a|lib/a_no_cycle.dart');
  final assetCycleWithB = makeAssetId('a|lib/a_cycle_with_b.dart');
  final assetCycleWithA = makeAssetId('b|lib/b_cycle_with_a.dart');

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
  });

  group('defineModule.sources', () {
    test('Finds the assets in a cycle', () {
      var sources = defineModule(assetCycle, libCycle).sources;
      expect(sources, unorderedEquals([assetCycle, assetSecondaryInCycle]));
    });

    test('Finds a single asset with no cycle', () {
      var sources = defineModule(assetNoCycle, libNoCycle).sources;
      expect(sources, unorderedEquals([assetNoCycle]));
    });

    test('Finds the assets in a cycle across packages', () {
      var sources = defineModule(assetCycleWithB, libCycleWithB).sources;
      expect(sources, unorderedEquals([assetCycleWithA, assetCycleWithB]));
    });
  });

  group('defineModule.directDependencies', () {
    test('Chooses primary from cycle for dependency', () {
      var dependencies = defineModule(assetCycle, libCycle).directDependencies;
      expect(dependencies, unorderedEquals([assetCycleWithB]));
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
}
