// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';

import 'package:build/build.dart';
import 'package:build/src/asset_graph/graph.dart';
import 'package:build/src/asset_graph/node.dart';

import '../common/common.dart';

main() {
  /// Basic phases/phase groups which get used in many tests
  final aFiles = new InputSet('a', ['**/*']);
  final copyAPhase = new Phase()..addAction(new CopyBuilder(), aFiles);
  final copyAPhaseGroup = new PhaseGroup()..addPhase(copyAPhase);

  group('build', () {
    group('with root package inputs', () {
      test('one phase, one builder, one-to-one outputs', () async {
        await testPhases(
            copyAPhaseGroup, {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
            outputs: {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'});
      });

      test('one phase, one builder, one-to-many outputs', () async {
        var phases =
            new PhaseGroup.singleAction(new CopyBuilder(numCopies: 2), aFiles);
        await testPhases(phases, {
          'a|web/a.txt': 'a',
          'a|lib/b.txt': 'b',
        }, outputs: {
          'a|web/a.txt.copy.0': 'a',
          'a|web/a.txt.copy.1': 'a',
          'a|lib/b.txt.copy.0': 'b',
          'a|lib/b.txt.copy.1': 'b',
        });
      });

      test('one phase, multiple builders', () async {
        var phases = new PhaseGroup();
        phases.newPhase()
          ..addAction(new CopyBuilder(), aFiles)
          ..addAction(new CopyBuilder(extension: 'clone'), aFiles)
          ..addAction(new CopyBuilder(numCopies: 2), aFiles);

        await testPhases(phases, {
          'a|web/a.txt': 'a',
          'a|lib/b.txt': 'b',
        }, outputs: {
          'a|web/a.txt.copy': 'a',
          'a|web/a.txt.clone': 'a',
          'a|lib/b.txt.copy': 'b',
          'a|lib/b.txt.clone': 'b',
          'a|web/a.txt.copy.0': 'a',
          'a|web/a.txt.copy.1': 'a',
          'a|lib/b.txt.copy.0': 'b',
          'a|lib/b.txt.copy.1': 'b',
        });
      });

      test('multiple phases, multiple builders', () async {
        var phases = new PhaseGroup();
        phases.addPhase(copyAPhase);
        phases.newPhase().addAction(new CopyBuilder(extension: 'clone'),
            new InputSet('a', ['**/*.txt']));
        phases.newPhase().addAction(new CopyBuilder(numCopies: 2),
            new InputSet('a', ['web/*.txt.clone']));

        await testPhases(phases, {
          'a|web/a.txt': 'a',
          'a|lib/b.txt': 'b',
        }, outputs: {
          'a|web/a.txt.copy': 'a',
          'a|web/a.txt.clone': 'a',
          'a|lib/b.txt.copy': 'b',
          'a|lib/b.txt.clone': 'b',
          'a|web/a.txt.clone.copy.0': 'a',
          'a|web/a.txt.clone.copy.1': 'a',
        });
      });
    });

    group('inputs from other packages', () {
      test('only gets inputs from lib, can output to root package', () async {
        var phases = new PhaseGroup.singleAction(
            new CopyBuilder(outputPackage: 'a'), new InputSet('b', ['**/*']));

        await testPhases(phases, {'b|web/b.txt': 'b', 'b|lib/b.txt': 'b'},
            outputs: {'a|lib/b.txt.copy': 'b'});
      });

      test('can\'t output files in non-root packages', () async {
        var phases = new PhaseGroup.singleAction(
            new CopyBuilder(), new InputSet('b', ['**/*']));

        await testPhases(phases, {'b|lib/b.txt': 'b'},
            outputs: {}, status: BuildStatus.Failure);
      });
    });

    test('multiple phases, inputs from multiple packages', () async {
      var phases = new PhaseGroup();
      phases.newPhase()
        ..addAction(new CopyBuilder(), aFiles)
        ..addAction(new CopyBuilder(extension: 'clone', outputPackage: 'a'),
            new InputSet('b', ['**/*.txt']));
      var twoCopyBuilder = new CopyBuilder(numCopies: 2, outputPackage: 'a');
      phases.newPhase()
        ..addAction(twoCopyBuilder, new InputSet('a', ['lib/*.txt.*']))
        ..addAction(twoCopyBuilder, new InputSet('b', ['**/*.dart']));

      await testPhases(phases, {
        'a|web/1.txt': '1',
        'a|lib/2.txt': '2',
        'b|lib/3.txt': '3',
        'b|lib/b.dart': 'main() {}',
      }, outputs: {
        'a|web/1.txt.copy': '1',
        'a|lib/2.txt.copy': '2',
        'a|lib/3.txt.clone': '3',
        'a|lib/2.txt.copy.copy.0': '2',
        'a|lib/2.txt.copy.copy.1': '2',
        'a|lib/3.txt.clone.copy.0': '3',
        'a|lib/3.txt.clone.copy.1': '3',
        'a|lib/b.dart.copy.0': 'main() {}',
        'a|lib/b.dart.copy.1': 'main() {}',
      });
    });
  });

  group('errors', () {
    test('when overwriting files', () async {
      var emptyGraph = new AssetGraph();
      await testPhases(
          copyAPhaseGroup,
          {
            'a|lib/a.txt': 'a',
            'a|lib/a.txt.copy': 'a',
            'a|.build/asset_graph.json': JSON.encode(emptyGraph.serialize()),
          },
          status: BuildStatus.Failure,
          exceptionMatcher: invalidOutputException);
    });
  });

  test('tracks dependency graph in a asset_graph.json file', () async {
    final writer = new InMemoryAssetWriter();
    await testPhases(copyAPhaseGroup, {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
        outputs: {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'},
        writer: writer);

    var graphId = makeAssetId('a|.build/asset_graph.json');
    expect(writer.assets, contains(graphId));
    var cachedGraph =
        new AssetGraph.deserialize(JSON.decode(writer.assets[graphId].value));

    var expectedGraph = new AssetGraph();
    var aCopyNode = makeAssetNode('a|web/a.txt.copy');
    expectedGraph.add(aCopyNode);
    expectedGraph.add(makeAssetNode('a|web/a.txt', [aCopyNode.id]));
    var bCopyNode = makeAssetNode('a|lib/b.txt.copy');
    expectedGraph.add(bCopyNode);
    expectedGraph.add(makeAssetNode('a|lib/b.txt', [bCopyNode.id]));

    expect(cachedGraph, equalsAssetGraph(expectedGraph));
  });

  test('outputs from previous full builds shouldn\'t be inputs to later ones',
      () async {
    final writer = new InMemoryAssetWriter();
    var inputs = {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'};
    var outputs = {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'};
    // First run, nothing special.
    await testPhases(copyAPhaseGroup, inputs, outputs: outputs, writer: writer);
    // Second run, should have no extra outputs.
    await testPhases(copyAPhaseGroup, inputs, outputs: outputs, writer: writer);
  });

  test('can recover from a deleted asset_graph.json cache', () async {
    final writer = new InMemoryAssetWriter();
    var inputs = {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'};
    var outputs = {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'};
    // First run, nothing special.
    await testPhases(copyAPhaseGroup, inputs, outputs: outputs, writer: writer);

    // Delete the `asset_graph.json` file!
    var outputId = makeAssetId('a|.build/asset_graph.json');
    await writer.delete(outputId);

    // Second run, should have no extra outputs.
    var done =
        testPhases(copyAPhaseGroup, inputs, outputs: outputs, writer: writer);
    // Should block on user input.
    await new Future.delayed(new Duration(seconds: 1));
    // Now it should complete!
    await done;
  }, skip: 'Need to manually add a `y` to stdin for this test to run.');

  group('incremental builds with cached graph', () {
    test('one new asset, one modified asset, one unchanged asset', () async {
      var graph = new AssetGraph();
      var bId = makeAssetId('a|lib/b.txt');
      var bCopyNode = new GeneratedAssetNode(
          bId, false, true, makeAssetId('a|lib/b.txt.copy'));
      graph.add(bCopyNode);
      var bNode = makeAssetNode('a|lib/b.txt', [bCopyNode.id]);
      graph.add(bNode);

      var writer = new InMemoryAssetWriter();
      writer.writeAsString(makeAsset('a|lib/b.txt', 'b'),
          lastModified: graph.validAsOf.subtract(new Duration(hours: 1)));
      await testPhases(copyAPhaseGroup, {
        'a|web/a.txt': 'a',
        'a|lib/b.txt.copy': 'b',
        'a|lib/c.txt': 'c',
        'a|.build/asset_graph.json': JSON.encode(graph.serialize()),
      }, outputs: {
        'a|web/a.txt.copy': 'a',
        'a|lib/c.txt.copy': 'c',
      });
    });

    test('invalidates generated assets based on graph age', () async {
      var phases = new PhaseGroup();
      phases.addPhase(copyAPhase);
      phases.newPhase()
        ..addAction(new CopyBuilder(extension: 'clone'),
            new InputSet('a', ['**/*.txt.copy']));

      var graph = new AssetGraph()..validAsOf = new DateTime.now();

      var aCloneNode = new GeneratedAssetNode(makeAssetId('a|lib/a.txt.copy'),
          false, true, makeAssetId('a|lib/a.txt.copy.clone'));
      graph.add(aCloneNode);
      var aCopyNode = new GeneratedAssetNode(makeAssetId('a|lib/a.txt'), false,
          true, makeAssetId('a|lib/a.txt.copy'))..outputs.add(aCloneNode.id);
      graph.add(aCopyNode);
      var aNode = makeAssetNode('a|lib/a.txt', [aCopyNode.id]);
      graph.add(aNode);

      var bCloneNode = new GeneratedAssetNode(makeAssetId('a|lib/b.txt.copy'),
          false, true, makeAssetId('a|lib/b.txt.copy.clone'));
      graph.add(bCloneNode);
      var bCopyNode = new GeneratedAssetNode(makeAssetId('a|lib/b.txt'), false,
          true, makeAssetId('a|lib/b.txt.copy'))..outputs.add(bCloneNode.id);
      graph.add(bCopyNode);
      var bNode = makeAssetNode('a|lib/b.txt', [bCopyNode.id]);
      graph.add(bNode);

      var writer = new InMemoryAssetWriter();
      writer.writeAsString(makeAsset('a|lib/b.txt', 'b'),
          lastModified: graph.validAsOf.subtract(new Duration(days: 1)));
      await testPhases(
          phases,
          {
            'a|lib/a.txt': 'b',
            'a|lib/a.txt.copy': 'a',
            'a|lib/a.txt.copy.clone': 'a',
            'a|lib/b.txt.copy': 'b',
            'a|lib/b.txt.copy.clone': 'b',
            'a|.build/asset_graph.json': JSON.encode(graph.serialize()),
          },
          outputs: {'a|lib/a.txt.copy': 'b', 'a|lib/a.txt.copy.clone': 'b',},
          writer: writer);
    });

    test('graph/file system get cleaned up for deleted inputs', () async {
      var phases = new PhaseGroup();
      phases.addPhase(copyAPhase);
      phases.newPhase()
        ..addAction(new CopyBuilder(extension: 'clone'),
            new InputSet('a', ['**/*.txt.copy']));

      var graph = new AssetGraph();
      var aCloneNode = new GeneratedAssetNode(makeAssetId('a|lib/a.txt.copy'),
          false, true, makeAssetId('a|lib/a.txt.copy.clone'));
      graph.add(aCloneNode);
      var aCopyNode = new GeneratedAssetNode(makeAssetId('a|lib/a.txt'), false,
          true, makeAssetId('a|lib/a.txt.copy'))..outputs.add(aCloneNode.id);
      graph.add(aCopyNode);
      var aNode = makeAssetNode('a|lib/a.txt', [aCopyNode.id]);
      graph.add(aNode);

      var writer = new InMemoryAssetWriter();
      await testPhases(
          phases,
          {
            'a|lib/a.txt.copy': 'a',
            'a|lib/a.txt.copy.clone': 'a',
            'a|.build/asset_graph.json': JSON.encode(graph.serialize()),
          },
          outputs: {},
          writer: writer);

      /// Should be deleted using the writer, and removed from the new graph.
      var newGraph = new AssetGraph.deserialize(JSON.decode(
          writer.assets[makeAssetId('a|.build/asset_graph.json')].value));
      expect(newGraph.contains(aNode.id), isFalse);
      expect(newGraph.contains(aCopyNode.id), isFalse);
      expect(newGraph.contains(aCloneNode.id), isFalse);
      expect(writer.assets.containsKey(aNode.id), isFalse);
      expect(writer.assets.containsKey(aCopyNode.id), isFalse);
      expect(writer.assets.containsKey(aCloneNode.id), isFalse);
    });

    test('invalidates graph if build script updates', () async {
      var graph = new AssetGraph();
      var aId = makeAssetId('a|web/a.txt');
      var aCopyNode = new GeneratedAssetNode(
          aId, false, true, makeAssetId('a|web/a.txt.copy'));
      graph.add(aCopyNode);
      var aNode = makeAssetNode('a|web/a.txt', [aCopyNode.id]);
      graph.add(aNode);

      var writer = new InMemoryAssetWriter();

      /// Spoof the `package:test/test.dart` import and pretend its newer than
      /// the current graph to cause a rebuild.
      writer.writeAsString(makeAsset('test|lib/test.dart', ''),
          lastModified: graph.validAsOf.add(new Duration(hours: 1)));
      await testPhases(copyAPhaseGroup, {
        'a|web/a.txt': 'a',
        'a|web/a.txt.copy': 'a',
        'a|.build/asset_graph.json': JSON.encode(graph.serialize()),
      }, outputs: {
        'a|web/a.txt.copy': 'a',
      });
    });
  });
}
