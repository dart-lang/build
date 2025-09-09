// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_runner/src/bootstrap/apply_builders.dart';
import 'package:build_runner/src/build/asset_graph/build_definition.dart';
import 'package:build_runner/src/build_plan/build_options.dart';
import 'package:build_runner/src/build_plan/build_plan.dart';
import 'package:build_runner/src/build_plan/package_graph.dart';
import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:build_runner/src/constants.dart';
import 'package:build_runner/src/io/reader_writer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  group('BuildPlan', () {
    final rootPackage = 'a';
    final asset = AssetId(rootPackage, 'lib/a.dart');
    final assetGraphId = AssetId(rootPackage, assetGraphPath);
    late ReaderWriter readerWriter;
    late BuildOptions buildOptions;
    late TestingOverrides testingOverrides;

    setUp(() {
      final packageGraph = PackageGraph.fromRoot(
        PackageNode(
          rootPackage,
          '/$rootPackage',
          DependencyType.path,
          null,
          isRoot: true,
        ),
      );
      readerWriter = InternalTestReaderWriter(rootPackage: rootPackage);
      readerWriter.writeAsString(asset, '// a.dart');
      buildOptions = BuildOptions.forTests();
      testingOverrides = TestingOverrides(
        readerWriter: readerWriter,
        packageGraph: packageGraph,
      );
    });

    test('loads with no asset graph', () async {
      final buildPlan = await BuildPlan.load(
        builders: [applyToRoot(TestBuilder())].build(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      expect(buildPlan.takeAssetGraph(), null);
    });

    test('loads previous asset graph', () async {
      var buildPlan = await BuildPlan.load(
        builders: [applyToRoot(TestBuilder())].build(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      final assetGraph =
          (await BuildDefinition.prepareWorkspace(
            assetGraph: null,
            packageGraph: buildPlan.packageGraph,
            targetGraph: buildPlan.targetGraph,
            readerWriter: readerWriter,
            buildPhases: buildPlan.buildPhases,
            skipBuildScriptCheck: true,
          )).assetGraph;
      await readerWriter.writeAsBytes(assetGraphId, assetGraph.serialize());

      buildPlan = await BuildPlan.load(
        builders: [applyToRoot(TestBuilder())].build(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      final loadedGraph = buildPlan.takeAssetGraph();
      expect(loadedGraph.toString(), assetGraph.toString());
    });

    test('discards previous asset graph if build phases changed', () async {
      var buildPlan = await BuildPlan.load(
        builders: [applyToRoot(TestBuilder())].build(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      final assetGraph =
          (await BuildDefinition.prepareWorkspace(
            assetGraph: null,
            packageGraph: buildPlan.packageGraph,
            targetGraph: buildPlan.targetGraph,
            readerWriter: readerWriter,
            buildPhases: buildPlan.buildPhases,
            skipBuildScriptCheck: true,
          )).assetGraph;
      await readerWriter.writeAsBytes(assetGraphId, assetGraph.serialize());

      buildPlan = await BuildPlan.load(
        builders:
            [
              applyToRoot(TestBuilder()),
              // Apply a second builder so build phases change.
              applyToRoot(
                TestBuilder(buildExtensions: appendExtension('.copy2')),
              ),
            ].build(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );

      expect(buildPlan.takeAssetGraph(), null);

      // The old graph gets deleted when a new one is created.
      expect(await readerWriter.canRead(assetGraphId), true);
      await BuildDefinition.prepareWorkspace(
        assetGraph: null,
        packageGraph: buildPlan.packageGraph,
        targetGraph: buildPlan.targetGraph,
        readerWriter: readerWriter,
        buildPhases: buildPlan.buildPhases,
        skipBuildScriptCheck: true,
      );
      expect(await readerWriter.canRead(assetGraphId), false);
    });

    test('tracks lost outputs if build phases changed', () async {
      var buildPlan = await BuildPlan.load(
        builders:
            [
              applyToRoot(
                TestBuilder(),
                // Hidden output is easy to find and delete, it's under one
                // generated root. Unhide the output so there can be lost
                // outputs.
                hideOutput: false,
              ),
            ].build(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      final assetGraph =
          (await BuildDefinition.prepareWorkspace(
            assetGraph: null,
            packageGraph: buildPlan.packageGraph,
            targetGraph: buildPlan.targetGraph,
            readerWriter: readerWriter,
            buildPhases: buildPlan.buildPhases,
            skipBuildScriptCheck: true,
          )).assetGraph;
      // Write an output and add it to the asset graph as if it was built.
      final outputId = AssetId('a', 'lib/a.dart.copy');
      await readerWriter.writeAsString(outputId, '// output');
      assetGraph.updateNode(outputId, (b) {
        b.digest = Digest([]);
      });
      await readerWriter.writeAsBytes(assetGraphId, assetGraph.serialize());

      buildPlan = await BuildPlan.load(
        builders:
            [
              applyToRoot(TestBuilder()),
              // Apply a second builder so build phases change.
              applyToRoot(
                TestBuilder(buildExtensions: appendExtension('.copy2')),
              ),
            ].build(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );

      expect(buildPlan.takeAssetGraph(), null);
      expect(buildPlan.previousBuildOutputs, isNotEmpty);

      // `BuildPlan` can delete lost outputs.
      expect(await readerWriter.canRead(outputId), true);
      await buildPlan.deletePreviousBuildOutputs();
      expect(await readerWriter.canRead(outputId), false);
    });

    test('discards previous asset graph if SDK version changed', () async {
      var buildPlan = await BuildPlan.load(
        builders: [applyToRoot(TestBuilder())].build(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      final assetGraph =
          (await BuildDefinition.prepareWorkspace(
            assetGraph: null,
            packageGraph: buildPlan.packageGraph,
            targetGraph: buildPlan.targetGraph,
            readerWriter: readerWriter,
            buildPhases: buildPlan.buildPhases,
            skipBuildScriptCheck: true,
          )).assetGraph;
      await readerWriter.writeAsBytes(assetGraphId, assetGraph.serialize());

      buildPlan = await BuildPlan.load(
        builders:
            [
              applyToRoot(TestBuilder()),
              // Apply a second builder so build phases change.
              applyToRoot(
                TestBuilder(buildExtensions: appendExtension('.copy2')),
              ),
            ].build(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );

      expect(buildPlan.takeAssetGraph(), null);
    });

    test('discards previous asset graph if packages changed', () async {
      var buildPlan = await BuildPlan.load(
        builders: [applyToRoot(TestBuilder())].build(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      final assetGraph =
          (await BuildDefinition.prepareWorkspace(
            assetGraph: null,
            packageGraph: buildPlan.packageGraph,
            targetGraph: buildPlan.targetGraph,
            readerWriter: readerWriter,
            buildPhases: buildPlan.buildPhases,
            skipBuildScriptCheck: true,
          )).assetGraph;
      await readerWriter.writeAsBytes(assetGraphId, assetGraph.serialize());

      final packageGraph2 = PackageGraph.fromRoot(
        PackageNode('b', '/b', DependencyType.path, null, isRoot: true),
      );
      final testingOverrides2 = TestingOverrides(
        readerWriter: readerWriter,
        packageGraph: packageGraph2,
      );
      buildPlan = await BuildPlan.load(
        builders: [applyToRoot(TestBuilder())].build(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides2,
      );

      expect(buildPlan.takeAssetGraph(), null);
    });

    test(
      'discards previous asset graph if enabled experiments changed',
      () async {
        var buildPlan = await BuildPlan.load(
          builders: [applyToRoot(TestBuilder())].build(),
          buildOptions: buildOptions,
          testingOverrides: testingOverrides,
        );
        final assetGraph =
            (await BuildDefinition.prepareWorkspace(
              assetGraph: null,
              packageGraph: buildPlan.packageGraph,
              targetGraph: buildPlan.targetGraph,
              readerWriter: readerWriter,
              buildPhases: buildPlan.buildPhases,
              skipBuildScriptCheck: true,
            )).assetGraph;
        await readerWriter.writeAsBytes(assetGraphId, assetGraph.serialize());

        buildPlan = await withEnabledExperiments(
          () => BuildPlan.load(
            builders: [applyToRoot(TestBuilder())].build(),
            buildOptions: buildOptions,
            testingOverrides: testingOverrides,
          ),
          ['an_experiment'],
        );

        expect(buildPlan.takeAssetGraph(), null);
      },
    );
  });
}
