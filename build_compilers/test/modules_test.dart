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

  group('defineModule.cycle', () {
    test('Finds the assets in a cycle', () async {
      var cycle = defineModule(assetCycle, libCycle).cycle;
      expect(cycle, unorderedEquals([assetCycle, assetSecondaryInCycle]));
    });

    test('Finds a single asset with no cycle', () async {
      var cycle = defineModule(assetNoCycle, libNoCycle).cycle;
      expect(cycle, unorderedEquals([assetNoCycle]));
    });

    test('Finds the assets in a cycle across packages', () async {
      var cycle = defineModule(assetCycleWithB, libCycleWithB).cycle;
      expect(cycle, unorderedEquals([assetCycleWithA, assetCycleWithB]));
    });
  });

  group('defineModule.dependencies', () {
    test('Chooses primary from cycle for dependency', () async {
      var dependencies = defineModule(assetCycle, libCycle).dependencies;
      expect(dependencies, unorderedEquals([assetCycleWithB]));
    });
  });

  group('isPrimary', () {
    test('Marks library with no cycle as primary', () async {
      expect(isPrimary(libNoCycle), true);
    });

    test('Marks library with lowest alpha sort as primary', () async {
      expect(isPrimary(libCycle), true);
    });

    test('Does not mark library with higher alpha sort as primary', () async {
      expect(isPrimary(libSecondaryInCycle), false);
    });

    test('Marks library with lowest alpha sort across packages as primary',
        () async {
      expect(isPrimary(libCycleWithB), true);
    });
    test(
        'Does not mark library with higher alpha sort across packages as primary',
        () async {
      expect(isPrimary(libCycleWithA), false);
    });
  });
}
