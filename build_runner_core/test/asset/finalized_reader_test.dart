// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'package:_test_common/common.dart';
import 'package:build/build.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'package:build_runner_core/src/asset_graph/post_process_build_step_id.dart';
import 'package:build_runner_core/src/generate/build_phases.dart';
import 'package:build_runner_core/src/generate/options.dart';
import 'package:build_runner_core/src/generate/phase.dart';
import 'package:build_runner_core/src/package_graph/target_graph.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

void main() {
  group('FinalizedReader', () {
    FinalizedReader reader;
    late AssetGraph graph;
    late TargetGraph targetGraph;

    setUp(() async {
      final packageGraph = buildPackageGraph({rootPackage('a'): []});
      targetGraph = await TargetGraph.forPackageGraph(
        packageGraph,
        defaultRootPackageSources: defaultNonRootVisibleAssets,
      );

      graph = await AssetGraph.build(
        BuildPhases([]),
        <AssetId>{},
        <AssetId>{},
        packageGraph,
        TestReaderWriter(),
      );
    });

    test('can not read deleted files', () async {
      var notDeleted = makeAssetNode(
        'a|web/a.txt',
        [],
        computeDigest(AssetId('a', 'web/a.txt'), 'a'),
      );
      var deleted = makeAssetNode(
        'a|lib/b.txt',
        [],
        computeDigest(AssetId('a', 'lib/b.txt'), 'b'),
      );

      deleted = deleted.rebuild(
        (b) =>
            b
              ..deletedBy.add(
                PostProcessBuildStepId(input: notDeleted.id, actionNumber: 0),
              ),
      );

      graph
        ..add(notDeleted)
        ..add(deleted);

      var delegate = TestReaderWriter();
      delegate.testing.writeString(notDeleted.id, '');
      delegate.testing.writeString(deleted.id, '');

      reader = FinalizedReader(
        delegate,
        graph,
        targetGraph,
        BuildPhases([]),
        'a',
      );
      expect(await reader.canRead(notDeleted.id), true);
      expect(await reader.canRead(deleted.id), false);
    });

    test('Failure nodes interact well with build filters ', () async {
      var id = AssetId('a', 'web/a.txt');
      var node = AssetNode.generated(
        id,
        phaseNumber: 0,
        result: false,
        digest: Digest([]),
        primaryInput: AssetId('a', 'web/a.dart'),
        isHidden: true,
      );
      graph.add(node);
      var delegate = TestReaderWriter();
      delegate.testing.writeString(id, '');
      reader = FinalizedReader(
        delegate,
        graph,
        targetGraph,
        BuildPhases([InBuildPhase(TestBuilder(), 'a', isOptional: false)]),
        'a',
      )..reset({'web'}, {});
      expect(
        await reader.unreadableReason(id),
        UnreadableReason.failed,
        reason: 'Should report a failure if no build filters apply',
      );

      reader.reset({'web'}, {BuildFilter(Glob('b'), Glob('foo'))});
      expect(
        await reader.unreadableReason(id),
        UnreadableReason.notOutput,
        reason:
            'Should report as not output if it doesn\'t match requested '
            'build filters',
      );
    });
  });
}
