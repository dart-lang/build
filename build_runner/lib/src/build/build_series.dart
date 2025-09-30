// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:watcher/watcher.dart';

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

  final Completer<void> _closingCompleter = Completer();

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

  /// A future that completes when [close] is called.
  ///
  /// Then, no further builds are allowed.
  Future<void> get closing => _closingCompleter.future;

  /// Filters [changes] to only changes that might trigger a build.
  ///
  /// Pass expected deletes in [expectedDeletes]. Expected deletes do not
  /// trigger a build. A delete that matches is removed from the set.
  Future<List<AssetChange>> filterChanges(
    List<AssetChange> changes,
    Set<AssetId> expectedDeletes,
  ) async {
    final result = <AssetChange>[];
    for (final change in changes) {
      final id = change.id;

      // Changes to the entrypoint are handled via depfiles.
      if (_buildPlan.bootstrapper.isKernelDependency(
        _buildPlan.packageGraph.pathFor(id),
      )) {
        result.add(change);
        continue;
      }
      if (id.path.startsWith(entrypointDirectoryPath)) {
        continue;
      }

      // Ignore any expected delete once.
      if (change.type == ChangeType.REMOVE && expectedDeletes.remove(id)) {
        continue;
      }

      if (_isBuildConfiguration(id)) {
        result.add(change);
        continue;
      }

      final node = _assetGraph.contains(id) ? _assetGraph.get(id) : null;

      // Changes to files that are not currently part of the build.
      if (node == null) {
        // Ignore under `.dart_tool/build`.
        if (id.path.startsWith(cacheDirectoryPath)) continue;

        // Ignore modifications and deletes.
        if (change.type != ChangeType.ADD) continue;

        // It's an add: handle if it's a new input.
        if (_buildPlan.targetGraph.anyMatchesAsset(id)) {
          result.add(change);
        }
        continue;
      }

      // Changes to files that are part of the build.

      // If not copying to a merged output directory, ignore changes to files
      // with no outputs.
      if (!_buildPlan.buildOptions.anyMergedOutputDirectory &&
          !node.changesRequireRebuild) {
        continue;
      }

      // Ignore creation or modification of outputs.
      if (node.type == NodeType.generated && change.type != ChangeType.REMOVE) {
        continue;
      }

      // For modifications, confirm that the content actually changed.
      if (change.type == ChangeType.MODIFY) {
        _readerWriter.cache.invalidate([id]);
        final newDigest = await _readerWriter.digest(id);
        if (node.digest != newDigest) {
          result.add(change);
        }
        continue;
      }

      // It's an add of "missing source" node or a deletion of an input.
      result.add(change);
    }

    return result;
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
  ///
  /// Set [recentlyBootstrapped] to skip doing checks that are done during
  /// bootstrapping. If [recentlyBootstrapped] then [updates] must be empty.
  Future<BuildResult> run(
    Map<AssetId, ChangeType> updates, {
    required bool recentlyBootstrapped,
    BuiltSet<BuildDirectory>? buildDirs,
    BuiltSet<BuildFilter>? buildFilters,
  }) async {
    if (_closingCompleter.isCompleted) {
      throw StateError('BuildSeries was closed.');
    }

    if (recentlyBootstrapped) {
      if (updates.isNotEmpty) {
        throw StateError('`recentlyBootstrapped` but updates not empty.');
      }
    } else {
      final kernelFreshness = await _buildPlan.bootstrapper
          .checkKernelFreshness(digestsAreFresh: false);
      if (!kernelFreshness.outputIsFresh) {
        final result = BuildResult.buildScriptChanged();
        _buildResultsController.add(result);
        await close();
        return result;
      }
    }

    if (updates.keys.any(_isBuildConfiguration)) {
      _buildPlan = await _buildPlan.reload();
      await _buildPlan.deleteFilesAndFolders();
      // A config change might have caused new builders to be needed, which
      // needs a restart to change the build script.
      if (_buildPlan.restartIsNeeded) {
        final result = BuildResult.buildScriptChanged();
        _buildResultsController.add(result);
        await close();
        return result;
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

  /// Ends the build series.
  ///
  /// First, [closing] is completed and new builds are prohibited.
  ///
  /// Then, any currently-running build is waited for, followed by cleanup of
  /// any resources via [ResourceManager.beforeExit].
  ///
  /// Finally, [buildResults] is closed.
  Future<void> close() async {
    if (_closingCompleter.isCompleted) return;
    _closingCompleter.complete();
    await _currentBuildResult;
    await _resourceManager.beforeExit();

    // Close the results stream last: this indicates that cleanup is done.
    await _buildResultsController.close();
  }
}
