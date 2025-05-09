// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:math';

import 'package:build/src/asset/id.dart';
import 'package:build/src/library_cycle_graph/asset_deps.dart';
import 'package:build/src/library_cycle_graph/asset_deps_loader.dart';
import 'package:build/src/library_cycle_graph/library_cycle.dart';
import 'package:build/src/library_cycle_graph/library_cycle_graph.dart';
import 'package:build/src/library_cycle_graph/library_cycle_graph_loader.dart';
import 'package:build/src/library_cycle_graph/phased_value.dart';
import 'package:test/test.dart';

void main() {
  final a1 = AssetId('a', '1');
  final a2 = AssetId('a', '2');
  final a3 = AssetId('a', '3');
  final a4 = AssetId('a', '4');
  final a5 = AssetId('a', '5');
  final a6 = AssetId('a', '6');
  final a7 = AssetId('a', '7');
  final a8 = AssetId('a', '8');
  final a9 = AssetId('a', '9');

  group('LibraryCycleGraphLoader', () {
    group('no generated nodes', () {
      test('single missing node', () async {
        final nodeLoader = TestAssetDepsLoader(0, {
          a1: PhasedValue.fixed(AssetDeps.empty),
        });
        final loader = LibraryCycleGraphLoader();
        expect(await loader.transitiveDepsOf(nodeLoader, a1), {a1});
      });

      test('single present node', () async {
        final nodeLoader = TestAssetDepsLoader(0, {
          a1: PhasedValue.fixed(AssetDeps({})),
        });
        final loader = LibraryCycleGraphLoader();
        expect(await loader.transitiveDepsOf(nodeLoader, a1), {a1});
      });

      test('node with one dep', () async {
        final nodeLoader = TestAssetDepsLoader(0, {
          a1: PhasedValue.fixed(AssetDeps({a2})),
          a2: PhasedValue.fixed(AssetDeps({})),
        });
        final loader = LibraryCycleGraphLoader();
        expect(await loader.transitiveDepsOf(nodeLoader, a1), {a1, a2});
      });

      test('seven node tree', () async {
        final nodeLoader = TestAssetDepsLoader(0, {
          a1: PhasedValue.fixed(AssetDeps({a2, a3})),
          a2: PhasedValue.fixed(AssetDeps({a4, a5})),
          a3: PhasedValue.fixed(AssetDeps({a6, a7})),
          a4: PhasedValue.fixed(AssetDeps({})),
          a5: PhasedValue.fixed(AssetDeps({})),
          a6: PhasedValue.fixed(AssetDeps({})),
          a7: PhasedValue.fixed(AssetDeps({})),
        });
        final loader = LibraryCycleGraphLoader();
        expect(await loader.transitiveDepsOf(nodeLoader, a1), {
          a1,
          a2,
          a3,
          a4,
          a5,
          a6,
          a7,
        });
      });

      test('four node diamond', () async {
        final nodeLoader = TestAssetDepsLoader(0, {
          a1: PhasedValue.fixed(AssetDeps({a2, a3})),
          a2: PhasedValue.fixed(AssetDeps({a4})),
          a3: PhasedValue.fixed(AssetDeps({a4})),
          a4: PhasedValue.fixed(AssetDeps({})),
        });
        final loader = LibraryCycleGraphLoader();
        expect(await loader.transitiveDepsOf(nodeLoader, a1), {a1, a2, a3, a4});
      });

      test('two node cycle', () async {
        final nodeLoader = TestAssetDepsLoader(0, {
          a1: PhasedValue.fixed(AssetDeps({a2})),
          a2: PhasedValue.fixed(AssetDeps({a1})),
        });
        final loader = LibraryCycleGraphLoader();
        expect(await loader.transitiveDepsOf(nodeLoader, a1), {a1, a2});

        expect(
          (await loader.libraryCycleOf(nodeLoader, a1)).valueAt(phase: 0).ids,
          {a1, a2},
        );
      });

      test('two node cycle excluding entrypoint', () async {
        final nodeLoader = TestAssetDepsLoader(0, {
          a1: PhasedValue.fixed(AssetDeps({a2})),
          a2: PhasedValue.fixed(AssetDeps({a3})),
          a3: PhasedValue.fixed(AssetDeps({a2})),
        });
        final loader = LibraryCycleGraphLoader();
        expect(await loader.transitiveDepsOf(nodeLoader, a1), {a1, a2, a3});

        expect(
          (await loader.libraryCycleOf(nodeLoader, a1)).valueAt(phase: 0).ids,
          {a1},
        );
        expect(
          (await loader.libraryCycleOf(nodeLoader, a2)).valueAt(phase: 0).ids,
          {a2, a3},
        );
      });
    });

    test('phased cycle uses same instance', () async {
      final nodeLoader = TestAssetDepsLoader(0, {
        a1: PhasedValue.fixed(AssetDeps({a2})),
        a2: PhasedValue.fixed(AssetDeps({a3})),
        a3: PhasedValue.fixed(AssetDeps({a2})),
      });
      final loader = LibraryCycleGraphLoader();
      expect(await loader.transitiveDepsOf(nodeLoader, a1), {a1, a2, a3});

      expect(
        await loader.libraryCycleOf(nodeLoader, a2),
        same(await loader.libraryCycleOf(nodeLoader, a3)),
      );
    });

    test('phased graph uses same instance', () async {
      final nodeLoader = TestAssetDepsLoader(0, {
        a1: PhasedValue.fixed(AssetDeps({a2})),
        a2: PhasedValue.fixed(AssetDeps({a3})),
        a3: PhasedValue.fixed(AssetDeps({a2})),
      });
      final loader = LibraryCycleGraphLoader();
      expect(await loader.transitiveDepsOf(nodeLoader, a1), {a1, a2, a3});

      expect(
        await loader.libraryCycleGraphOf(nodeLoader, a2),
        same(await loader.libraryCycleGraphOf(nodeLoader, a3)),
      );
    });
  });

  group('with generated nodes', () {
    test('single generated node', () async {
      final nodeLoader0 = TestAssetDepsLoader(0, {
        a1: PhasedValue.unavailable(expiresAfter: 1, before: AssetDeps.empty),
      });
      final nodeLoader2 = TestAssetDepsLoader(2, {
        a1: PhasedValue.generated(
          atPhase: 1,
          before: AssetDeps.empty,
          AssetDeps({}),
        ),
      });
      final loader = LibraryCycleGraphLoader();

      // Load before it's generated; the not-yet-available node is still a dep.
      // But the results show that they are incomplete.
      expect(await loader.transitiveDepsOf(nodeLoader0, a1), {a1});
      expect((await loader.libraryCycleOf(nodeLoader0, a1)).expiresAfter, 1);
      expect(
        (await loader.libraryCycleGraphOf(nodeLoader0, a1)).expiresAfter,
        1,
      );

      // Same result, but now marked as complete.
      expect(await loader.transitiveDepsOf(nodeLoader2, a1), {a1});
      expect(
        (await loader.libraryCycleOf(nodeLoader0, a1)).expiresAfter,
        isNull,
      );
      expect(
        (await loader.libraryCycleGraphOf(nodeLoader0, a1)).expiresAfter,
        isNull,
      );
    });

    group('sequence of three nodes', () {
      final nodeLoader = TestAssetDepsLoader(4, {
        a1: PhasedValue.generated(
          atPhase: 1,
          before: AssetDeps.empty,
          AssetDeps({a2}),
        ),
        a2: PhasedValue.generated(
          atPhase: 2,
          before: AssetDeps.empty,
          AssetDeps({a3}),
        ),
        a3: PhasedValue.generated(
          atPhase: 3,
          before: AssetDeps.empty,
          AssetDeps({}),
        ),
      });

      test('loaded in the order they appear', () async {
        final loader = LibraryCycleGraphLoader();

        expect(await loader.transitiveDepsOf(nodeLoader.at(phase: 1), a1), {
          a1,
        });
        expect(await loader.transitiveDepsOf(nodeLoader.at(phase: 2), a1), {
          a1,
          a2,
        });
        expect(await loader.transitiveDepsOf(nodeLoader.at(phase: 3), a1), {
          a1,
          a2,
          a3,
        });
        expect(await loader.transitiveDepsOf(nodeLoader.at(phase: 4), a1), {
          a1,
          a2,
          a3,
        });
      });

      test('loaded in reverse order', () async {
        final loader = LibraryCycleGraphLoader();

        expect(await loader.transitiveDepsOf(nodeLoader.at(phase: 4), a1), {
          a1,
          a2,
          a3,
        });
        expect(await loader.transitiveDepsOf(nodeLoader.at(phase: 3), a1), {
          a1,
          a2,
          a3,
        });
        expect(await loader.transitiveDepsOf(nodeLoader.at(phase: 2), a1), {
          a1,
          a2,
        });
        expect(await loader.transitiveDepsOf(nodeLoader.at(phase: 1), a1), {
          a1,
        });
      });

      test('loaded in reverse order with recursive load', () async {
        final loader = LibraryCycleGraphLoader();
        final recursiveLoader = nodeLoader.withRecursiveLoads(loader, {
          a3: [a2],
        });

        expect(
          await loader.transitiveDepsOf(recursiveLoader.at(phase: 4), a1),
          {a1, a2, a3},
        );
        expect(
          await loader.transitiveDepsOf(recursiveLoader.at(phase: 3), a1),
          {a1, a2, a3},
        );
        expect(
          await loader.transitiveDepsOf(recursiveLoader.at(phase: 2), a1),
          {a1, a2},
        );
        expect(
          await loader.transitiveDepsOf(recursiveLoader.at(phase: 1), a1),
          {a1},
        );
      });
    });

    group('graph of nine nodes', () {
      // A graph with 9 nodes generated in phases 1-5.
      //
      // a1 and a2 are generated in phase 1, then a3-a5 in phase 2, a6-7 in
      // phase 3, a8 in phase 4 and a9 in phase 5; in the ASCII art diagram,
      // nodes on the same vertical line are generated in the same phase.
      //
      // Notes:
      //
      //   - a node is readable the phase _after_ it's generated
      //   - a node can be depended on _before_ it's generated or readable
      //   - node a3 has a self edge not shown in the ASCII art diagram.
      //
      // ```
      //          ------------------\
      //         /                   \
      //        v      v---------\    \
      //       a1 --> a3 -------> a6   |
      //               |               |
      //                \-------> a7   |
      //                          |    |
      //       a2 --> a4 <-------/     |
      //      / ^      |               |
      //      | |      v               |
      //      | \---- a5               |
      //      |                        |
      //       \---------------------> a8 <--- a9
      // ```

      final nodeLoader = TestAssetDepsLoader(6, {
        a1: PhasedValue.generated(
          atPhase: 1,
          before: AssetDeps.empty,
          AssetDeps({a3}),
        ),
        a2: PhasedValue.generated(
          atPhase: 1,
          before: AssetDeps.empty,
          AssetDeps({a4, a8}),
        ),
        a3: PhasedValue.generated(
          atPhase: 2,
          before: AssetDeps.empty,
          AssetDeps({a3, a6, a7}),
        ),
        a4: PhasedValue.generated(
          atPhase: 2,
          before: AssetDeps.empty,
          AssetDeps({a5}),
        ),
        a5: PhasedValue.generated(
          atPhase: 2,
          before: AssetDeps.empty,
          AssetDeps({a2}),
        ),
        a6: PhasedValue.generated(
          atPhase: 3,
          before: AssetDeps.empty,
          AssetDeps({a3}),
        ),
        a7: PhasedValue.generated(
          atPhase: 3,
          before: AssetDeps.empty,
          AssetDeps({a4}),
        ),
        a8: PhasedValue.generated(
          atPhase: 4,
          before: AssetDeps.empty,
          AssetDeps({a1}),
        ),
        a9: PhasedValue.generated(
          atPhase: 5,
          before: AssetDeps.empty,
          AssetDeps({a8}),
        ),
      });

      // Test expectations as data so they can be checked in
      // different orders, exercising the "lazy" nature of the loader.
      // The transitive deps expected from each node at each phase.
      final expectations = [
        Expect(phase: 1, from: a1, deps: {a1}),
        Expect(phase: 1, from: a2, deps: {a2}),
        Expect(phase: 1, from: a3, deps: {a3}),
        Expect(phase: 1, from: a4, deps: {a4}),
        Expect(phase: 1, from: a5, deps: {a5}),
        Expect(phase: 1, from: a6, deps: {a6}),
        Expect(phase: 1, from: a7, deps: {a7}),
        Expect(phase: 1, from: a8, deps: {a8}),
        Expect(phase: 1, from: a9, deps: {a9}),
        Expect(phase: 2, from: a1, deps: {a1, a3}),
        Expect(phase: 2, from: a2, deps: {a2, a4, a8}),
        Expect(phase: 2, from: a3, deps: {a3}),
        Expect(phase: 2, from: a4, deps: {a4}),
        Expect(phase: 2, from: a5, deps: {a5}),
        Expect(phase: 2, from: a6, deps: {a6}),
        Expect(phase: 2, from: a7, deps: {a7}),
        Expect(phase: 2, from: a8, deps: {a8}),
        Expect(phase: 2, from: a9, deps: {a9}),
        Expect(phase: 3, from: a1, deps: {a1, a3, a6, a7}),
        Expect(phase: 3, from: a2, deps: {a2, a4, a5, a8}),
        Expect(phase: 3, from: a3, deps: {a3, a6, a7}),
        Expect(phase: 3, from: a4, deps: {a2, a4, a5, a8}),
        Expect(phase: 3, from: a5, deps: {a2, a4, a5, a8}),
        Expect(phase: 3, from: a6, deps: {a6}),
        Expect(phase: 3, from: a7, deps: {a7}),
        Expect(phase: 3, from: a8, deps: {a8}),
        Expect(phase: 3, from: a9, deps: {a9}),
        Expect(phase: 4, from: a1, deps: {a1, a2, a3, a4, a5, a6, a7, a8}),
        Expect(phase: 4, from: a2, deps: {a2, a4, a8, a5}),
        Expect(phase: 4, from: a3, deps: {a2, a3, a4, a5, a6, a7, a8}),
        Expect(phase: 4, from: a4, deps: {a2, a4, a5, a8}),
        Expect(phase: 4, from: a5, deps: {a2, a4, a5, a8}),
        Expect(phase: 4, from: a6, deps: {a2, a3, a4, a5, a6, a7, a8}),
        Expect(phase: 4, from: a7, deps: {a2, a4, a5, a7, a8}),
        Expect(phase: 4, from: a8, deps: {a8}),
        Expect(phase: 4, from: a9, deps: {a9}),
        Expect(phase: 5, from: a1, deps: {a1, a2, a3, a4, a5, a6, a7, a8}),
        Expect(phase: 5, from: a2, deps: {a1, a2, a3, a4, a5, a6, a7, a8}),
        Expect(phase: 5, from: a3, deps: {a1, a2, a3, a4, a5, a6, a7, a8}),
        Expect(phase: 5, from: a4, deps: {a1, a2, a3, a4, a5, a6, a7, a8}),
        Expect(phase: 5, from: a5, deps: {a1, a2, a3, a4, a5, a6, a7, a8}),
        Expect(phase: 5, from: a6, deps: {a1, a2, a3, a4, a5, a6, a7, a8}),
        Expect(phase: 5, from: a7, deps: {a1, a2, a3, a4, a5, a6, a7, a8}),
        Expect(phase: 5, from: a8, deps: {a1, a2, a3, a4, a5, a6, a7, a8}),
        Expect(phase: 5, from: a9, deps: {a9}),
        Expect(phase: 6, from: a1, deps: {a1, a2, a3, a4, a5, a6, a7, a8}),
        Expect(phase: 6, from: a2, deps: {a1, a2, a3, a4, a5, a6, a7, a8}),
        Expect(phase: 6, from: a3, deps: {a1, a2, a3, a4, a5, a6, a7, a8}),
        Expect(phase: 6, from: a4, deps: {a1, a2, a3, a4, a5, a6, a7, a8}),
        Expect(phase: 6, from: a5, deps: {a1, a2, a3, a4, a5, a6, a7, a8}),
        Expect(phase: 6, from: a6, deps: {a1, a2, a3, a4, a5, a6, a7, a8}),
        Expect(phase: 6, from: a7, deps: {a1, a2, a3, a4, a5, a6, a7, a8}),
        Expect(phase: 6, from: a8, deps: {a1, a2, a3, a4, a5, a6, a7, a8}),
        Expect(phase: 6, from: a9, deps: {a1, a2, a3, a4, a5, a6, a7, a8, a9}),
      ];

      /// Checks that loaded cycles and graphs that are equal are also
      /// identical.
      ///
      /// This is important for efficiency so that later processing, such as
      /// serialization, can deduplicate work by identity.
      Future<void> expectEqualValuesAreIdentical(
        LibraryCycleGraphLoader loader,
      ) async {
        final allCycles = Set<LibraryCycle>.identity();
        final allGraphs = Set<LibraryCycleGraph>.identity();
        for (final id in [a1, a2, a3, a4, a5, a6, a7, a8, a9]) {
          final phasedCycle = await loader.libraryCycleOf(nodeLoader, id);
          final phasedGraph = await loader.libraryCycleGraphOf(nodeLoader, id);
          for (final phase in [1, 2, 3, 4, 5, 6]) {
            allCycles.add(phasedCycle.valueAt(phase: phase));
            final graph = phasedGraph.valueAt(phase: phase);
            allGraphs.add(graph);
          }
        }

        expect(allCycles.length, Set.of(allCycles).length);
        expect(allGraphs.length, Set.of(allGraphs).length);
      }

      test('loaded in order', () async {
        final loader = LibraryCycleGraphLoader();
        for (final expectation in expectations) {
          printOnFailure(expectation.toString());
          await expectation.run(loader, nodeLoader);
        }
        await expectEqualValuesAreIdentical(loader);
      });

      test('loaded in reverse order', () async {
        final loader = LibraryCycleGraphLoader();
        for (final expectation in expectations.reversed) {
          printOnFailure(expectation.toString());
          await expectation.run(loader, nodeLoader);
        }
        await expectEqualValuesAreIdentical(loader);
      });

      test('loaded in reverse order with recursive loads', () async {
        final loader = LibraryCycleGraphLoader();
        final recursiveLoader = nodeLoader.withRecursiveLoads(loader, {
          a4: [a1],
          a6: [a2],
          a9: [a5],
        });
        for (final expectation in expectations.reversed) {
          printOnFailure(expectation.toString());
          await expectation.run(loader, recursiveLoader);
        }
        await expectEqualValuesAreIdentical(loader);
      });

      // 50 randomized runs was enough to find all known issues multiple times;
      // 100000 runs, which only takes 100s, didn't find any further issues.
      for (var seed = 0; seed != 50; ++seed) {
        test('loaded in random order (seed $seed)', () async {
          final random = Random(seed);
          final loader = LibraryCycleGraphLoader();
          for (final expectation in expectations.toList()..shuffle(random)) {
            printOnFailure(expectation.toString());
            await expectation.run(loader, nodeLoader);
          }
          await expectEqualValuesAreIdentical(loader);
        });
      }

      for (var seed = 0; seed != 50; ++seed) {
        test(
          'loaded in random order with recursive loads (seed $seed)',
          () async {
            // Use a second `Random` so the load order matches the above tests.
            final randomForLoads = Random(seed);

            List<AssetId> randomLoads() {
              return ([a1, a2, a3, a4, a5, a6, a7, a8, a9]..shuffle(
                randomForLoads,
              )).take(randomForLoads.nextInt(3)).toList();
            }

            final loader = LibraryCycleGraphLoader();
            final recursiveLoader = nodeLoader.withRecursiveLoads(loader, {
              a1: randomLoads(),
              a2: randomLoads(),
              a3: randomLoads(),
              a4: randomLoads(),
              a5: randomLoads(),
              a6: randomLoads(),
              a7: randomLoads(),
              a8: randomLoads(),
              a9: randomLoads(),
            });

            final random = Random(seed);
            for (final expectation in expectations.toList()..shuffle(random)) {
              printOnFailure(expectation.toString());
              await expectation.run(loader, recursiveLoader);
            }
            await expectEqualValuesAreIdentical(loader);
          },
        );
      }
    });
  });
}

