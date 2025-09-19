// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'package:build/build.dart';
import 'package:build_runner/src/build/asset_graph/graph.dart';
import 'package:build_runner/src/build/asset_graph/node.dart';
import 'package:build_runner/src/build/asset_graph/post_process_build_step_id.dart';
import 'package:build_runner/src/build/optional_output_tracker.dart';
import 'package:build_runner/src/build_plan/build_filter.dart';
import 'package:build_runner/src/build_plan/build_phases.dart';
import 'package:build_runner/src/build_plan/phase.dart';
import 'package:build_runner/src/build_plan/target_graph.dart';
import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:build_runner/src/io/finalized_reader.dart';
import 'package:built_collection/built_collection.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  group('FinalizedReader', () {
    FinalizedReader reader;
    late AssetGraph assetGraph;
    late TargetGraph targetGraph;
    late OptionalOutputTracker optionalOutputTracker;
    late BuildPhases buildPhases;

    setUp(() async {
      final packageGraph = buildPackageGraph({rootPackage('a'): []});
      targetGraph = await TargetGraph.forPackageGraph(
        packageGraph: packageGraph,
        testingOverrides: TestingOverrides(
          defaultRootPackageSources: defaultNonRootVisibleAssets,
        ),
      );
      assetGraph = await AssetGraph.build(
        BuildPhases([]),
        <AssetId>{},
        <AssetId>{},
        packageGraph,
        InternalTestReaderWriter(),
      );
      buildPhases = BuildPhases([]);
      optionalOutputTracker = OptionalOutputTracker(
        assetGraph,
        targetGraph,
        BuiltSet(),
        BuiltSet(),
        buildPhases,
      );
    });

    test('can not read deleted files', () async {
      final notDeleted = AssetNode.source(
        AssetId.parse('a|web/a.txt'),
        digest: computeDigest(AssetId('a', 'web/a.txt'), 'a'),
      );
      var deleted = AssetNode.source(
        AssetId.parse('a|lib/b.txt'),
        digest: computeDigest(AssetId('a', 'lib/b.txt'), 'b'),
      );

      deleted = deleted.rebuild(
        (b) =>
            b
              ..deletedBy.add(
                PostProcessBuildStepId(input: notDeleted.id, actionNumber: 0),
              ),
      );

      assetGraph
        ..add(notDeleted)
        ..add(deleted);

      final readerWriter = InternalTestReaderWriter();
      readerWriter.testing.writeString(notDeleted.id, '');
      readerWriter.testing.writeString(deleted.id, '');

      reader = FinalizedReader(
        readerWriter: readerWriter,
        assetGraph: assetGraph,
        optionalOutputTracker: optionalOutputTracker,
      );
      expect(await reader.canRead(notDeleted.id), true);
      expect(await reader.canRead(deleted.id), false);
    });

    test('Failure nodes interact well with build filters ', () async {
      final id = AssetId('a', 'web/a.txt');
      final node = AssetNode.generated(
        id,
        phaseNumber: 0,
        result: false,
        digest: Digest([]),
        primaryInput: AssetId('a', 'web/a.dart'),
        isHidden: true,
      );
      assetGraph.add(node);
      final readerWriter = InternalTestReaderWriter();
      readerWriter.testing.writeString(id, '');

      buildPhases = BuildPhases([
        InBuildPhase(TestBuilder(), 'a', isOptional: false),
      ]);

      optionalOutputTracker = OptionalOutputTracker(
        assetGraph,
        targetGraph,
        BuiltSet({'web'}.build()),
        BuiltSet(),
        buildPhases,
      );
      reader = FinalizedReader(
        readerWriter: readerWriter,
        assetGraph: assetGraph,
        optionalOutputTracker: optionalOutputTracker,
      );
      expect(
        await reader.unreadableReason(id),
        UnreadableReason.failed,
        reason: 'Should report a failure if no build filters apply',
      );

      optionalOutputTracker = OptionalOutputTracker(
        assetGraph,
        targetGraph,
        BuiltSet({'web'}.build()),
        {BuildFilter(Glob('b'), Glob('foo'))}.build(),
        buildPhases,
      );
      reader = FinalizedReader(
        readerWriter: readerWriter,
        assetGraph: assetGraph,
        optionalOutputTracker: optionalOutputTracker,
      );

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
