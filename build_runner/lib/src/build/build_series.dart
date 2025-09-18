// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';

import '../build_plan/build_directory.dart';
import '../build_plan/build_filter.dart';
import '../build_plan/build_plan.dart';
import '../io/filesystem_cache.dart';
import '../io/finalized_reader.dart';
import '../io/reader_writer.dart';
import '../logging/build_log.dart';
import 'asset_graph/graph.dart';
import 'build.dart';
import 'build_result.dart';

/// A series of builds with the same configuration.
///
/// Changes to inputs are tracked to determine what build steps need to rerun
/// each time, for fast "incremental" builds.
///
/// This happens either across multiple invocations of `build_runner build` or
/// within one long-running `build_runner watch` or `build_runner serve`.
///
/// In both cases, the `AssetGraph` is serialized after the build, to give the
/// starting state for the next `build_runner build`. For `watch` and `serve`
/// this serialized state is not actually used: the `AssetGraph` instance
/// already in memory is used directly.
class BuildSeries {
  BuildPlan buildPlan;
  FinalizedReader? finalizedReader;
  AssetGraph? assetGraph;
  ReaderWriter? readerWriter;
  final ResourceManager resourceManager = ResourceManager();

  Future<void> beforeExit() => resourceManager.beforeExit();

  BuildSeries(this.buildPlan);

  /// Runs a single build.
  ///
  /// For the first build, pass any changes since the `BuildSeries` was created
  /// as [updates]. If the first build happens immediately then pass empty
  /// `updates`.
  ///
  /// For further builds, pass the changes since the previous builds as
  /// [updates].
  Future<BuildResult> run({
    BuiltSet<BuildDirectory>? buildDirs,
    BuiltSet<BuildFilter>? buildFilters,
  }) async {
    buildDirs ??= buildPlan.buildOptions.buildDirs;
    buildFilters ??= buildPlan.buildOptions.buildFilters;

    final firstBuild = assetGraph == null;
    if (firstBuild) {
      assetGraph = buildPlan.takeAssetGraph();
    } else {
      buildPlan = await buildPlan.reload();
      assetGraph = buildPlan.takeAssetGraph();
    }
    readerWriter = buildPlan.readerWriter.copyWith(
      generatedAssetHider: assetGraph,
      cache:
          buildPlan.buildOptions.enableLowResourcesMode
              ? const PassthroughFilesystemCache()
              : InMemoryFilesystemCache(),
    );

    finalizedReader = FinalizedReader(
      buildPlan.readerWriter.copyWith(generatedAssetHider: assetGraph),
      assetGraph!,
      buildPlan.targetGraph,
      buildPlan.buildPhases,
      buildPlan.packageGraph.root.name,
    );

    finalizedReader!.reset(BuildDirectory.buildPaths(buildDirs), buildFilters);

    if (!firstBuild && !buildPlan.buildIsNeeded) {
      return BuildResult(BuildStatus.success, []);
    }

    if (!firstBuild) {
      buildLog.nextBuild();
    }
    final build = Build(
      buildPlan: buildPlan.copyWith(
        buildDirs: buildDirs,
        buildFilters: buildFilters,
      ),
      assetGraph: assetGraph!,
      readerWriter: readerWriter!,
      resourceManager: resourceManager,
    );
    final result = await build.run(buildPlan.updates ?? BuiltMap());
    return result;
  }
}
