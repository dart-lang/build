// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/src/build/build_state/build_state.dart';
import 'package:build_runner/src/build/build_state/build_step_id.dart';
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
        buildState = BuildState(<AssetId>{});
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

      setUp(() async {
        buildState = BuildState({primaryInputId, excludedInputId});
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
        (builder) => builder
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
        (builder) => builder
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
        (builder) => builder
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
