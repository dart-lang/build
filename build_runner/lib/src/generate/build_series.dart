// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:watcher/watcher.dart';

import '../asset/finalized_reader.dart';
import '../asset/reader_writer.dart';
import '../asset_graph/graph.dart';
import '../build_plan.dart';
import '../changes/build_script_updates.dart';
import '../commands/build_filter.dart';
import '../state/filesystem_cache.dart';
import 'build.dart';
import 'build_definition.dart';
import 'build_directory.dart';
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
  final BuildPlan buildPlan;

  final AssetGraph assetGraph;
  final BuildScriptUpdates? buildScriptUpdates;

  final FinalizedReader finalizedReader;
  final ReaderWriter readerWriter;
  final ResourceManager resourceManager = ResourceManager();

  /// For the first build only, updates from the previous serialized build
  /// state.
  ///
  /// Null after the first build, or if there was no serialized build state, or
  /// if the serialized build state was discarded.
  Map<AssetId, ChangeType>? updatesFromLoad;

  /// Whether the next build is the first build.
  bool firstBuild = true;

  Future<void> beforeExit() => resourceManager.beforeExit();

  BuildSeries._(
    this.buildPlan,
    this.assetGraph,
    this.buildScriptUpdates,
    this.finalizedReader,
    this.updatesFromLoad,
  ) : readerWriter = buildPlan.readerWriter.copyWith(
        generatedAssetHider: assetGraph,
        cache:
            buildPlan.buildOptions.enableLowResourcesMode
                ? const PassthroughFilesystemCache()
                : InMemoryFilesystemCache(),
      );

  /// Runs a single build.
  ///
  /// For the first build, pass any changes since the `BuildSeries` was created
  /// as [updates]. If the first build happens immediately then pass empty
  /// `updates`.
  ///
  /// For further builds, pass the changes since the previous builds as
  /// [updates].
  Future<BuildResult> run(
    Map<AssetId, ChangeType> updates, {
    BuiltSet<BuildDirectory>? buildDirs,
    BuiltSet<BuildFilter>? buildFilters,
  }) async {
    buildDirs ??= buildPlan.buildOptions.buildDirs;
    buildFilters ??= buildPlan.buildOptions.buildFilters;
    if (firstBuild) {
      if (updatesFromLoad != null) {
        updates = updatesFromLoad!..addAll(updates);
        updatesFromLoad = null;
      }
    } else {
      if (updatesFromLoad != null) {
        throw StateError('Only first build can have updates from load.');
      }
    }

    finalizedReader.reset(BuildDirectory.buildPaths(buildDirs), buildFilters);
    final build = Build(
      buildPlan: buildPlan.copyWith(
        buildDirs: buildDirs,
        buildFilters: buildFilters,
      ),
      assetGraph: assetGraph,
      readerWriter: readerWriter,
      resourceManager: resourceManager,
    );
    if (firstBuild) firstBuild = false;
    final result = await build.run(updates);
    return result;
  }

  static Future<BuildSeries> create({required BuildPlan buildPlan}) async {
    var buildDefinition = await BuildDefinition.prepareWorkspace(
      packageGraph: buildPlan.packageGraph,
      targetGraph: buildPlan.targetGraph,
      readerWriter: buildPlan.readerWriter,
      buildPhases: buildPlan.buildPhases,
      skipBuildScriptCheck: buildPlan.buildOptions.skipBuildScriptCheck,
    );

    var finalizedReader = FinalizedReader(
      buildPlan.readerWriter.copyWith(
        generatedAssetHider: buildDefinition.assetGraph,
      ),
      buildDefinition.assetGraph,
      buildPlan.targetGraph,
      buildPlan.buildPhases,
      buildPlan.packageGraph.root.name,
    );
    var build = BuildSeries._(
      buildPlan,
      buildDefinition.assetGraph,
      buildDefinition.buildScriptUpdates,
      finalizedReader,
      buildDefinition.updates,
    );
    return build;
  }
}