/// An [AssetDepsLoader] with data passed in from test setup.
class TestAssetDepsLoader implements AssetDepsLoader {
  @override
  final int phase;
  final Map<AssetId, PhasedValue<AssetDeps>> results;

  // Support for triggering recursive loads.

  /// Loader to do recursive loads.
  final LibraryCycleGraphLoader? loader;

  /// Test data: map from asset ID to recursive loads to trigger while
  /// loading that ID.
  final Map<AssetId, List<AssetId>>? triggeredBuilds;

  /// Assets that "have been built". A recursive load is only triggered
  /// once, as in a real build it would only happen at most once when the
  /// asset gets built.
  final Set<AssetId>? built;

  TestAssetDepsLoader(
    this.phase,
    this.results, [
    this.loader,
    this.triggeredBuilds,
    this.built,
  ]);

  @override
  Future<PhasedValue<AssetDeps>> load(AssetId id) async {
    final result = results[id]!;

    // Check test setup for recursive loads that should be triggered by this
    // load.
    if (triggeredBuilds != null) {
      for (final triggeredBuild in triggeredBuilds![id] ?? const <AssetId>[]) {
        if (built!.add(triggeredBuild)) {
          final triggeredBuildPhase =
              results[triggeredBuild]!.values.first.expiresAfter!;
          // It's only allowed to trigger loads at earlier phases than the
          // currently-running phase. `LibraryCycleGraphLoader` checks and
          // enforces this condition. In a real build, it happens this way
          // because reads of an asset generated at the current or a later phase
          // return nothing instead of triggering a build.
          if (triggeredBuildPhase >= phase) {
            continue;
          }
          await loader!.transitiveDepsOf(
            at(phase: triggeredBuildPhase),
            triggeredBuild,
          );
        }
      }
    }
    return result;
  }

