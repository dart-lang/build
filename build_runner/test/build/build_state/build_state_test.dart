// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/src/build/build_state/build_state.dart';
import 'package:build_runner/src/build/build_state/build_step_id.dart';
import 'package:build_runner/src/build/build_state/build_step_result.dart';
import 'package:build_runner/src/build/build_state/exceptions.dart';
import 'package:build_runner/src/build_plan/build_phases.dart';
import 'package:build_runner/src/build_plan/build_step_plan.dart';
import 'package:build_runner/src/build_plan/phase.dart';

import 'package:test/test.dart';

import '../../common/common.dart';

void main() {
  group('BuildState', () {
    late BuildState buildState;
    late BuildStepPlan buildStepPlan;

    AssetId testAddSource(int number) {
      final id = AssetId.parse('pkg|lib/a$number.dart');
      expect(buildState.isSource(id), false);
      buildState.addSourceForTest(id);
      expect(buildState.isSource(id), true);
      return id;
    }

    group('simple build state', () {
      setUp(() async {
        buildState = BuildState.create(sources: <AssetId>{});
      });

      test('add, contains, get, allNodes', () {
        final expectedNodes = [for (var i = 0; i < 5; i++) testAddSource(i)];
        expect(buildState.sources, unorderedEquals(expectedNodes));
      });
    });

    group('build state with declared outputs', () {
      final targetSources = const InputSet(exclude: ['excluded.txt']);
      final buildPhases = BuildPhases(
        [
          InBuildPhase(
            builder: TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.txt'),
            ),
            key: 'TestBuilder',
            package: 'foo',
            targetSources: targetSources,
          ),
        ],
        PostBuildPhase([
          PostBuildAction(
            builder: CopyingPostProcessBuilder(outputExtension: '.post'),
            package: 'foo',
            targetSources: targetSources,
            options: const BuilderOptions({}),
            generateFor: const InputSet(),
            hideOutput: true,
          ),
        ]),
      );
      final primaryInputId = makeAssetId('foo|file.txt');
      final excludedInputId = makeAssetId('foo|excluded.txt');
      final primaryOutputId = makeAssetId('foo|file.txt.copy');
      final syntheticId = makeAssetId('foo|synthetic.txt');
      final syntheticOutputId = makeAssetId('foo|synthetic.txt.copy');

      setUp(() async {
        buildState = BuildState.create(
          sources: {primaryInputId, excludedInputId},
        );
        buildStepPlan = BuildStepPlan.compute(
          buildPhases: buildPhases,
          placeholderIds: [],
          sources: buildState.sources,
        );
      });



      test('build', () {
        expect(
          buildStepPlan.declaredOutputs,
          unorderedEquals([primaryOutputId]),
        );
        expect(
          buildState.sources,
          unorderedEquals([primaryInputId, excludedInputId]),
        );
        expect(buildStepPlan.declaredOutputsOf(primaryInputId), [
          primaryOutputId,
        ]);

        final buildStepId = BuildStepId(
          primaryInput: primaryInputId,
          phaseNumber: 0,
        );
        expect(buildState.stepResultOrNull(buildStepId), isNull);
        expect(
          buildStepPlan.stepForDeclaredOutput(primaryOutputId).primaryInput,
          primaryInputId,
        );
      });

      group('updateAndInvalidate', () {
        test('add new primary input', () async {
          final newSources = {...buildState.sources, AssetId('foo', 'new.txt')};
          final newBuildState = BuildState.create(sources: newSources);
          final newBuildStepPlan = BuildStepPlan.compute(
            buildPhases: buildPhases,
            placeholderIds: [],
            sources: newSources,
          );
          expect(
            newBuildState.isFile(
              buildStepPlan: newBuildStepPlan,
              id: AssetId('foo', 'new.txt.copy'),
            ),
            isTrue,
          );
        });

        test('modify primary input', () async {
          // Modifications don't change the static plan, so recreation with
          // same sources will yield same sources and outputs.
          final newBuildState = BuildState.create(
            sources: buildState.sources.toSet(),
          );
          expect(
            newBuildState.isFile(
              buildStepPlan: buildStepPlan,
              id: primaryInputId,
            ),
            isTrue,
          );
          expect(
            newBuildState.isFile(
              buildStepPlan: buildStepPlan,
              id: primaryOutputId,
            ),
            isTrue,
          );
        });

        test('add new primary input which replaces a synthetic node', () async {
          buildState.addMissingSource(syntheticId);
          expect(buildState.isMissingSource(syntheticId), isTrue);

          final newSources = {...buildState.sources, syntheticId};
          final newBuildState = BuildState.create(sources: newSources);
          final newBuildStepPlan = BuildStepPlan.compute(
            buildPhases: buildPhases,
            placeholderIds: [],
            sources: newSources,
          );
          expect(
            newBuildState.isFile(
              buildStepPlan: newBuildStepPlan,
              id: syntheticId,
            ),
            isTrue,
          );
          expect(newBuildState.isSource(syntheticId), isTrue);
          expect(
            newBuildState.isFile(
              buildStepPlan: newBuildStepPlan,
              id: syntheticOutputId,
            ),
            isTrue,
          );
          expect(newBuildStepPlan.isDeclaredOutput(syntheticOutputId), isTrue);
        });

        test(
          'add new generated asset which replaces a synthetic node',
          () async {
            buildState.addMissingSource(syntheticOutputId);
            expect(buildState.isMissingSource(syntheticOutputId), isTrue);

            final newSources = {...buildState.sources, syntheticId};
            final newBuildState = BuildState.create(sources: newSources);
            final newBuildStepPlan = BuildStepPlan.compute(
              buildPhases: buildPhases,
              placeholderIds: [],
              sources: newSources,
            );

            expect(
              newBuildState.isFile(
                buildStepPlan: newBuildStepPlan,
                id: syntheticOutputId,
              ),
              isTrue,
            );
            expect(newBuildStepPlan.isDeclaredOutput(syntheticOutputId), isTrue);
          },
        );

        test(
          'removing nodes deletes primary outputs and secondary edges',
          () async {
            final newSources =
                buildState.sources.toSet()..remove(primaryInputId);
            final newBuildState = BuildState.create(sources: newSources);
            final newBuildStepPlan = BuildStepPlan.compute(
              buildPhases: buildPhases,
              placeholderIds: [],
              sources: newSources,
            );
            expect(
              newBuildState.isFile(
                buildStepPlan: newBuildStepPlan,
                id: primaryInputId,
              ),
              isFalse,
            );
            expect(
              newBuildState.isFile(
                buildStepPlan: newBuildStepPlan,
                id: primaryOutputId,
              ),
              isFalse,
            );
          },
        );
      });

      test('overlapping build phases cause an error', () async {
        expect(
          () => BuildStepPlan.compute(
            buildPhases: BuildPhases(
              List.filled(
                2,
                InBuildPhase(
                  builder: TestBuilder(),
                  key: 'TestBuilder',
                  package: 'foo',
                ),
              ),
            ),
            placeholderIds: [],
            sources: {makeAssetId('foo|file')},
          ),
          throwsA(isA<DuplicateAssetIdException>()),
        );
      });

      group('regression tests', () {
        test('build can chains of pre-existing to-source outputs', () async {
          final buildPhases = BuildPhases([
            InBuildPhase(
              builder: TestBuilder(
                buildExtensions: replaceExtension('.txt', '.a.txt'),
              ),
              key: 'TestBuilder',
              package: 'foo',
              hideOutput: false,
            ),
            InBuildPhase(
              builder: TestBuilder(
                buildExtensions: replaceExtension('.txt', '.b.txt'),
              ),
              key: 'TestBuilder',
              package: 'foo',
              hideOutput: false,
            ),
            InBuildPhase(
              builder: TestBuilder(
                buildExtensions: replaceExtension('.a.b.txt', '.a.b.c.txt'),
              ),
              key: 'TestBuilder',
              package: 'foo',
              hideOutput: false,
            ),
          ]);

          final buildStepPlan = BuildStepPlan.compute(
            buildPhases: buildPhases,
            placeholderIds: [],
            sources: {
              makeAssetId('foo|lib/1.txt'),
              makeAssetId('foo|lib/2.txt'),
            },
          );

          expect(
            buildStepPlan.declaredOutputs,
            unorderedEquals([
              makeAssetId('foo|lib/1.a.txt'),
              makeAssetId('foo|lib/1.b.txt'),
              makeAssetId('foo|lib/1.a.b.txt'),
              makeAssetId('foo|lib/1.a.b.c.txt'),
              makeAssetId('foo|lib/2.a.txt'),
              makeAssetId('foo|lib/2.b.txt'),
              makeAssetId('foo|lib/2.a.b.txt'),
              makeAssetId('foo|lib/2.a.b.c.txt'),
            ]),
          );
        });

        test('allows running on generated inputs that do not match target '
            'source globs', () async {
          final sources = {makeAssetId('foo|lib/1.txt')};
          final buildPhases = BuildPhases([
            InBuildPhase(
              builder: TestBuilder(
                buildExtensions: appendExtension('.1', from: '.txt'),
              ),
              key: 'TestBuilder',
              package: 'foo',
            ),
            InBuildPhase(
              builder: TestBuilder(
                buildExtensions: appendExtension('.2', from: '.1'),
              ),
              key: 'TestBuilder',
              package: 'foo',
              targetSources: const InputSet(include: ['lib/*.txt']),
            ),
          ]);

          final computed = BuildStepPlan.compute(
            buildPhases: buildPhases,
            placeholderIds: [],
            sources: sources,
          );
          final buildStepsByDeclaredOutput =
              computed.buildStepsByDeclaredOutput;

          expect(
            buildStepsByDeclaredOutput.keys,
            unorderedEquals([
              makeAssetId('foo|lib/1.txt.1'),
              makeAssetId('foo|lib/1.txt.1.2'),
            ]),
          );
        });

        test('https://github.com/dart-lang/build/issues/1804', () async {
          final source = AssetId('a', 'lib/a.dart');
          final renamedSource = AssetId('a', 'lib/A.dart');
          final generatedPart = AssetId('a', 'lib/a.g.part');
          final toBeGeneratedDart = AssetId('a', 'lib/A.g.dart');
          final buildPhases = BuildPhases([
            InBuildPhase(
              builder: TestBuilder(
                buildExtensions: replaceExtension('.dart', '.g.part'),
              ),
              key: 'TestBuilder',
              package: 'a',
            ),
            InBuildPhase(
              builder: TestBuilder(
                buildExtensions: replaceExtension('.g.part', '.g.dart'),
              ),
              key: 'TestBuilder',
              package: 'a',
            ),
          ]);
          final buildState = BuildState.create(sources: {source});

          final buildStepPlan = BuildStepPlan.compute(
            buildPhases: buildPhases,
            placeholderIds: [],
            sources: {source},
          );

          // Pretend a build happened.
          buildState.addMissingSource(toBeGeneratedDart);
          final buildStepId = BuildStepId(
            primaryInput: generatedPart,
            phaseNumber: 1,
          );
          final stepResult = BuildStepResult((b) {
            b.result = true;
            b.isHidden = false;
            b.inputs.addAll([generatedPart, toBeGeneratedDart]);
          });
          buildState.updateBuildStepResult(buildStepId, stepResult);

          expect(buildState.isSource(source), isTrue);

          final adds = {renamedSource};
          final removes = {source};

          final newSources =
              buildState.sources.toSet()
                ..addAll(adds)
                ..removeAll(removes);

          final newBuildState = BuildState.create(sources: newSources);

          // Populate missing sources in newBuildState using the new logic:
          final stillMissing = buildState.missingSources.difference(adds);
          for (final id in stillMissing) {
            newBuildState.addMissingSource(id);
          }
          final newlyMissing = <AssetId>{};
          void addTransitiveOutputs(AssetId id) {
            if (newlyMissing.add(id)) {
              buildStepPlan.declaredOutputsOf(id).forEach(addTransitiveOutputs);
            }
          }
          for (final id in removes) {
            addTransitiveOutputs(id);
          }
          for (final id in newlyMissing) {
            newBuildState.addMissingSource(id);
          }

          // The old generated part file should be marked as missing.
          expect(newBuildState.isMissingSource(generatedPart), isTrue);
        });
      });
    });
  });

  group('BuildStepPlan.transitiveDeclaredOutputsOf', () {
    late BuildStepPlan plan;

    setUp(() {
      plan = BuildStepPlan((builder) => builder..buildPhases = BuildPhases([]));
    });

    test('empty plan', () {
      expect(plan.transitiveDeclaredOutputsOf([]), isEmpty);
      expect(plan.transitiveDeclaredOutputsOf([makeAssetId('foo|a')]), {
        makeAssetId('foo|a'),
      });
    });

    test('chain: a -> b -> c', () {
      final a = makeAssetId('foo|a');
      final b = makeAssetId('foo|b');
      final c = makeAssetId('foo|c');
      plan = BuildStepPlan(
        (builder) =>
            builder
              ..buildPhases = BuildPhases([])
              ..declaredOutputsByPrimaryInput.addValues(a, [b])
              ..declaredOutputsByPrimaryInput.addValues(b, [c]),
      );

      expect(plan.transitiveDeclaredOutputsOf([a]), unorderedEquals({a, b, c}));
      expect(plan.transitiveDeclaredOutputsOf([b]), unorderedEquals({b, c}));
      expect(plan.transitiveDeclaredOutputsOf([c]), unorderedEquals({c}));
    });

    test('diamond: a -> b, c; b -> d; c -> d', () {
      final a = makeAssetId('foo|a');
      final b = makeAssetId('foo|b');
      final c = makeAssetId('foo|c');
      final d = makeAssetId('foo|d');
      plan = BuildStepPlan(
        (builder) =>
            builder
              ..buildPhases = BuildPhases([])
              ..declaredOutputsByPrimaryInput.addValues(a, [b, c])
              ..declaredOutputsByPrimaryInput.addValues(b, [d])
              ..declaredOutputsByPrimaryInput.addValues(c, [d]),
      );

      expect(
        plan.transitiveDeclaredOutputsOf([a]),
        unorderedEquals({a, b, c, d}),
      );
    });

    test('multiple inputs', () {
      final a = makeAssetId('foo|a');
      final b = makeAssetId('foo|b');
      final c = makeAssetId('foo|c');
      final d = makeAssetId('foo|d');
      plan = BuildStepPlan(
        (builder) =>
            builder
              ..buildPhases = BuildPhases([])
              ..declaredOutputsByPrimaryInput.addValues(a, [b])
              ..declaredOutputsByPrimaryInput.addValues(c, [d]),
      );

      expect(
        plan.transitiveDeclaredOutputsOf([a, c]),
        unorderedEquals({a, b, c, d}),
      );
    });
  });
}
