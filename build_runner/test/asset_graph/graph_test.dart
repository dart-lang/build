// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import 'package:build_runner/src/asset/reader.dart';
import 'package:build_runner/src/asset_graph/graph.dart';
import 'package:build_runner/src/asset_graph/node.dart';
import 'package:build_runner/src/generate/phase.dart';
import 'package:build_test/build_test.dart';

import '../common/common.dart';

void main() {
  final digestReader = new MockDigestReader();

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
        graph = await AssetGraph.build([], new Set(), 'foo', digestReader);
      });

      test('add, contains, get, allNodes', () {
        var expectedNodes = [];
        for (int i = 0; i < 5; i++) {
          expectedNodes.add(testAddNode());
        }
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
          for (int g = 0; g < 5 - n; g++) {
            var generatedNode = new GeneratedAssetNode(
                0, node.id, g % 2 == 1, g % 2 == 0, makeAssetId());
            node.outputs.add(generatedNode.id);
            node.primaryOutputs.add(generatedNode.id);

            var syntheticNode = new SyntheticAssetNode(makeAssetId());
            syntheticNode.outputs.add(generatedNode.id);

            generatedNode.inputs.addAll([node.id, syntheticNode.id]);
            if (g % 2 == 1) {
              // Fake a digest using the id, we just care that this gets
              // serialized/deserialized properly.
              generatedNode.previousInputsDigest =
                  md5.convert(UTF8.encode(generatedNode.id.toString()));
            }

            graph.add(syntheticNode);
            graph.add(generatedNode);
          }
        }

        var encoded = JSON.encode(graph.serialize());
        var decoded = new AssetGraph.deserialize(JSON.decode(encoded) as Map);
        expect(graph, equalsAssetGraph(decoded));
      });

      test('Throws an AssetGraphVersionError if versions dont match up', () {
        var serialized = graph.serialize();
        serialized['version'] = -1;
        var encoded = JSON.encode(serialized);
        expect(() => new AssetGraph.deserialize(JSON.decode(encoded) as Map),
            throwsA(assetGraphVersionException));
      });
    });

    group('with buildActions', () {
      final buildActions = [
        new BuildAction(new CopyBuilder(), 'foo', excludes: ['excluded'])
      ];
      final primaryInputId = makeAssetId('foo|file');
      final excludedInputId = makeAssetId('foo|excluded');
      final primaryOutputId = makeAssetId('foo|file.copy');
      final syntheticId = makeAssetId('foo|synthetic');
      final syntheticOutputId = makeAssetId('foo|synthetic.copy');

      setUp(() async {
        graph = await AssetGraph.build(
            buildActions,
            new Set.from([primaryInputId, excludedInputId]),
            'foo',
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
            ]));
        var node = graph.get(primaryInputId);
        expect(node.primaryOutputs, [primaryOutputId]);
        expect(node.outputs, [primaryOutputId]);
        expect(node.lastKnownDigest, isNotNull,
            reason: 'Nodes with outputs should get an eager digest.');

        var excludedNode = graph.get(excludedInputId);
        expect(excludedNode, isNotNull);
        expect(excludedNode.lastKnownDigest, isNull,
            reason: 'Nodes with no output shouldn\'t get an eager digest.');
      });

      group('updateAndInvalidate', () {
        test('add new primary input', () async {
          var changes = {new AssetId('foo', 'new'): ChangeType.ADD};
          await graph.updateAndInvalidate(
              buildActions, changes, 'foo', null, digestReader);
          expect(graph.contains(new AssetId('foo', 'new.copy')), isTrue);
        });

        test('delete old primary input', () async {
          var changes = {primaryInputId: ChangeType.REMOVE};
          var deletes = <AssetId>[];
          expect(graph.contains(primaryOutputId), isTrue);
          await graph.updateAndInvalidate(buildActions, changes, 'foo',
              (id) async => deletes.add(id), digestReader);
          expect(graph.contains(primaryInputId), isFalse);
          expect(graph.contains(primaryOutputId), isFalse);
          expect(deletes, equals([primaryOutputId]));
        });

        test('modify primary input', () async {
          var changes = {primaryInputId: ChangeType.MODIFY};
          var deletes = <AssetId>[];
          expect(graph.contains(primaryOutputId), isTrue);
          await graph.updateAndInvalidate(buildActions, changes, 'foo',
              (id) async => deletes.add(id), digestReader);
          expect(graph.contains(primaryInputId), isTrue);
          expect(graph.contains(primaryOutputId), isTrue);
          // We don't pre-emptively delete the file in the case of modifications
          expect(deletes, equals([]));
          var outputNode = graph.get(primaryOutputId) as GeneratedAssetNode;
          // But we should mark it as needing an update
          expect(outputNode.needsUpdate, isTrue);
        });

        test('add new primary input which replaces a synthetic node', () async {
          var syntheticNode = new SyntheticAssetNode(syntheticId);
          graph.add(syntheticNode);
          expect(graph.get(syntheticId), syntheticNode);

          var changes = {syntheticId: ChangeType.ADD};
          await graph.updateAndInvalidate(
              buildActions, changes, 'foo', null, digestReader);

          expect(graph.contains(syntheticId), isTrue);
          expect(graph.get(syntheticId),
              isNot(new isInstanceOf<SyntheticAssetNode>()));
          expect(graph.contains(syntheticOutputId), isTrue);
        });

        test('add new generated asset which replaces a synthetic node',
            () async {
          var syntheticNode = new SyntheticAssetNode(syntheticOutputId);
          graph.add(syntheticNode);
          expect(graph.get(syntheticOutputId), syntheticNode);

          var changes = {syntheticId: ChangeType.ADD};
          await graph.updateAndInvalidate(
              buildActions, changes, 'foo', null, digestReader);

          expect(graph.contains(syntheticOutputId), isTrue);
          expect(graph.get(syntheticOutputId),
              new isInstanceOf<GeneratedAssetNode>());
          expect(graph.contains(syntheticOutputId), isTrue);
        });

        test('removing nodes deletes primary outputs and secondary edges',
            () async {
          var secondaryId = makeAssetId('foo|secondary');
          var secondaryNode = new SourceAssetNode(secondaryId);
          secondaryNode.outputs.add(primaryOutputId);
          var primaryOutputNode =
              graph.get(primaryOutputId) as GeneratedAssetNode;
          primaryOutputNode.inputs.add(secondaryNode.id);

          graph.add(secondaryNode);
          expect(graph.get(secondaryId), secondaryNode);

          var changes = {primaryInputId: ChangeType.REMOVE};
          await graph.updateAndInvalidate(buildActions, changes, 'foo',
              (_) => new Future.value(null), digestReader);

          expect(graph.contains(primaryInputId), isFalse);
          expect(graph.contains(primaryOutputId), isFalse);
          expect(
              graph.get(secondaryId).outputs, isNot(contains(primaryOutputId)));
        });
      });
    });

    test('overlapping build actions cause an error', () async {
      expect(
          () => AssetGraph.build(
              new List.filled(2, new BuildAction(new CopyBuilder(), 'foo')),
              [makeAssetId('foo|file')].toSet(),
              'foo',
              digestReader),
          throwsA(duplicateAssetNodeException));
    });
  });
}

class MockDigestReader extends StubAssetReader with Md5DigestReader {
  @override
  Future<List<int>> readAsBytes(AssetId id) async => UTF8.encode('$id');
}
