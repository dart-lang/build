// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:_test_common/common.dart';
import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'package:build_runner_core/src/asset_graph/post_process_build_step_id.dart';
import 'package:build_runner_core/src/generate/build_phases.dart';
import 'package:build_runner_core/src/generate/phase.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

void main() {
  late TestReaderWriter digestReader;
  final fooPackageGraph = buildPackageGraph({rootPackage('foo'): []});

  setUp(() async {
    digestReader = TestReaderWriter();
  });

  group('AssetGraph', () {
    late AssetGraph graph;

    void expectNodeDoesNotExist(AssetNode node) {
      expect(graph.contains(node.id), isFalse);
      expect(graph.get(node.id), isNull);
    }

    void expectNodeExists(AssetNode node) {
      expect(graph.contains(node.id), isTrue);
      expect(graph.get(node.id), node);
    }

    AssetNode testAddNode() {
      var node = makeAssetNode();
      expectNodeDoesNotExist(node);
      graph.add(node);
      expectNodeExists(node);
      return node;
    }

    group('simple graph', () {
      setUp(() async {
        graph = await AssetGraph.build(
          BuildPhases([]),
          <AssetId>{},
          <AssetId>{},
          fooPackageGraph,
          digestReader,
        );
      });

      test('add, contains, get, allNodes', () {
        var expectedNodes = [
          for (var i = 0; i < 5; i++) testAddNode(),
          for (var id in placeholderIdsFor(fooPackageGraph)) graph.get(id),
        ];
        expect(graph.allNodes, unorderedEquals(expectedNodes));
      });

      test('remove', () {
        var nodes = <AssetNode>[];
        for (var i = 0; i < 5; i++) {
          nodes.add(testAddNode());
        }
        graph
          ..removeForTest(nodes[1].id)
          ..removeForTest(nodes[4].id);

        expectNodeExists(nodes[0]);
        expectNodeDoesNotExist(nodes[1]);
        expectNodeExists(nodes[2]);
        expectNodeDoesNotExist(nodes[4]);
        expectNodeExists(nodes[3]);

        graph
          // Doesn't throw.
          ..removeForTest(nodes[1].id)
          // Can be added back
          ..add(nodes[1]);
        expectNodeExists(nodes[1]);
      });

      test('serialize/deserialize', () {
        var globNode = AssetNode.glob(
          makeAssetId(),
          glob: '**/*.dart',
          phaseNumber: 0,
          inputs: HashSet(),
          results: [],
        );
        for (var n = 0; n < 5; n++) {
          var node = makeAssetNode();
          globNode = globNode.rebuild(
            (b) =>
                b.globNodeState
                  ..inputs.add(node.id)
                  ..results.add(node.id),
          );
          var phaseNum = n;
          final postProcessBuildStep = PostProcessBuildStepId(
            input: node.id,
            actionNumber: n,
          );
          graph.updatePostProcessBuildStep(postProcessBuildStep, outputs: {});
          for (var g = 0; g < 5 - n; g++) {
            var generatedNode = AssetNode.generated(
              makeAssetId(),
              phaseNumber: phaseNum,
              primaryInput: node.id,
              digest: g.isEven ? Digest([]) : null,
              result: phaseNum.isOdd,
              isHidden: g % 3 == 0,
            );
            node = node.rebuild((b) => b..primaryOutputs.add(generatedNode.id));
            if (g.isEven) {
              node = node.rebuild(
                (b) => b..deletedBy.add(postProcessBuildStep),
              );
            }

            var syntheticNode = AssetNode.missingSource(makeAssetId());

            generatedNode = generatedNode.rebuild(
              (b) => b.generatedNodeState.inputs.addAll([
                node.id,
                syntheticNode.id,
                globNode.id,
              ]),
            );
            graph
              ..add(generatedNode)
              ..add(syntheticNode);
          }
          graph.add(node);
        }
        graph.add(globNode);

        var encoded = graph.serialize();
        var decoded = AssetGraph.deserialize(encoded);
        expect(decoded, equalsAssetGraph(graph));
        expect(
          decoded.allPostProcessBuildStepOutputs,
          graph.allPostProcessBuildStepOutputs,
        );
      });

      test(
        'Throws an AssetGraphCorruptedException if versions dont match up',
        () {
          var bytes = graph.serialize();
          var serialized =
              json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
          serialized['version'] = -1;
          var encoded = utf8.encode(json.encode(serialized));
          expect(
            () => AssetGraph.deserialize(encoded),
            throwsCorruptedException,
          );
        },
      );

      test('Throws an AssetGraphCorruptedException on invalid json', () {
        var bytes = List.of(graph.serialize())..removeLast();
        expect(() => AssetGraph.deserialize(bytes), throwsCorruptedException);
      });
    });

    group('with buildPhases', () {
      var targetSources = const InputSet(exclude: ['excluded.txt']);
      final buildPhases = BuildPhases(
        [
          InBuildPhase(
            TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.txt'),
            ),
            'foo',
            targetSources: targetSources,
          ),
        ],
        PostBuildPhase([
          PostBuildAction(
            CopyingPostProcessBuilder(outputExtension: '.post'),
            'foo',
            targetSources: targetSources,
            builderOptions: const BuilderOptions({}),
            generateFor: const InputSet(),
          ),
        ]),
      );
      final primaryInputId = makeAssetId('foo|file.txt');
      final excludedInputId = makeAssetId('foo|excluded.txt');
      final primaryOutputId = makeAssetId('foo|file.txt.copy');
      final syntheticId = makeAssetId('foo|synthetic.txt');
      final syntheticOutputId = makeAssetId('foo|synthetic.txt.copy');
      final internalId = makeAssetId(
        'foo|.dart_tool/build/entrypoint/serve.dart',
      );
      final placeholders = placeholderIdsFor(fooPackageGraph);
      final expectedBuildStepId = PostProcessBuildStepId(
        input: primaryInputId,
        actionNumber: 0,
      );

      setUp(() async {
        for (final id in [primaryInputId, internalId]) {
          digestReader.testing.writeString(id, 'contents of $id');
        }
        graph = await AssetGraph.build(
          buildPhases,
          {primaryInputId, excludedInputId},
          {internalId},
          fooPackageGraph,
          digestReader,
        );
      });

      test('build', () {
        expect(graph.outputs, unorderedEquals([primaryOutputId]));
        expect(
          graph.allNodes.map((n) => n.id),
          unorderedEquals([
            primaryInputId,
            excludedInputId,
            primaryOutputId,
            internalId,
            ...placeholders,
          ]),
        );
        expect(graph.postProcessBuildStepIds(package: 'foo'), {
          expectedBuildStepId,
        });
        var node = graph.get(primaryInputId)!;
        expect(node.primaryOutputs, [primaryOutputId]);
        expect(graph.computeOutputs()[node.id] ?? <AssetId>{}, isEmpty);
        expect(
          node.digest,
          isNotNull,
          reason: 'Nodes with outputs should get an eager digest.',
        );

        var excludedNode = graph.get(excludedInputId);
        expect(excludedNode, isNotNull);
        expect(
          excludedNode!.digest,
          isNull,
          reason: 'Nodes with no output shouldn\'t get an eager digest.',
        );

        expect(graph.get(internalId)?.type, NodeType.internal);

        var primaryOutputNode = graph.get(primaryOutputId)!;
        // Didn't actually do a build yet so this starts out empty.
        expect(primaryOutputNode.generatedNodeState!.inputs, isEmpty);
        expect(
          primaryOutputNode.generatedNodeConfiguration!.primaryInput,
          primaryInputId,
        );

        expect(graph.postProcessBuildStepIds(package: 'foo'), {
          expectedBuildStepId,
        });
      });

      group('updateAndInvalidate', () {
        test('add new primary input', () async {
          var changes = {AssetId('foo', 'new.txt'): ChangeType.ADD};
          await graph.updateAndInvalidate(
            buildPhases,
            changes,
            'foo',
            (_) async {},
            digestReader,
          );
          expect(graph.contains(AssetId('foo', 'new.txt.copy')), isTrue);
          var newBuildStepId = PostProcessBuildStepId(
            input: primaryInputId,
            actionNumber: 0,
          );
          expect(
            graph.postProcessBuildStepIds(package: 'foo'),
            contains(newBuildStepId),
          );
        });

        test('delete old primary input', () async {
          var changes = {primaryInputId: ChangeType.REMOVE};
          var deletes = <AssetId>[];
          expect(graph.contains(primaryOutputId), isTrue);
          await graph.updateAndInvalidate(
            buildPhases,
            changes,
            'foo',
            (id) async => deletes.add(id),
            digestReader,
          );
          expect(graph.get(primaryInputId)!.type, NodeType.missingSource);
          expect(graph.get(primaryOutputId)!.type, NodeType.missingSource);
          expect(deletes, equals([primaryOutputId]));
          expect(graph.postProcessBuildStepIds(package: 'foo'), isEmpty);
        });

        test('modify primary input', () async {
          var changes = {primaryInputId: ChangeType.MODIFY};
          var deletes = <AssetId>[];
          expect(graph.contains(primaryOutputId), isTrue);
          // pretend a build happened
          graph.updateNode(primaryOutputId, (nodeBuilder) {
            nodeBuilder.generatedNodeState.inputs.add(primaryInputId);
          });
          await graph.updateAndInvalidate(
            buildPhases,
            changes,
            'foo',
            (id) async => deletes.add(id),
            digestReader,
          );
          expect(graph.contains(primaryInputId), isTrue);
          expect(graph.contains(primaryOutputId), isTrue);
          // We don't pre-emptively delete the file in the case of modifications
          expect(deletes, isEmpty);
        });

        test('add new primary input which replaces a synthetic node', () async {
          var syntheticNode = AssetNode.missingSource(syntheticId);
          graph.add(syntheticNode);
          expect(graph.get(syntheticId), syntheticNode);

          var changes = {syntheticId: ChangeType.ADD};
          await graph.updateAndInvalidate(
            buildPhases,
            changes,
            'foo',
            (_) async {},
            digestReader,
          );

          expect(graph.contains(syntheticId), isTrue);
          expect(graph.get(syntheticId)?.type, NodeType.source);
          expect(graph.contains(syntheticOutputId), isTrue);
          expect(graph.get(syntheticOutputId)!.type, NodeType.generated);

          var newAnchor = PostProcessBuildStepId(
            input: syntheticId,
            actionNumber: 0,
          );
          expect(
            graph.postProcessBuildStepIds(package: 'foo'),
            contains(newAnchor),
          );
        });

        test(
          'add new generated asset which replaces a synthetic node',
          () async {
            var syntheticNode = AssetNode.missingSource(syntheticOutputId);
            graph.add(syntheticNode);
            expect(graph.get(syntheticOutputId), syntheticNode);

            var changes = {syntheticId: ChangeType.ADD};
            await graph.updateAndInvalidate(
              buildPhases,
              changes,
              'foo',
              (_) async {},
              digestReader,
            );

            expect(graph.contains(syntheticOutputId), isTrue);
            expect(graph.get(syntheticOutputId)!.type, NodeType.generated);
            expect(graph.contains(syntheticOutputId), isTrue);
          },
        );

        test(
          'removing nodes deletes primary outputs and secondary edges',
          () async {
            var secondaryId = makeAssetId('foo|secondary.txt');
            var secondaryNode = AssetNode.source(secondaryId);

            graph.updateNode(primaryOutputId, (nodeBuilder) {
              nodeBuilder.generatedNodeState.inputs.add(secondaryNode.id);
            });

            graph.add(secondaryNode);
            expect(graph.get(secondaryId), secondaryNode);

            var changes = {primaryInputId: ChangeType.REMOVE};
            await graph.updateAndInvalidate(
              buildPhases,
              changes,
              'foo',
              (_) => Future.value(null),
              digestReader,
            );

            expect(graph.get(primaryInputId)!.type, NodeType.missingSource);
            expect(graph.get(primaryOutputId)!.type, NodeType.missingSource);
            expect(
              graph.computeOutputs()[secondaryId] ?? const <AssetId>{},
              isNot(contains(primaryOutputId)),
            );
          },
        );
      });

      test('overlapping build phases cause an error', () async {
        expect(
          () => AssetGraph.build(
            BuildPhases(List.filled(2, InBuildPhase(TestBuilder(), 'foo'))),
            {makeAssetId('foo|file')},
            <AssetId>{},
            fooPackageGraph,
            digestReader,
          ),
          throwsA(duplicateAssetNodeException),
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

          for (final id in sources) {
            digestReader.testing.writeString(id, 'contents of $id');
          }
          final graph = await AssetGraph.build(
            BuildPhases([
              InBuildPhase(
                TestBuilder(
                  buildExtensions: replaceExtension('.txt', '.a.txt'),
                ),
                'foo',
                hideOutput: false,
              ),
              InBuildPhase(
                TestBuilder(
                  buildExtensions: replaceExtension('.txt', '.b.txt'),
                ),
                'foo',
                hideOutput: false,
              ),
              InBuildPhase(
                TestBuilder(
                  buildExtensions: replaceExtension('.a.b.txt', '.a.b.c.txt'),
                ),
                'foo',
                hideOutput: false,
              ),
            ]),
            sources,
            <AssetId>{},
            fooPackageGraph,
            digestReader,
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
          for (final id in sources) {
            digestReader.testing.writeString(id, 'contents of $id');
          }
          final graph = await AssetGraph.build(
            BuildPhases([
              InBuildPhase(
                TestBuilder(
                  buildExtensions: appendExtension('.1', from: '.txt'),
                ),
                'foo',
              ),
              InBuildPhase(
                TestBuilder(buildExtensions: appendExtension('.2', from: '.1')),
                'foo',
                targetSources: const InputSet(include: ['lib/*.txt']),
              ),
            ]),
            sources,
            <AssetId>{},
            fooPackageGraph,
            digestReader,
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
          digestReader.testing.writeString(source, 'contents of $source');
          final renamedSource = AssetId('a', 'lib/A.dart');
          final generatedDart = AssetId('a', 'lib/a.g.dart');
          final generatedPart = AssetId('a', 'lib/a.g.part');
          final toBeGeneratedDart = AssetId('a', 'lib/A.g.dart');
          final buildPhases = BuildPhases([
            InBuildPhase(
              TestBuilder(
                buildExtensions: replaceExtension('.dart', '.g.part'),
              ),
              'a',
            ),
            InBuildPhase(
              TestBuilder(
                buildExtensions: replaceExtension('.g.part', '.g.dart'),
              ),
              'a',
            ),
          ]);
          final packageGraph = buildPackageGraph({rootPackage('a'): []});
          final graph = await AssetGraph.build(
            buildPhases,
            {source},
            <AssetId>{},
            packageGraph,
            digestReader,
          );

          // Pretend a build happened
          graph.add(AssetNode.missingSource(toBeGeneratedDart));
          graph.updateNode(generatedDart, (nodeBuilder) {
            nodeBuilder.generatedNodeState.inputs.addAll([
              generatedPart,
              toBeGeneratedDart,
            ]);
          });

          expect(graph.get(source)!.type, NodeType.source);

          await graph.updateAndInvalidate(
            buildPhases,
            {renamedSource: ChangeType.ADD, source: ChangeType.REMOVE},
            'a',
            (_) async {},
            digestReader,
          );

          // The old generated part file should be marked as missing.
          expect(graph.get(generatedPart)!.type, NodeType.missingSource);

          // The generated part file should not exist in outputs of the new
          // generated dart file
          expect(
            graph.computeOutputs()[toBeGeneratedDart] ?? <AssetId>{},
            isNot(contains(generatedPart)),
          );
        });
      });
    });
  });
}
