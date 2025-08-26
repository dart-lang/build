// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:watcher/watcher.dart';

import '../asset/finalized_reader.dart';
import '../asset/writer.dart';
import '../asset_graph/graph.dart';
import '../changes/build_script_updates.dart';
import '../environment/build_environment.dart';
import '../logging/build_log.dart';
import '../package_graph/apply_builders.dart';
import 'build.dart';
import 'build_definition.dart';
import 'build_directory.dart';
import 'build_phases.dart';
import 'build_result.dart';
import 'options.dart';

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
  // Configuration.
  final BuildOptions _options;
  final BuildEnvironment _environment;
  final List<BuilderApplication> _builders;
  final Map<String, Map<String, dynamic>> _builderConfigOverrides;
  final bool isReleaseBuild;

  // State that is kept forever.
  final FilesystemCache _cache;
  final ResourceManager _resourceManager = ResourceManager();

  // State that is initialized by `_prepare` then kept.

  late BuildPhases _buildPhases;
  late AssetGraph assetGraph;
  late BuildScriptUpdates? buildScriptUpdates;
  late FinalizedReader finalizedReader;

  // State that is initialized by `_prepare` and changes after the build.

  /// Whether the next build is the first build.
  late bool _firstBuild;

  /// For the first build only, updates from the previous serialized build
  /// state.
  ///
  /// Null after the first build, or if there was no serialized build state, or
  /// if the serialized build state was discarded.
  Map<AssetId, ChangeType>? updatesFromLoad;

  BuildSeries._({
    required BuildOptions options,
    required BuildEnvironment environment,
    required List<BuilderApplication> builders,
    required Map<String, Map<String, dynamic>> builderConfigOverrides,
    required this.isReleaseBuild,
  }) : _builderConfigOverrides = builderConfigOverrides,
       _builders = builders,
       _environment = environment,
       _options = options,
       _cache =
           options.enableLowResourcesMode
               ? const PassthroughFilesystemCache()
               : InMemoryFilesystemCache();

  static Future<BuildSeries> create(
    BuildOptions options,
    BuildEnvironment environment,
    List<BuilderApplication> builders,
    Map<String, Map<String, dynamic>> builderConfigOverrides, {
    bool isReleaseBuild = false,
  }) async {
    final result = BuildSeries._(
      options: options,
      environment: environment,
      builders: builders,
      builderConfigOverrides: builderConfigOverrides,
      isReleaseBuild: isReleaseBuild,
    );
    await result._prepare();
    return result;
  }

  Future<void> _prepare() async {
    _buildPhases = await createBuildPhases(
      _options.targetGraph,
      _builders,
      _builderConfigOverrides,
      isReleaseBuild,
    );
    if (_buildPhases.inBuildPhases.isEmpty &&
        _buildPhases.postBuildPhase.builderActions.isEmpty) {
      buildLog.warning('Nothing to build.');
    }

    final buildDefinition = await BuildDefinition.prepareWorkspace(
      _environment,
      _options,
      _buildPhases,
    );
    buildScriptUpdates = buildDefinition.buildScriptUpdates;
    assetGraph = buildDefinition.assetGraph;
    _firstBuild = true;
    updatesFromLoad = buildDefinition.updates;

    finalizedReader = FinalizedReader(
      _environment.reader.copyWith(
        generatedAssetHider: buildDefinition.assetGraph,
      ),
      buildDefinition.assetGraph,
      _options.targetGraph,
      _buildPhases,
      _options.packageGraph.root.name,
    );
  }

  Future<void> beforeExit() => _resourceManager.beforeExit();

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
    Set<BuildDirectory> buildDirs = const <BuildDirectory>{},
    Set<BuildFilter> buildFilters = const {},
  }) async {
    if (_firstBuild) {
      if (updatesFromLoad != null) {
        updates = updatesFromLoad!..addAll(updates);
        updatesFromLoad = null;
      }
    } else {
      if (updatesFromLoad != null) {
        throw StateError('Only first build can have updates from load.');
      }
    }

    final readerWriter = _environment.reader.copyWith(
      generatedAssetHider: assetGraph,
      cache: _cache,
    );
    // Prefer to use `readerWriter` for deletes if possible, so deletes can go
    // to the write cache.
    // TODO(davidmorgan): clean up setup so it's always possible.
    final RunnerAssetWriter deleteWriter;
    if (readerWriter is RunnerAssetWriter) {
      deleteWriter = readerWriter as RunnerAssetWriter;
    } else {
      deleteWriter = _environment.writer.copyWith(
        generatedAssetHider: assetGraph,
      );
    }

    finalizedReader.reset(BuildDirectory.buildPaths(buildDirs), buildFilters);
    final build = Build(
      environment: _environment,
      options: _options,
      buildPhases: _buildPhases,
      assetGraph: assetGraph,
      buildDirs: buildDirs,
      buildFilters: buildFilters,
      readerWriter: readerWriter,
      deleteWriter: deleteWriter,
      resourceManager: _resourceManager,
    );
    if (_firstBuild) _firstBuild = false;
    final result = await build.run(updates);
    _options.resolvers.reset();
    return result;
  }
}
