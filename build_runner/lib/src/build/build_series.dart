// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:watcher/watcher.dart';

import '../bootstrap/build_script_generate.dart';
import '../build_plan/build_directory.dart';
import '../build_plan/build_filter.dart';
import '../build_plan/build_plan.dart';
import '../commands/watch/asset_change.dart';
import '../constants.dart';
import '../io/asset_tracker.dart';
import '../io/filesystem_cache.dart';
import '../io/reader_writer.dart';
import '../logging/build_log.dart';
import 'asset_graph/graph.dart';
import 'asset_graph/node.dart';
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
  BuildPlan _buildPlan;
  AssetGraph _assetGraph;
  ReaderWriter _readerWriter;

  final ResourceManager _resourceManager = ResourceManager();

  /// For the first build only, updates from the previous serialized build
  /// state.
  ///
  /// Null after the first build, or if there was no serialized build state, or
  /// if the serialized build state was discarded.
  BuiltMap<AssetId, ChangeType>? _updatesFromLoad;

  final StreamController<BuildResult> _buildResultsController =
      StreamController.broadcast();

  /// Whether the next build is the first build.
  bool firstBuild = true;

  BuildSeries._({
    required BuildPlan buildPlan,
    required AssetGraph assetGraph,
    required ReaderWriter readerWriter,
    required BuiltMap<AssetId, ChangeType>? updatesFromLoad,
  }) : _buildPlan = buildPlan,
       _assetGraph = assetGraph,
       _readerWriter = readerWriter,
       _updatesFromLoad = updatesFromLoad;

  factory BuildSeries(BuildPlan buildPlan) {
    final assetGraph = buildPlan.takeAssetGraph();
    final readerWriter = buildPlan.readerWriter.copyWith(
      generatedAssetHider: assetGraph,
      cache:
          buildPlan.buildOptions.enableLowResourcesMode
              ? const PassthroughFilesystemCache()
              : InMemoryFilesystemCache(),
    );
    return BuildSeries._(
      buildPlan: buildPlan,
      assetGraph: assetGraph,
      readerWriter: readerWriter,
      updatesFromLoad: buildPlan.updates,
    );
  }

  /// Broadcast stream of build results.
  Stream<BuildResult> get buildResults => _buildResultsController.stream;
  Future<BuildResult>? _currentBuildResult;

  bool _hasBuildScriptChanged(Set<AssetId> changes) {
    if (_buildPlan.buildOptions.skipBuildScriptCheck) return false;
    if (_buildPlan.buildScriptUpdates == null) return true;
    return _buildPlan.buildScriptUpdates!.hasBeenUpdated(changes);
  }

  /// Returns whether [change] might trigger a build.
  ///
  /// Pass expected deletes in [expectedDeletes]. Expected deletes do not
  /// trigger a build. A delete that matches is removed from the set.
  Future<bool> shouldProcess(
    AssetChange change,
    Set<AssetId> expectedDeletes,
  ) async {
    // Ignore any expected delete once.
    if (change.type == ChangeType.REMOVE && expectedDeletes.remove(change.id)) {
      return false;
    }

    final id = change.id;
    if (_isBuildConfiguration(id)) return true;

    final node = _assetGraph.contains(id) ? _assetGraph.get(id) : null;

    // Changes to files that are not currently part of the build.
    if (node == null) {
      // Ignore under `.dart_tool/build`.
      if (id.path.startsWith(cacheDir)) return false;

      // Ignore modifications and deletes.
      if (change.type != ChangeType.ADD) return false;

      // It's an add: return whether it's a new input.
      return _buildPlan.targetGraph.anyMatchesAsset(id);
    }

    // Changes to files that are part of the build.

    // If not copying to a merged output directory, ignore changes to files with
    // no outputs.
    if (!_buildPlan.buildOptions.anyMergedOutputDirectory &&
        !node.changesRequireRebuild) {
      return false;
    }

    // Ignore creation or modification of outputs.
    if (node.type == NodeType.generated && change.type != ChangeType.REMOVE) {
      return false;
    }

    // For modifications, confirm that the content actually changed.
    if (change.type == ChangeType.MODIFY) {
      _readerWriter.cache.invalidate([id]);
      final newDigest = await _readerWriter.digest(id);
      return node.digest != newDigest;
    }

    // It's an add of "missing source" node or a deletion of an input.
    return true;
  }

  bool _isBuildConfiguration(AssetId id) =>
      id.path == 'build.yaml' ||
      id.path.endsWith('.build.yaml') ||
      (id.package == _buildPlan.packageGraph.root.name &&
          id.path == 'build.${_buildPlan.buildOptions.configKey}.yaml');

  Future<List<WatchEvent>> checkForChanges() async {
    final updates = await AssetTracker(
      _buildPlan.readerWriter,
      _buildPlan.targetGraph,
    ).collectChanges(_assetGraph);
    return List.of(
      updates.entries.map((entry) => WatchEvent(entry.value, '${entry.key}')),
    );
  }

  /// If a build is running, the build result when it's done.
  ///
  /// If no build has ever run, returns the first build result when it's
  /// available.
  ///
  /// If a build has run, the most recent build result.
  Future<BuildResult> get currentBuildResult =>
      _currentBuildResult ?? buildResults.first;

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
    if (_hasBuildScriptChanged(updates.keys.toSet())) {
      return BuildResult.buildScriptChanged();
    }

    if (updates.keys.any(_isBuildConfiguration)) {
      _buildPlan = await _buildPlan.reload();
      await _buildPlan.deleteFilesAndFolders();
      // A config change might have caused new builders to be needed, which
      // needs a restart to change the build script.
      if (_buildPlan.restartIsNeeded) {
        return BuildResult.buildScriptChanged();
      }
      // A config change might have changed builder factories, which needs a
      // restart to change the build script.
      if (await hasGeneratedBuildScriptChanged()) {
        return BuildResult.buildScriptChanged();
      }
      _assetGraph = _buildPlan.takeAssetGraph();
      _readerWriter = _buildPlan.readerWriter.copyWith(
        generatedAssetHider: _assetGraph,
        cache:
            _buildPlan.buildOptions.enableLowResourcesMode
                ? const PassthroughFilesystemCache()
                : InMemoryFilesystemCache(),
      );
    }

    buildDirs ??= _buildPlan.buildOptions.buildDirs;
    buildFilters ??= _buildPlan.buildOptions.buildFilters;
    if (firstBuild) {
      if (_updatesFromLoad != null) {
        updates = _updatesFromLoad!.toMap()..addAll(updates);
        _updatesFromLoad = null;
      }
    } else {
      if (_updatesFromLoad != null) {
        throw StateError('Only first build can have updates from load.');
      }
    }

    if (!firstBuild) buildLog.nextBuild();
    final build = Build(
      buildPlan: _buildPlan.copyWith(
        buildDirs: buildDirs,
        buildFilters: buildFilters,
      ),
      assetGraph: _assetGraph,
      readerWriter: _readerWriter,
      resourceManager: _resourceManager,
    );
    if (firstBuild) firstBuild = false;

    _currentBuildResult = build.run(updates);
    final result = await _currentBuildResult!;
    _buildResultsController.add(result);
    return result;
  }

  Future<void> beforeExit() => _resourceManager.beforeExit();
}
