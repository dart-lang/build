// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:build_runner/src/asset_graph/graph.dart';
import 'package:build_runner/src/asset_graph/node.dart';
import 'package:build_runner/src/builder/run_post_process_builder.dart';
import 'package:build_runner/src/generate/phase.dart';

import '../common/common.dart';

main() {
  group('runPostProcessBuilder', () {
    InMemoryAssetReader reader;
    InMemoryAssetWriter writer;
    final copyBuilder = new CopyingPostProcessBuilder();
    final deleteBuilder = new DeletePostProcessBuilder();
    final aTxt = makeAssetId('a|lib/a.txt');
    final aTxtCopy = makeAssetId('a|lib/a.txt.copy');
    final logger = new Logger('test');
    AssetGraph assetGraph;
    Map<AssetId, String> sourceAssets;
    final packageGraph = buildPackageGraph({rootPackage('a'): []});
    final buildPhases = [
      new PostBuildPhase([
        new PostBuildAction(copyBuilder, 'a',
            builderOptions: null, generateFor: null, targetSources: null),
        new PostBuildAction(deleteBuilder, 'b',
            builderOptions: null, targetSources: null, generateFor: null)
      ])
    ];
    PostProcessAnchorNode anchorNode;

    setUp(() async {
      sourceAssets = {
        aTxt: 'a',
      };
      reader = new InMemoryAssetReader(sourceAssets: sourceAssets);
      writer = new InMemoryAssetWriter();
      assetGraph = await AssetGraph.build(buildPhases,
          sourceAssets.keys.toSet(), new Set<AssetId>(), packageGraph, reader);
      anchorNode = assetGraph.packageNodes('a').firstWhere(
              (n) => n is PostProcessAnchorNode && n.primaryInput == aTxt)
          as PostProcessAnchorNode;
    });

    test('can delete assets', () async {
      await runPostProcessBuilder(
          copyBuilder, aTxt, reader, writer, logger, assetGraph, anchorNode, 0);
      await runPostProcessBuilder(deleteBuilder, aTxt, reader, writer, logger,
          assetGraph, anchorNode, 0);
      expect(assetGraph.get(aTxt).isDeleted, isTrue);
      expect(assetGraph.get(aTxtCopy).isDeleted, isFalse);
    });

    test('can create assets and read the primary asset', () async {
      await runPostProcessBuilder(
          copyBuilder, aTxt, reader, writer, logger, assetGraph, anchorNode, 0);
      expect(writer.assets, contains(aTxtCopy));
      expect(writer.assets[aTxtCopy], decodedMatches('a'));
    });

    test('throws if you try to output a pre-existing asset', () async {
      assetGraph.add(new SourceAssetNode(aTxtCopy));
      expect(
          () => runPostProcessBuilder(copyBuilder, aTxt, reader, writer, logger,
              assetGraph, anchorNode, 0),
          throwsA(new isInstanceOf<InvalidOutputException>()));
    });
  });
}