  /// Returns a [TestAssetDepsLoader] at [phase] with the same values as this,
  /// but excluding any values not yet available at [phase].
  TestAssetDepsLoader at({required int phase}) {
    if (phase > this.phase) {
      throw ArgumentError(
        "Can't make a phase $phase TestAssetDepsLoader from "
        'a phase ${this.phase} loader.',
      );
    }
    return TestAssetDepsLoader(
      phase,
      results.map((id, value) {
        return MapEntry(
          id,
          PhasedValue<AssetDeps>((b) {
            for (final expiringValue in value.values) {
              b.values.add(expiringValue);
              if (expiringValue.expiresAfter != null &&
                  expiringValue.expiresAfter! > phase) {
                return;
              }
            }
          }),
        );
      }),
      loader,
      triggeredBuilds,
      built,
    );
  }

  /// Returns a [TestAssetDepsLoader] with the same values as this, plus
  /// set up to trigger recursive loads using [loader] according
  /// [triggeredBuilds].
  ///
  /// For example, `triggeredBuilds[a1] = [a2]` to cause a load of `a1` to
  /// trigger a recursive load of `a2`.
  TestAssetDepsLoader withRecursiveLoads(
    LibraryCycleGraphLoader loader,
    Map<AssetId, List<AssetId>> triggeredBuilds,
  ) => TestAssetDepsLoader(phase, results, loader, triggeredBuilds, {});
}

/// An expectation about [LibraryCycleGraphLoader#transitiveDepsOf].
class Expect {
  /// The phase the deps are evaluated in.
  final int phase;

  /// The asset that is the starting point for `transitiveDepsOf`.
  final AssetId from;

  /// The expected transitive deps.
  final Iterable<AssetId> deps;

  Expect({required this.phase, required this.from, required this.deps});

  Future<void> run(
    LibraryCycleGraphLoader loader,
    TestAssetDepsLoader nodeLoader,
  ) async {
    expect(
      await loader.transitiveDepsOf(nodeLoader.at(phase: phase), from),
      deps,
      reason: toString(),
    );
  }

  @override
  String toString() => 'Transitive deps of $from at phase $phase.';
}
