// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:watcher/watcher.dart';

import '../asset/reader_writer.dart';
import '../asset_graph/exceptions.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/graph_loader.dart';
import '../build_script_generate/build_process_state.dart';
import '../changes/build_script_updates.dart';
import '../logging/build_log.dart';
import '../package_graph/package_graph.dart';
import '../package_graph/target_graph.dart';
import '../util/constants.dart';
import 'asset_tracker.dart';
import 'build_phases.dart';
import 'exceptions.dart';

// TODO(davidmorgan): rename/refactor this, it's now just about loading state,
// not a build definition.
class BuildDefinition {
  final AssetGraph assetGraph;
  final BuildScriptUpdates? buildScriptUpdates;

  /// When reusing serialized state from a previous build: the file updates
  /// since that build.
  ///
  /// Or, `null` if there was no serialized state or it was discared due to
  /// the current build having an incompatible change.
  final Map<AssetId, ChangeType>? updates;

  BuildDefinition._(this.assetGraph, this.buildScriptUpdates, this.updates);

  static Future<BuildDefinition> prepareWorkspace({
    required PackageGraph packageGraph,
    required TargetGraph targetGraph,
    required ReaderWriter readerWriter,
    required BuildPhases buildPhases,
    required bool skipBuildScriptCheck,
  }) =>
      _Loader(
        packageGraph,
        targetGraph,
        readerWriter,
        buildPhases,
        skipBuildScriptCheck,
      ).prepareWorkspace();
}

class _Loader {
  final PackageGraph packageGraph;
  final TargetGraph targetGraph;
  final ReaderWriter readerWriter;
  final BuildPhases buildPhases;
  final bool skipBuildScriptCheck;

  _Loader(
    this.packageGraph,
    this.targetGraph,
    this.readerWriter,
    this.buildPhases,
    this.skipBuildScriptCheck,
  );

  Future<BuildDefinition> prepareWorkspace() async {
    buildPhases.checkOutputLocations(packageGraph.root.name);

    final assetGraphLoader = AssetGraphLoader(
      readerWriter: readerWriter,
      buildPhases: buildPhases,
      packageGraph: packageGraph,
    );

    var assetGraph = await assetGraphLoader.load();

    final assetTracker = AssetTracker(readerWriter, targetGraph);
    final inputSources = await assetTracker.findInputSources();
    final cacheDirSources = await assetTracker.findCacheDirSources();
    final internalSources = await assetTracker.findInternalSources();

    BuildScriptUpdates? buildScriptUpdates;
    Map<AssetId, ChangeType>? updates;
    if (assetGraph != null) {
      buildLog.doing('Checking for updates.');
      updates = await _computeUpdates(
        assetGraph,
        assetTracker,
        inputSources,
        cacheDirSources,
        internalSources,
      );
      buildScriptUpdates = await BuildScriptUpdates.create(
        readerWriter,
        packageGraph,
        assetGraph,
        disabled: skipBuildScriptCheck,
      );

      final buildScriptUpdated =
          !skipBuildScriptCheck &&
          buildScriptUpdates.hasBeenUpdated(updates.keys.toSet());
      if (buildScriptUpdated) {
        buildLog.fullBuildBecause(FullBuildReason.incompatibleScript);
        final deletedSourceOutputs = await assetGraph.deleteOutputs(
          packageGraph,
          readerWriter,
        );
        await _deleteGeneratedDir();

        if (_runningFromSnapshot) {
          // We have to be regenerated if running from a snapshot.
          throw const BuildScriptChangedException();
        }

        inputSources.removeAll(deletedSourceOutputs);
        assetGraph = null;
        buildScriptUpdates = null;
        updates = null;
      }
    }

    if (assetGraph == null) {
      buildLog.doing('Creating the asset graph.');

      late Set<AssetId> conflictingOutputs;
      try {
        assetGraph = await AssetGraph.build(
          buildPhases,
          inputSources,
          internalSources,
          packageGraph,
          readerWriter,
        );
      } on DuplicateAssetNodeException catch (e) {
        buildLog.error(e.toString());
        throw const CannotBuildException();
      }
      buildScriptUpdates = await BuildScriptUpdates.create(
        readerWriter,
        packageGraph,
        assetGraph,
        disabled: skipBuildScriptCheck,
      );

      conflictingOutputs =
          assetGraph.outputs
              .where((n) => n.package == packageGraph.root.name)
              .where(inputSources.contains)
              .toSet();
      final conflictsInDeps =
          assetGraph.outputs
              .where((n) => n.package != packageGraph.root.name)
              .where(inputSources.contains)
              .toSet();
      if (conflictsInDeps.isNotEmpty) {
        buildLog.error(
          'There are existing files in dependencies which conflict '
          'with files that a Builder may produce. These must be removed or '
          'the Builders disabled before a build can continue: '
          '${conflictsInDeps.map((a) => a.uri).join('\n')}',
        );
        throw const CannotBuildException();
      }

      buildLog.doing('Doing initial build cleanup.');
      // Use a writer with no asset graph. If it had the asset graph, it would
      // delete from the generated output location, but the aim is to delete
      // from input sources.
      await _initialBuildCleanup(conflictingOutputs, readerWriter);
    }

    return BuildDefinition._(assetGraph, buildScriptUpdates, updates);
  }

  /// Deletes the generated output directory.
  Future<void> _deleteGeneratedDir() async {
    final generatedDir = Directory(generatedOutputDirectory);
    if (await generatedDir.exists()) {
      await generatedDir.delete(recursive: true);
    }
  }

  /// Returns which sources and builder options changed, and the [ChangeType]
  /// describing whether they where added, removed or modified.
  Future<Map<AssetId, ChangeType>> _computeUpdates(
    AssetGraph assetGraph,
    AssetTracker assetTracker,
    Set<AssetId> inputSources,
    Set<AssetId> cacheDirSources,
    Set<AssetId> internalSources,
  ) async {
    final updates = await assetTracker.computeSourceUpdates(
      inputSources,
      cacheDirSources,
      internalSources,
      assetGraph,
    );
    return updates;
  }

  /// Handles cleanup of pre-existing outputs for initial builds (where there is
  /// no cached graph).
  Future<void> _initialBuildCleanup(
    Set<AssetId> conflictingAssets,
    ReaderWriter readerWriter,
  ) async {
    if (conflictingAssets.isEmpty) return;
    await Future.wait(conflictingAssets.map((id) => readerWriter.delete(id)));
  }
}

bool get _runningFromSnapshot => !Platform.script.path.endsWith('.dart');
