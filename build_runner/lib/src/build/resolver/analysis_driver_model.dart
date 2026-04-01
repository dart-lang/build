// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:pool/pool.dart';

import '../../logging/timed_activities.dart';
import '../asset_graph/graph.dart';
import '../input_tracker.dart';
import '../library_cycle_graph/asset_deps_loader.dart';
import '../library_cycle_graph/library_cycle_graph.dart';
import '../library_cycle_graph/library_cycle_graph_loader.dart';
import '../library_cycle_graph/phased_asset_deps.dart';
import '../library_cycle_graph/phased_reader.dart';
import 'analysis_driver_filesystem.dart';
import 'analysis_driver_for_package_build.dart';

/// Manages analysis driver and related build state.
///
/// - Tracks the import graph of all sources needed for analysis.
/// - Given a set of entrypoints, adds them to known sources, optionally with
///   their transitive imports.
/// - Given a set of entrypoints, informs a `BuildStep` which inputs it now
///   depends on because of analysis.
/// - Maintains an in-memory filesystem that is the analyzer's view of the
///   build.
/// - Notifies the analyzer of changes to that in-memory filesystem.
class AnalysisDriverModel {
  final _pool = Pool(1);
  PoolResource? _lock;

  /// In-memory filesystem for the analyzer.
  final AnalysisDriverFilesystem filesystem = AnalysisDriverFilesystem();

  /// The import graph of all sources needed for analysis.
  final LibraryCycleGraphLoader _graphLoader = LibraryCycleGraphLoader();

  /// Assets that have been synced into the in-memory filesystem
  /// [filesystem].
  final Set<LibraryCycleGraph> _syncedLibraryCycleGraphs = Set.identity();

  /// Starts a build with [assetGraph].
  ///
  /// If another build has the lock, waits for it to finish.
  Future<void> takeLockAndStartBuild(
    AssetGraph assetGraph, {
    required Set<AssetId>? invalidatedSources,
  }) async {
    _lock = await _pool.request();
    filesystem.startBuild(
      assetGraph.outputs.map((id) => assetGraph.get(id)!),
      invalidatedSources: invalidatedSources,
    );
  }

  /// Clears build state and frees the lock taken by [takeLockAndStartBuild].
  ///
  /// If no lock was taken, just clears build state.
  void endBuildAndUnlock() {
    _graphLoader.clear();
    _syncedLibraryCycleGraphs.clear();
    _lock?.release();
    _lock = null;
  }

  /// Serializable data from which the library cycle graphs can be
  /// reconstructed.
  ///
  /// This must be used to associated the entrypoints recorded with
  /// `InputTracker.addResolverEntrypoint` to transitively loaded assets.
  PhasedAssetDeps phasedAssetDeps() => _graphLoader.phasedAssetDeps();

  /// Attempts to parse [uri] into an [AssetId] and returns it if it is cached.
  ///
  /// Handles 'package:' or 'asset:' URIs, as well as 'file:' URIs of the form
  /// `/$packageName/$assetPath`.
  ///
  /// Returns null if the `Uri` cannot be parsed or is not cached.
  AssetId? lookupCachedAsset(Uri uri) {
    final assetId = AnalysisDriverFilesystem.parseAsset(uri);
    // TODO(davidmorgan): not clear if this is the right "exists" check.
    if (assetId == null || !filesystem.getFile(assetId.asPath).exists) {
      return null;
    }

    return assetId;
  }

  /// Updates [filesystem] and the driver provided by [withDriver] with updated
  /// source of [entrypoint] at the phase viewed by [phasedReader].
  ///
  /// If [transitive], then all the transitive imports from [entrypoint] are
  /// also updated.
  ///
  /// Records what was read in [inputTracker].
  Future<void> updateDriver({
    required Future<void> Function(
      Future<void> Function(AnalysisDriverForPackageBuild),
    )
    withDriver,
    required AssetId entrypoint,
    required PhasedReader phasedReader,
    required InputTracker? inputTracker,
    required bool transitive,
  }) async {
    AssetId? idToSyncOntoFilesystem;
    LibraryCycleGraph? libraryCycleGraphToSyncOntoFilesystem;

    // If requested, find transitive imports.
    if (transitive) {
      libraryCycleGraphToSyncOntoFilesystem = await TimedActivity.resolve
          .runAsync(() async {
            // Note: `transitiveDepsOf` can cause loads that cause builds that
            // cause a recursive `_performResolve` on this same `AnalysisDriver`
            // instance.
            final nodeLoader = AssetDepsLoader(phasedReader);
            inputTracker?.addResolverEntrypoint(entrypoint);
            return (await _graphLoader.libraryCycleGraphOf(
              nodeLoader,
              entrypoint,
            )).valueAt(phase: phasedReader.phase);
          });
    } else {
      // Notify [buildStep] of its inputs.
      inputTracker?.add(entrypoint);
      idToSyncOntoFilesystem = entrypoint;
      // Trigger any builds required for the file to be generated.
      await phasedReader.readAtPhase(entrypoint);
    }

    await withDriver((driver) async {
      // Sync changes onto the "URI resolver", the in-memory filesystem.

      await TimedActivity.resolve.runAsync(() async {
        // Change `filesystem`'s view of the files to be at `phase`.
        final phase = phasedReader.phase;
        filesystem.phase = phase;

        Future<void> writeToFilesystem(AssetId id) async {
          final content = await phasedReader.readAtPhase(id);
          if (content.exists) {
            filesystem.writeContent(content);
          }
        }

        // For single file parsing, sync that one file.
        if (idToSyncOntoFilesystem != null) {
          await writeToFilesystem(idToSyncOntoFilesystem);
        }

        // For transitive resolves, sync all transitive library cycle graphs
        // that were not already synced.
        if (libraryCycleGraphToSyncOntoFilesystem != null) {
          final nextGraphs = [libraryCycleGraphToSyncOntoFilesystem];
          while (nextGraphs.isNotEmpty) {
            final nextGraph = nextGraphs.removeLast();
            if (_syncedLibraryCycleGraphs.add(nextGraph)) {
              for (final id in nextGraph.root.ids) {
                await writeToFilesystem(id);
              }
              nextGraphs.addAll(nextGraph.children);
            }
          }
        }
      });

      // Notify the analyzer of changes and wait for it to update its internal
      // state.
      if (filesystem.changedPaths.isNotEmpty) {
        for (final path in filesystem.changedPaths) {
          driver.changeFile(path);
        }
        filesystem.clearChangedPaths();
        await TimedActivity.analyze.runAsync(driver.applyPendingFileChanges);
        await TimedActivity.analyze.runAsync(driver.waitForIdle);
      }
    });
  }
}
