// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import 'package:build_runner/src/asset_graph/graph.dart';
import 'package:build_runner/src/asset_graph/node.dart';
import 'package:build_runner/src/generate/phase.dart';
import 'package:build_test/build_test.dart';

import '../common/common.dart';
import '../common/package_graphs.dart';

void main() {
  final digestReader = new StubAssetReader();
  final fooPackageGraph = buildPackageGraph({rootPackage('foo'): []});

  group('AssetGraph', () {
    AssetGraph graph;

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
        graph = await AssetGraph
            .build([], new Set(), new Set(), fooPackageGraph, digestReader);
      });

      test('add, contains, get, allNodes', () {
        var expectedNodes = [];
        for (int i = 0; i < 5; i++) {
          expectedNodes.add(testAddNode());
        }
        expectedNodes.addAll(
            placeholderIdsFor(fooPackageGraph).map((id) => graph.get(id)));
        expect(graph.allNodes, unorderedEquals(expectedNodes));
      });

      test('remove', () {
        var nodes = <AssetNode>[];
        for (int i = 0; i < 5; i++) {
          nodes.add(testAddNode());
        }
        graph.remove(nodes[1].id);
        graph.remove(nodes[4].id);

        expectNodeExists(nodes[0]);
        expectNodeDoesNotExist(nodes[1]);
        expectNodeExists(nodes[2]);
        expectNodeDoesNotExist(nodes[4]);
        expectNodeExists(nodes[3]);

        // Doesn't throw.
        graph.remove(nodes[1].id);

        // Can be added back
        graph.add(nodes[1]);
        expectNodeExists(nodes[1]);
      });

      test('serialize/deserialize', () {
        for (int n = 0; n < 5; n++) {
          var node = makeAssetNode();
          graph.add(node);
          var phaseNum = n;
          if (phaseNum % 2 == 0) {
            graph.markActionFailed(phaseNum, node.id);
          }
          var builderOptionsNode =
              new BuilderOptionsAssetNode(makeAssetId(), new Digest([n]));
          graph.add(builderOptionsNode);
          graph.add(new PostProcessAnchorNode.forInputAndAction(
              node.id, n, builderOptionsNode.id));
          for (int g = 0; g < 5 - n; g++) {
            var builderOptionsNode = new BuilderOptionsAssetNode(
                makeAssetId(), md5.convert(utf8.encode('test')));

            var generatedNode = new GeneratedAssetNode(makeAssetId(),
                phaseNumber: phaseNum,
                primaryInput: node.id,
                state: GeneratedNodeState
                    .values[g % GeneratedNodeState.values.length],
                wasOutput: g % 2 == 0,
                builderOptionsId: builderOptionsNode.id,
                isHidden: g % 3 == 0);
            node.outputs.add(generatedNode.id);
            node.primaryOutputs.add(generatedNode.id);
            builderOptionsNode.outputs.add(generatedNode.id);

            var syntheticNode = new SyntheticSourceAssetNode(makeAssetId());
            syntheticNode.outputs.add(generatedNode.id);

            generatedNode.inputs.addAll([node.id, syntheticNode.id]);
            if (g % 2 == 1) {
              // Fake a digest using the id, we just care that this gets
              // serialized/deserialized properly.
              generatedNode.previousInputsDigest =
                  md5.convert(utf8.encode(generatedNode.id.toString()));
            }

            graph.add(syntheticNode);
            graph.add(generatedNode);
            graph.add(builderOptionsNode);
          }
        }

        var encoded = graph.serialize();
        var decoded = new AssetGraph.deserialize(encoded);
        expect(decoded.failedActions, isNotEmpty);
        expect(graph, equalsAssetGraph(decoded));
      });

      test('Throws an AssetGraphVersionError if versions dont match up', () {
        var bytes = graph.serialize();
        var serialized = json.decode(utf8.decode(bytes));
        serialized['version'] = -1;
        var encoded = utf8.encode(json.encode(serialized));
        expect(() => new AssetGraph.deserialize(encoded),
            throwsA(assetGraphVersionException));
      });

      group('failedActions/markActionFailed/markActionSucceeded', () {
        var aTxt = makeAssetId('foo|lib/a.txt');
        var bTxt = makeAssetId('foo|lib/b.txt');

        test('basic functionality', () {
          expect(graph.failedActions, isEmpty);
          graph.markActionFailed(1, aTxt);
          expect(graph.failedActions[1], equals([aTxt]));
          graph.markActionFailed(1, bTxt);
          expect(graph.failedActions[1], unorderedEquals([aTxt, bTxt]));
          graph.markActionSucceeded(1, aTxt);
          expect(graph.failedActions[1], equals([bTxt]));
          graph.markActionFailed(2, bTxt);
          expect(graph.failedActions[2], equals([bTxt]));
          graph.markActionSucceeded(1, bTxt);
          graph.markActionSucceeded(2, bTxt);
          expect(graph.failedActions, isEmpty);
        });

        test('deleted nodes remove their failures', () async {
          graph = await AssetGraph.build([
            new InBuildPhase(
                new TestBuilder(
                    buildExtensions: appendExtension('.copy', from: '.txt')),
                'foo'),
            new InBuildPhase(
                new TestBuilder(
                    buildExtensions: appendExtension('.clone', from: '.txt')),
                'foo'),
          ], [aTxt, bTxt].toSet(), new Set(), fooPackageGraph, digestReader);
          graph.markActionFailed(0, aTxt);
          graph.markActionFailed(1, aTxt);
          expect(graph.failedActions, isNotEmpty);
          graph.remove(aTxt);
          expect(graph.failedActions, isEmpty);
        });
      });
    });

    group('with buildPhases', () {
      var targetSources = const InputSet(exclude: const ['excluded.txt']);
      final buildPhases = [
        new InBuildPhase(
            new TestBuilder(
                buildExtensions: appendExtension('.copy', from: '.txt')),
            'foo',
            targetSources: targetSources),
        new PostBuildPhase([
          new PostBuildAction(
              new CopyingPostProcessBuilder(outputExtension: '.post'), 'foo',
              targetSources: targetSources,
              builderOptions: const BuilderOptions(const {}),
              generateFor: const InputSet())
        ])
      ];
      final primaryInputId = makeAssetId('foo|file.txt');
      final excludedInputId = makeAssetId('foo|excluded.txt');
      final primaryOutputId = makeAssetId('foo|file.txt.copy');
      final syntheticId = makeAssetId('foo|synthetic.txt');
      final syntheticOutputId = makeAssetId('foo|synthetic.txt.copy');
      final internalId =
          makeAssetId('foo|.dart_tool/build/entrypoint/serve.dart');
      final builderOptionsId = makeAssetId('foo|Phase0.builderOptions');
      final postBuilderOptionsId = makeAssetId('foo|PostPhase0.builderOptions');
      final placeholders = placeholderIdsFor(fooPackageGraph);
      final expectedAnchorNode = new PostProcessAnchorNode.forInputAndAction(
          primaryInputId, 0, postBuilderOptionsId);

      setUp(() async {
        graph = await AssetGraph.build(
            buildPhases,
            new Set.from([primaryInputId, excludedInputId]),
            [internalId].toSet(),
            fooPackageGraph,
            digestReader);
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
              builderOptionsId,
              expectedAnchorNode.id,
              postBuilderOptionsId,
            ]..addAll(placeholders)));
        var node = graph.get(primaryInputId);
        expect(node.primaryOutputs, [primaryOutputId]);
        expect(node.outputs, [primaryOutputId]);
        expect(node.lastKnownDigest, isNotNull,
            reason: 'Nodes with outputs should get an eager digest.');

        var excludedNode = graph.get(excludedInputId);
        expect(excludedNode, isNotNull);
        expect(excludedNode.lastKnownDigest, isNull,
            reason: 'Nodes with no output shouldn\'t get an eager digest.');

        expect(graph.get(internalId), new isInstanceOf<InternalAssetNode>());

        var primaryOutputNode =
            graph.get(primaryOutputId) as GeneratedAssetNode;
        expect(primaryOutputNode.builderOptionsId, builderOptionsId);
        // Didn't actually do a build yet so this starts out empty.
        expect(primaryOutputNode.inputs, isEmpty);
        expect(primaryOutputNode.primaryInput, primaryInputId);

        var builderOptionsNode =
            graph.get(builderOptionsId) as BuilderOptionsAssetNode;
        expect(builderOptionsNode.outputs, unorderedEquals([primaryOutputId]));

        var postBuilderOptionsNode =
            graph.get(postBuilderOptionsId) as BuilderOptionsAssetNode;
        expect(postBuilderOptionsNode, isNotNull);
        expect(postBuilderOptionsNode.outputs, isEmpty);
        var anchorNode =
            graph.get(expectedAnchorNode.id) as PostProcessAnchorNode;
        expect(anchorNode, isNotNull);
      });

      group('updateAndInvalidate', () {
        test('add new primary input', () async {
          var changes = {new AssetId('foo', 'new.txt'): ChangeType.ADD};
          await graph.updateAndInvalidate(
              buildPhases, changes, 'foo', null, digestReader);
          expect(graph.contains(new AssetId('foo', 'new.txt.copy')), isTrue);
          var newAnchor = new PostProcessAnchorNode.forInputAndAction(
              primaryInputId, 0, null);
          expect(graph.contains(newAnchor.id), isTrue);
        });

        test('delete old primary input', () async {
          var changes = {primaryInputId: ChangeType.REMOVE};
          var deletes = <AssetId>[];
          expect(graph.contains(primaryOutputId), isTrue);
          await graph.updateAndInvalidate(buildPhases, changes, 'foo',
              (id) async => deletes.add(id), digestReader);
          expect(graph.contains(primaryInputId), isFalse);
          expect(graph.contains(primaryOutputId), isFalse);
          expect(deletes, equals([primaryOutputId]));
          expect(graph.contains(expectedAnchorNode.id), isFalse,
              skip: 'https://github.com/dart-lang/build/issues/1144');
        });

        test('modify primary input', () async {
          var changes = {primaryInputId: ChangeType.MODIFY};
          var deletes = <AssetId>[];
          expect(graph.contains(primaryOutputId), isTrue);
          await graph.updateAndInvalidate(buildPhases, changes, 'foo',
              (id) async => deletes.add(id), digestReader);
          expect(graph.contains(primaryInputId), isTrue);
          expect(graph.contains(primaryOutputId), isTrue);
          // We don't pre-emptively delete the file in the case of modifications
          expect(deletes, equals([]));
          var outputNode = graph.get(primaryOutputId) as GeneratedAssetNode;
          // But we should mark it as needing an update
          expect(outputNode.state, GeneratedNodeState.mayNeedUpdate);
        });

        test('add new primary input which replaces a synthetic node', () async {
          var syntheticNode = new SyntheticSourceAssetNode(syntheticId);
          graph.add(syntheticNode);
          expect(graph.get(syntheticId), syntheticNode);

          var changes = {syntheticId: ChangeType.ADD};
          await graph.updateAndInvalidate(
              buildPhases, changes, 'foo', null, digestReader);

          expect(graph.contains(syntheticId), isTrue);
          expect(graph.get(syntheticId), new isInstanceOf<SourceAssetNode>());
          expect(graph.contains(syntheticOutputId), isTrue);
          expect(graph.get(syntheticOutputId),
              new isInstanceOf<GeneratedAssetNode>());

          var newAnchor =
              new PostProcessAnchorNode.forInputAndAction(syntheticId, 0, null);
          expect(graph.contains(newAnchor.id), isTrue);
          expect(graph.get(newAnchor.id),
              new isInstanceOf<PostProcessAnchorNode>());
        });

        test('add new generated asset which replaces a synthetic node',
            () async {
          var syntheticNode = new SyntheticSourceAssetNode(syntheticOutputId);
          graph.add(syntheticNode);
          expect(graph.get(syntheticOutputId), syntheticNode);

          var changes = {syntheticId: ChangeType.ADD};
          await graph.updateAndInvalidate(
              buildPhases, changes, 'foo', null, digestReader);

          expect(graph.contains(syntheticOutputId), isTrue);
          expect(graph.get(syntheticOutputId),
              new isInstanceOf<GeneratedAssetNode>());
          expect(graph.contains(syntheticOutputId), isTrue);
        });

        test('removing nodes deletes primary outputs and secondary edges',
            () async {
          var secondaryId = makeAssetId('foo|secondary.txt');
          var secondaryNode = new SourceAssetNode(secondaryId);
          secondaryNode.outputs.add(primaryOutputId);
          var primaryOutputNode =
              graph.get(primaryOutputId) as GeneratedAssetNode;
          primaryOutputNode.inputs.add(secondaryNode.id);

          graph.add(secondaryNode);
          expect(graph.get(secondaryId), secondaryNode);

          var changes = {primaryInputId: ChangeType.REMOVE};
          await graph.updateAndInvalidate(buildPhases, changes, 'foo',
              (_) => new Future.value(null), digestReader);

          expect(graph.contains(primaryInputId), isFalse);
          expect(graph.contains(primaryOutputId), isFalse);
          expect(
              graph.get(secondaryId).outputs, isNot(contains(primaryOutputId)));
        });

        test(
            'a new or deleted asset matching a glob definitely invalidates '
            'a node', () async {
          var primaryOutputNode =
              graph.get(primaryOutputId) as GeneratedAssetNode;
          primaryOutputNode.globs.add(new Glob('lib/*.cool'));
          primaryOutputNode.state = GeneratedNodeState.upToDate;

          var coolAssetId = new AssetId('foo', 'lib/really.cool');
          var changes = {coolAssetId: ChangeType.ADD};
          await graph.updateAndInvalidate(buildPhases, changes, 'foo',
              (_) => new Future.value(null), digestReader);
          expect(primaryOutputNode.state,
              GeneratedNodeState.definitelyNeedsUpdate);

          primaryOutputNode.state = GeneratedNodeState.upToDate;
          changes = {coolAssetId: ChangeType.REMOVE};
          await graph.updateAndInvalidate(buildPhases, changes, 'foo',
              (_) => new Future.value(null), digestReader);
          expect(primaryOutputNode.state,
              GeneratedNodeState.definitelyNeedsUpdate);
        });
      });
    });

    test('overlapping build phases cause an error', () async {
      expect(
          () => AssetGraph.build(
              new List.filled(2, new InBuildPhase(new TestBuilder(), 'foo')),
              [makeAssetId('foo|file')].toSet(),
              new Set(),
              fooPackageGraph,
              digestReader),
          throwsA(duplicateAssetNodeException));
    });

    group('regression tests', () {
      test('build can chains of pre-existing to-source outputs', () async {
        final graph = await AssetGraph.build(
            [
              new InBuildPhase(
                  new TestBuilder(
                      buildExtensions: replaceExtension('.txt', '.a.txt')),
                  'foo',
                  hideOutput: false),
              new InBuildPhase(
                  new TestBuilder(
                      buildExtensions: replaceExtension('.txt', '.b.txt')),
                  'foo',
                  hideOutput: false),
              new InBuildPhase(
                  new TestBuilder(
                      buildExtensions:
                          replaceExtension('.a.b.txt', '.a.b.c.txt')),
                  'foo',
                  hideOutput: false),
            ],
            [
              makeAssetId('foo|lib/1.txt'),
              makeAssetId('foo|lib/2.txt'),
              // All the following are actually old outputs.
              makeAssetId('foo|lib/1.a.txt'),
              makeAssetId('foo|lib/1.a.b.txt'),
              makeAssetId('foo|lib/2.a.txt'),
              makeAssetId('foo|lib/2.a.b.txt'),
              makeAssetId('foo|lib/2.a.b.c.txt'),
            ].toSet(),
            new Set<AssetId>(),
            fooPackageGraph,
            digestReader);
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
            ]));
        expect(
            graph.sources,
            unorderedEquals([
              makeAssetId('foo|lib/1.txt'),
              makeAssetId('foo|lib/2.txt'),
            ]));
      });

      test(
          'allows running on generated inputs that do not match target '
          'source globs', () async {
        final graph = await AssetGraph.build([
          new InBuildPhase(
              new TestBuilder(
                  buildExtensions: appendExtension('.1', from: '.txt')),
              'foo'),
          new InBuildPhase(
              new TestBuilder(
                  buildExtensions: appendExtension('.2', from: '.1')),
              'foo',
              targetSources: new InputSet(include: ['lib/*.txt'])),
        ], [makeAssetId('foo|lib/1.txt')].toSet(), new Set<AssetId>(),
            fooPackageGraph, digestReader);
        expect(
            graph.outputs,
            unorderedEquals([
              makeAssetId('foo|lib/1.txt.1'),
              makeAssetId('foo|lib/1.txt.1.2')
            ]));
      });
    });
  });
}
