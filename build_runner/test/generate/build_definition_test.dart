// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import 'package:build_runner/build_runner.dart';
import 'package:build_runner/src/asset_graph/graph.dart';
import 'package:build_runner/src/asset_graph/node.dart';
import 'package:build_runner/src/generate/build_definition.dart';
import 'package:build_runner/src/generate/options.dart';
import 'package:build_runner/src/package_graph/package_graph.dart';
import 'package:build_runner/src/util/constants.dart';

import '../common/common.dart';

main() {
  group('BuildDefinition.load', () {
    Map<AssetId, DatedValue> assets;
    BuildOptions options;

    setUp(() {
      assets = <AssetId, DatedValue>{};
      var assetReader = new InMemoryRunnerAssetReader(assets, 'a');
      var assetWriter = new InMemoryRunnerAssetWriter();
      var packageA = new PackageNode.noPubspec('a');
      var packageGraph = new PackageGraph.fromRoot(packageA);
      options = new BuildOptions(
          reader: assetReader,
          writer: assetWriter,
          packageGraph: packageGraph,
          logLevel: Level.OFF,
          writeToCache: true);
    });

    group('updates', () {
      test('contains deleted outputs as remove events', () async {
        var lastBuild = new DateTime.now();
        assets[makeAssetId('a|lib/test.txt')] =
            new DatedString('a', lastBuild.subtract(new Duration(seconds: 1)));
        var buildActions = [new BuildAction(new CopyBuilder(), 'a')];

        var assetGraph = new AssetGraph.build(buildActions, assets.keys.toSet())
          ..validAsOf = new DateTime.now();
        var generatedSrcId = makeAssetId('a|lib/test.txt.copy');
        var generatedNode =
            assetGraph.get(generatedSrcId) as GeneratedAssetNode;
        generatedNode.wasOutput = true;

        assets[makeAssetId('a|$assetGraphPath')] =
            new DatedString(JSON.encode(assetGraph.serialize()));

        var buildDefinition = await BuildDefinition.load(options, buildActions);
        expect(buildDefinition.updates.keys, [generatedSrcId]);
        expect(buildDefinition.updates[generatedSrcId], ChangeType.REMOVE);
      });

      test('ignores non-output generated nodes', () async {
        var lastBuild = new DateTime.now();
        assets[makeAssetId('a|lib/test.txt')] =
            new DatedString('a', lastBuild.subtract(new Duration(seconds: 1)));
        var buildActions = [
          new BuildAction(new OverDeclaringCopyBuilder(), 'a')
        ];

        var assetGraph = new AssetGraph.build(buildActions, assets.keys.toSet())
          ..validAsOf = lastBuild;
        var generatedSrcId = makeAssetId('a|lib/test.txt.copy');
        var generatedNode =
            assetGraph.get(generatedSrcId) as GeneratedAssetNode;
        generatedNode.wasOutput = false;

        assets[makeAssetId('a|$assetGraphPath')] =
            new DatedString(JSON.encode(assetGraph.serialize()));

        var buildDefinition = await BuildDefinition.load(options, buildActions);
        expect(buildDefinition.updates, isEmpty);
      });
    });

    group('assetGraph', () {
      test('doesn\'t capture unrecognized cacheDir files as inputs', () async {
        assets[makeAssetId('a|$generatedOutputDirectory/a/lib/test.txt')] =
            new DatedString('a');
        var buildActions = [new BuildAction(new CopyBuilder(), 'a')];

        var assetGraph = new AssetGraph.build(buildActions, new Set<AssetId>())
          ..validAsOf = new DateTime.now();
        expect(assetGraph.allNodes, isEmpty);

        assets[makeAssetId('a|$assetGraphPath')] =
            new DatedString(JSON.encode(assetGraph.serialize()));

        var buildDefinition = await BuildDefinition.load(options, buildActions);
        expect(buildDefinition.updates, isEmpty);
        expect(buildDefinition.assetGraph.allNodes, isEmpty);
      });
    });
  });
}
