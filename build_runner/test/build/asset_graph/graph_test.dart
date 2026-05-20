// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/src/build/asset_graph/build_step_id.dart';
import 'package:build_runner/src/build/asset_graph/build_step_result.dart';
import 'package:build_runner/src/build/asset_graph/exceptions.dart';
import 'package:build_runner/src/build/asset_graph/graph.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/build_plan/build_phases.dart';
import 'package:build_runner/src/build_plan/phase.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import '../../common/common.dart';

void main() {
  final fooPackageGraph = BuildPackages.singlePackageBuild('foo', {
    BuildPackage.forTesting(name: 'foo', isOutput: true),
  });

  group('AssetGraph', () {
    late AssetGraph graph;

    void expectNodeDoesNotExist(AssetId id) {
      expect(graph.isKnownFile(id), isFalse);
      expect(graph.isSource(id), isFalse);
    }

    void expectNodeExists(AssetId id) {
      expect(graph.isKnownFile(id), isTrue);
      expect(graph.isSource(id), isTrue);
    }

    AssetId testAddNode(int number) {
      final id = AssetId.parse('pkg|lib/a$number.dart');
      expectNodeDoesNotExist(id);
      graph.addSourceForTest(id);
      expectNodeExists(id);
      return id;
    }

    group('simple graph', () {
      setUp(() async {
        graph = await AssetGraph.build(
          BuildPhases([]),
          <AssetId>{},
          fooPackageGraph,
        );
      });

      test('add, contains, get, allNodes', () {
        final expectedNodes = [for (var i = 0; i < 5; i++) testAddNode(i)];
        expect(graph.sources, unorderedEquals(expectedNodes));
      });

      test('remove', () {
        final nodes = <AssetId>[];
        for (var i = 0; i < 5; i++) {
          nodes.add(testAddNode(i));
        }
        graph
          ..removeForTest(nodes[1])
          ..removeForTest(nodes[4]);

        expectNodeExists(nodes[0]);
        expectNodeDoesNotExist(nodes[1]);
        expectNodeExists(nodes[2]);
        expectNodeDoesNotExist(nodes[4]);
        expectNodeExists(nodes[3]);

        graph
          // Doesn't throw.
          ..removeForTest(nodes[1])
          // Can be added back
          ..addSourceForTest(nodes[1]);
        expectNodeExists(nodes[1]);
      });
    });

    group('with buildPhases', () {
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
        graph = await AssetGraph.build(buildPhases, {
          primaryInputId,
          excludedInputId,
        }, fooPackageGraph);
      });

      test('build', () {
        expect(graph.outputs, unorderedEquals([primaryOutputId]));
        expect(
          graph.sources,
          unorderedEquals([primaryInputId, excludedInputId]),
        );
        expect(graph.primaryOutputsOf(primaryInputId), [primaryOutputId]);

        final buildStepId = BuildStepId(
          primaryInput: primaryInputId,
          phaseNumber: 0,
        );
        expect(graph.buildStepResultFor(buildStepId)!.result, isNull);
        expect(
          graph.buildStepsByDeclaredOutput[primaryOutputId]!.primaryInput,
          primaryInputId,
        );
      });

      group('updateAndInvalidate', () {
        test('add new primary input', () async {
          final changes = {AssetId('foo', 'new.txt'): ChangeType.ADD};
          await graph.updateAndInvalidate(buildPhases, changes);
          expect(graph.isKnownFile(AssetId('foo', 'new.txt.copy')), isTrue);
        });

        test('modify primary input', () async {
          final changes = {primaryInputId: ChangeType.MODIFY};
          expect(graph.isKnownFile(primaryOutputId), isTrue);
          final buildStepId = BuildStepId(
            primaryInput: primaryInputId,
            phaseNumber: 0,
          );
          final stepResult = BuildStepResult((b) {
            b.result = true;
            b.isHidden = false;
            b.inputs.add(primaryInputId);
          });
          graph.updateBuildStepResult(buildStepId, stepResult);
          await graph.updateAndInvalidate(buildPhases, changes);
          expect(graph.isKnownFile(primaryInputId), isTrue);
          expect(graph.isKnownFile(primaryOutputId), isTrue);
        });

        test('add new primary input which replaces a synthetic node', () async {
          graph.addMissingSource(syntheticId);
          expect(graph.isMissingSource(syntheticId), isTrue);

          final changes = {syntheticId: ChangeType.ADD};
          await graph.updateAndInvalidate(buildPhases, changes);

          expect(graph.isKnownFile(syntheticId), isTrue);
          expect(graph.isSource(syntheticId), isTrue);
          expect(graph.isKnownFile(syntheticOutputId), isTrue);
          expect(graph.isDeclaredOutput(syntheticOutputId), isTrue);
        });

        test(
          'add new generated asset which replaces a synthetic node',
          () async {
            graph.addMissingSource(syntheticOutputId);
            expect(graph.isMissingSource(syntheticOutputId), isTrue);

            final changes = {syntheticId: ChangeType.ADD};
            await graph.updateAndInvalidate(buildPhases, changes);

            expect(graph.isKnownFile(syntheticOutputId), isTrue);
            expect(graph.isDeclaredOutput(syntheticOutputId), isTrue);
            expect(graph.isKnownFile(syntheticOutputId), isTrue);
          },
        );

        test(
          'removing nodes deletes primary outputs and secondary edges',
          () async {
            final secondaryId = makeAssetId('foo|secondary.txt');

            final buildStepId = BuildStepId(
              primaryInput: primaryInputId,
              phaseNumber: 0,
            );
            final stepResult = BuildStepResult((b) {
              b.result = true;
              b.isHidden = false;
              b.inputs.add(secondaryId);
            });
            graph.updateBuildStepResult(buildStepId, stepResult);

            graph.addSourceForTest(secondaryId);
            expect(graph.isSource(secondaryId), isTrue);

            final changes = {primaryInputId: ChangeType.REMOVE};
            await graph.updateAndInvalidate(buildPhases, changes);

            expect(graph.isMissingSource(primaryInputId), isTrue);
            expect(graph.isMissingSource(primaryOutputId), isTrue);
          },
        );
      });

      test('overlapping build phases cause an error', () async {
        expect(
          () => AssetGraph.build(
            BuildPhases(
              List.filled(
                2,
                InBuildPhase(
                  builder: TestBuilder(),
                  key: 'TestBuilder',
                  package: 'foo',
                ),
              ),
            ),
            {makeAssetId('foo|file')},
            fooPackageGraph,
          ),
          throwsA(isA<DuplicateAssetNodeException>()),
        );
      });

      group('regression tests', () {
        test('build can chains of pre-existing to-source outputs', () async {
          final sources = {
            makeAssetId('foo|lib/1.txt'),
            makeAssetId('foo|lib/2.txt'),
            // All the following are actually old outputs.
            makeAssetId('foo|lib/1.a.txt'),
            makeAssetId('foo|lib/1.a.b.txt'),
            makeAssetId('foo|lib/2.a.txt'),
            makeAssetId('foo|lib/2.a.b.txt'),
            makeAssetId('foo|lib/2.a.b.c.txt'),
          };

          final graph = await AssetGraph.build(
            BuildPhases([
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
            ]),
            sources,
            fooPackageGraph,
          );
          expect(
            graph.outputs,
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
          expect(
            graph.sources,
            unorderedEquals([
              makeAssetId('foo|lib/1.txt'),
              makeAssetId('foo|lib/2.txt'),
            ]),
          );
        });

        test('allows running on generated inputs that do not match target '
            'source globs', () async {
          final sources = {makeAssetId('foo|lib/1.txt')};
          final graph = await AssetGraph.build(
            BuildPhases([
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
            ]),
            sources,
            fooPackageGraph,
          );
          expect(
            graph.outputs,
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
          final buildPackages = BuildPackages.singlePackageBuild('a', {
            BuildPackage.forTesting(name: 'a', isOutput: true),
          });
          final graph = await AssetGraph.build(buildPhases, {
            source,
          }, buildPackages);

          // Pretend a build happened.
          graph.addMissingSource(toBeGeneratedDart);
          final buildStepId = BuildStepId(
            primaryInput: generatedPart,
            phaseNumber: 1,
          );
          final stepResult = BuildStepResult((b) {
            b.result = true;
            b.isHidden = false;
            b.inputs.addAll([generatedPart, toBeGeneratedDart]);
          });
          graph.updateBuildStepResult(buildStepId, stepResult);

          expect(graph.isSource(source), isTrue);

          await graph.updateAndInvalidate(buildPhases, {
            renamedSource: ChangeType.ADD,
            source: ChangeType.REMOVE,
          });

          // The old generated part file should be marked as missing.
          expect(graph.isMissingSource(generatedPart), isTrue);
        });
      });
    });
  });
}
