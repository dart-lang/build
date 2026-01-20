// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'package:build/build.dart';
import 'package:build_runner/src/build/asset_graph/graph.dart';
import 'package:build_runner/src/build/asset_graph/node.dart';
import 'package:build_runner/src/build/asset_graph/post_process_build_step_id.dart';
import 'package:build_runner/src/build_plan/build_configs.dart';
import 'package:build_runner/src/build_plan/build_directory.dart';
import 'package:build_runner/src/build_plan/build_filter.dart';
import 'package:build_runner/src/build_plan/build_options.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/build_plan/build_phases.dart';
import 'package:build_runner/src/build_plan/build_plan.dart';
import 'package:build_runner/src/build_plan/builder_factories.dart';
import 'package:build_runner/src/build_plan/phase.dart';
import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:build_runner/src/io/build_output_reader.dart';
import 'package:built_collection/built_collection.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  group('FinalizedReader', () {
    BuildOutputReader reader;
    late InternalTestReaderWriter readerWriter;
    late AssetGraph assetGraph;
    late BuildPackages buildPackages;
    late BuildPhases buildPhases;

    setUp(() async {
      readerWriter = InternalTestReaderWriter(outputRootPackage: 'a');
      buildPackages = BuildPackages.singlePackageBuild('a', [
        BuildPackage.forTesting(name: 'a', isOutput: true),
      ]);
      assetGraph = await AssetGraph.build(
        BuildPhases([]),
        <AssetId>{},
        buildPackages,
        readerWriter,
      );
      buildPhases = BuildPhases([]);
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

      readerWriter.testing.writeString(notDeleted.id, '');
      readerWriter.testing.writeString(deleted.id, '');

      final buildPlan = await BuildPlan.load(
        builderFactories: BuilderFactories({}),
        buildOptions: BuildOptions.forTests(),
        testingOverrides: TestingOverrides(
          buildPhases: buildPhases,
          readerWriter: readerWriter,
          buildPackages: buildPackages,
        ),
      );
      reader = BuildOutputReader(
        buildPlan: buildPlan,
        readerWriter: readerWriter,
        assetGraph: assetGraph,
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
      readerWriter.testing.writeString(id, '');

      buildPhases = BuildPhases([
        InBuildPhase(
          builder: TestBuilder(),
          key: 'TestBuilder',
          package: 'a',
          isOptional: false,
        ),
      ]);

      var buildPlan = await BuildPlan.load(
        builderFactories: BuilderFactories({}),
        buildOptions: BuildOptions.forTests(
          buildDirs: {BuildDirectory('web')}.build(),
        ),
        testingOverrides: TestingOverrides(
          buildPhases: buildPhases,
          defaultRootPackageSources: defaultDependencyVisibleAssets,
          readerWriter: readerWriter,
          buildPackages: buildPackages,
        ),
      );
      reader = BuildOutputReader(
        buildPlan: buildPlan,
        readerWriter: readerWriter,
        assetGraph: assetGraph,
      );
      expect(
        await reader.unreadableReason(id),
        UnreadableReason.failed,
        reason: 'Should report a failure if no build filters apply',
      );

      buildPlan = await BuildPlan.load(
        builderFactories: BuilderFactories({}),
        buildOptions: BuildOptions.forTests(
          buildDirs: {BuildDirectory('web')}.build(),
          buildFilters: {BuildFilter(Glob('b'), Glob('foo'))}.build(),
        ),
        testingOverrides: TestingOverrides(
          buildPhases: buildPhases,
          defaultRootPackageSources: defaultDependencyVisibleAssets,
          readerWriter: readerWriter,
          buildPackages: buildPackages,
        ),
      );
      reader = BuildOutputReader(
        buildPlan: buildPlan,
        readerWriter: readerWriter,
        assetGraph: assetGraph,
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
