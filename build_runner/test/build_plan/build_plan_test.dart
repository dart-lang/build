// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/src/build_plan/apply_builders.dart';
import 'package:build_runner/src/build_plan/build_options.dart';
import 'package:build_runner/src/build_plan/build_plan.dart';
import 'package:build_runner/src/build_plan/builder_factories.dart';
import 'package:build_runner/src/build_plan/package_graph.dart';
import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:build_runner/src/constants.dart';
import 'package:build_runner/src/io/reader_writer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import '../common/common.dart';

void main() {
  group('BuildPlan', () {
    final rootPackage = 'a';
    final assetId = AssetId(rootPackage, 'lib/a.dart');
    final outputId = AssetId('a', 'lib/a.dart.copy');
    final assetId2 = AssetId(rootPackage, 'lib/an.other');
    final assetGraphId = AssetId(rootPackage, assetGraphPath);

    late PackageGraph packageGraph;
    late ReaderWriter readerWriter;
    late BuildOptions buildOptions;
    late TestingOverrides testingOverrides;

    setUp(() {
      packageGraph = PackageGraph.fromRoot(
        PackageNode(
          rootPackage,
          '/$rootPackage',
          DependencyType.path,
          null,
          isRoot: true,
        ),
      );
      readerWriter = InternalTestReaderWriter(rootPackage: rootPackage);
      readerWriter.writeAsString(assetId, '// a.dart');
      readerWriter.writeAsString(assetId2, '// other');
      buildOptions = BuildOptions.forTests(
        // Script check doesn't work in tests, skip it.
        skipBuildScriptCheck: true,
      );
      testingOverrides = TestingOverrides(
        builderApplications: [applyToRoot(TestBuilder())].build(),
        readerWriter: readerWriter,
        packageGraph: packageGraph,
      );
    });

    test('loads with no asset graph', () async {
      final buildPlan = await BuildPlan.load(
        builderFactories: BuilderFactories(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      expect(buildPlan.takePreviousAssetGraph(), null);
    });

    test('loads previous asset graph', () async {
      var buildPlan = await BuildPlan.load(
        builderFactories: BuilderFactories(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      final assetGraph = buildPlan.takeAssetGraph();
      await readerWriter.writeAsBytes(assetGraphId, assetGraph.serialize());

      buildPlan = await BuildPlan.load(
        builderFactories: BuilderFactories(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      final loadedGraph = buildPlan.takePreviousAssetGraph();
      expect(loadedGraph.toString(), assetGraph.toString());
    });

    test('discards previous asset graph if build phases changed', () async {
      var buildPlan = await BuildPlan.load(
        builderFactories: BuilderFactories(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      final assetGraph = buildPlan.takeAssetGraph();
      await readerWriter.writeAsBytes(assetGraphId, assetGraph.serialize());

      buildPlan = await BuildPlan.load(
        builderFactories: BuilderFactories(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides.copyWith(
          builderApplications:
              [
                applyToRoot(TestBuilder()),
                // Apply a second builder so build phases change.
                applyToRoot(
                  TestBuilder(buildExtensions: appendExtension('.copy2')),
                ),
              ].build(),
        ),
      );

      expect(buildPlan.takePreviousAssetGraph(), null);

      // The old graph is in [BuildPlan#filesToDelete] because it's invalid.
      expect(await readerWriter.canRead(assetGraphId), true);
      await buildPlan.deleteFilesAndFolders();
      expect(await readerWriter.canRead(assetGraphId), false);
    });

    test('tracks lost outputs if build phases changed', () async {
      var buildPlan = await BuildPlan.load(
        builderFactories: BuilderFactories(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides.copyWith(
          builderApplications:
              [
                applyToRoot(
                  TestBuilder(),
                  // Hidden output is easy to find and delete, it's under one
                  // generated root. Unhide the output so there can be lost
                  // outputs.
                  hideOutput: false,
                ),
              ].build(),
        ),
      );
      final assetGraph = buildPlan.takeAssetGraph();

      // Write an output and add it to the asset graph as if it was built.
      await readerWriter.writeAsString(outputId, '// output');
      assetGraph.updateNode(outputId, (b) {
        b.digest = Digest([]);
      });
      await readerWriter.writeAsBytes(assetGraphId, assetGraph.serialize());

      buildPlan = await BuildPlan.load(
        builderFactories: BuilderFactories(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides.copyWith(
          builderApplications:
              [
                applyToRoot(TestBuilder()),
                // Apply a second builder so build phases change.
                applyToRoot(
                  TestBuilder(buildExtensions: appendExtension('.copy2')),
                ),
              ].build(),
        ),
      );

      expect(buildPlan.takePreviousAssetGraph(), null);
      expect(buildPlan.filesToDelete, isNotEmpty);

      // `BuildPlan` can delete lost outputs.
      expect(await readerWriter.canRead(outputId), true);
      await buildPlan.deleteFilesAndFolders();
      expect(await readerWriter.canRead(outputId), false);
    });

    test('discards previous asset graph if SDK version changed', () async {
      var buildPlan = await BuildPlan.load(
        builderFactories: BuilderFactories(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      final assetGraph = buildPlan.takeAssetGraph();
      await readerWriter.writeAsBytes(assetGraphId, assetGraph.serialize());

      buildPlan = await BuildPlan.load(
        builderFactories: BuilderFactories(),

        buildOptions: buildOptions,
        testingOverrides: testingOverrides.copyWith(
          builderApplications:
              [
                applyToRoot(TestBuilder()),
                // Apply a second builder so build phases change.
                applyToRoot(
                  TestBuilder(buildExtensions: appendExtension('.copy2')),
                ),
              ].build(),
        ),
      );

      expect(buildPlan.takePreviousAssetGraph(), null);
    });

    test('discards previous asset graph if packages changed', () async {
      var buildPlan = await BuildPlan.load(
        builderFactories: BuilderFactories(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      final assetGraph = buildPlan.takeAssetGraph();
      await readerWriter.writeAsBytes(assetGraphId, assetGraph.serialize());

      final packageGraph2 = PackageGraph.fromRoot(
        PackageNode('b', '/b', DependencyType.path, null, isRoot: true),
      );
      final testingOverrides2 = testingOverrides.copyWith(
        packageGraph: packageGraph2,
      );
      buildPlan = await BuildPlan.load(
        builderFactories: BuilderFactories(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides2,
      );

      expect(buildPlan.takePreviousAssetGraph(), null);
    });

    test(
      'discards previous asset graph if enabled experiments changed',
      () async {
        var buildPlan = await BuildPlan.load(
          builderFactories: BuilderFactories(),
          buildOptions: buildOptions,
          testingOverrides: testingOverrides,
        );
        final assetGraph = buildPlan.takeAssetGraph();
        await readerWriter.writeAsBytes(assetGraphId, assetGraph.serialize());

        buildPlan = await withEnabledExperiments(
          () => BuildPlan.load(
            builderFactories: BuilderFactories(),
            buildOptions: buildOptions,
            testingOverrides: testingOverrides,
          ),
          ['an_experiment'],
        );

        expect(buildPlan.takePreviousAssetGraph(), null);
      },
    );

    test('reports updates', () async {
      var buildPlan = await BuildPlan.load(
        builderFactories: BuilderFactories(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );
      final assetGraph = buildPlan.takeAssetGraph();

      // Write an output and add it to the asset graph as if it was built.
      await readerWriter.writeAsString(outputId, '// output');
      assetGraph.updateNode(outputId, (b) {
        b.digest = Digest([]);
      });

      await readerWriter.writeAsBytes(assetGraphId, assetGraph.serialize());

      // Remove source.
      await readerWriter.delete(assetId);
      // Change source.
      await readerWriter.writeAsString(assetId2, 'changed');
      // Add source.
      final assetId3 = AssetId(rootPackage, 'lib/new.dart');
      await readerWriter.writeAsString(assetId3, '');

      // Remove generated.
      await readerWriter.delete(outputId);

      buildPlan = await BuildPlan.load(
        builderFactories: BuilderFactories(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides,
      );

      expect(buildPlan.updates!.asMap(), <AssetId, ChangeType>{
        assetId: ChangeType.REMOVE,
        assetId2: ChangeType.MODIFY,
        assetId3: ChangeType.ADD,
        outputId: ChangeType.REMOVE,
      });
    });

    test('applies target glob from build config', () async {
      final buildConfig1 = runInBuildConfigZone(
        () {
          return BuildConfig(
            packageName: rootPackage,
            buildTargets: {
              '$rootPackage|$rootPackage': BuildTarget(
                sources: const InputSet(include: ['**/*.dart']),
              ),
            },
          );
        },
        rootPackage,
        [],
      );
      final buildPlan1 = await BuildPlan.load(
        builderFactories: BuilderFactories(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides.copyWith(
          buildConfig: {rootPackage: buildConfig1}.build(),
        ),
      );
      final assetGraph1 = buildPlan1.takeAssetGraph();
      // Matches the only `*.dart` source.
      expect(assetGraph1.sources, <AssetId>{assetId});

      // Same again but now glob `*.other`.
      final buildConfig2 = runInBuildConfigZone(
        () {
          return BuildConfig(
            packageName: rootPackage,
            buildTargets: {
              '$rootPackage|$rootPackage': BuildTarget(
                sources: const InputSet(include: ['**/*.other']),
              ),
            },
          );
        },
        rootPackage,
        [],
      );
      final buildPlan2 = await BuildPlan.load(
        builderFactories: BuilderFactories(),
        buildOptions: buildOptions,
        testingOverrides: testingOverrides.copyWith(
          buildConfig: {rootPackage: buildConfig2}.build(),
        ),
      );
      final assetGraph2 = buildPlan2.takeAssetGraph();
      // Matches the only `*.other` source.
      expect(assetGraph2.sources, <AssetId>{assetId2});
    });
  });
}
