// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';

import '../../logging/timed_activities.dart';
import '../build_step_impl.dart';
import '../library_cycle_graph/asset_deps_loader.dart';
import '../library_cycle_graph/library_cycle_graph_loader.dart';
import '../library_cycle_graph/phased_asset_deps.dart';
import 'analysis_driver_filesystem.dart';

import 'build_resolvers.dart';

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
  /// The instance used by the shared `AnalyzerResolvers` instance.
  static AnalysisDriverModel sharedInstance = AnalysisDriverModel();

  /// In-memory filesystem for the analyzer.
  final AnalysisDriverFilesystem filesystem = AnalysisDriverFilesystem();

  /// The import graph of all sources needed for analysis.
  final LibraryCycleGraphLoader _graphLoader = LibraryCycleGraphLoader();

  /// Assets that have been synced into the in-memory filesystem
  /// [filesystem].
  final _syncedOntoFilesystemAtPhase = <AssetId, int>{};

  /// Notifies that [step] has completed.
  ///
  /// All build steps must complete before [reset] is called.
  void notifyComplete(BuildStep step) {
    // This implementation doesn't keep state per `BuildStep`, nothing to do.
  }

  /// Clear cached information specific to an individual build.
  void reset() {
    _graphLoader.clear();
    _syncedOntoFilesystemAtPhase.clear();
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

  /// Updates [filesystem] and the analysis driver given by
  /// `withDriverResource`  with updated versions of [entrypoints].
  ///
  /// If [transitive], then all the transitive imports from [entrypoints] are
  /// also updated.
  ///
  /// Notifies [buildStep] of all inputs that result from analysis. If
  /// [transitive], this includes all transitive dependencies.
  ///
  Future<void> performResolve(
    BuildStep buildStep,
    List<AssetId> entrypoints,
    Future<void> Function(
      FutureOr<void> Function(AnalysisDriverForPackageBuild),
    )
    withDriverResource, {
    required bool transitive,
  }) async {
    for (final entrypoint in entrypoints) {
      await _performResolve(
        buildStep as BuildStepImpl,
        entrypoint,
        withDriverResource,
        transitive: transitive,
      );
    }
  }

  Future<void> _performResolve(
    BuildStepImpl buildStep,
    AssetId entrypoint,
    Future<void> Function(
      FutureOr<void> Function(AnalysisDriverForPackageBuild),
    )
    withDriverResource, {
    required bool transitive,
  }) async {
    Iterable<AssetId> idsToSyncOntoFilesystem;

    // If requested, find transitive imports.
    if (transitive) {
      idsToSyncOntoFilesystem = await TimedActivity.resolve.runAsync(() async {
        // Note: `transitiveDepsOf` can cause loads that cause builds that
        // cause a recursive `_performResolve` on this same `AnalysisDriver`
        // instance.
        final nodeLoader = AssetDepsLoader(buildStep.phasedReader);
        buildStep.inputTracker.addResolverEntrypoint(entrypoint);
        return await _graphLoader.transitiveDepsOf(nodeLoader, entrypoint);
      });
    } else {
      // Notify [buildStep] of its inputs.
      buildStep.inputTracker.add(entrypoint);
      idsToSyncOntoFilesystem = [entrypoint];
    }

    await withDriverResource((driver) async {
      // Sync changes onto the "URI resolver", the in-memory filesystem.
      final phase = buildStep.phasedReader.phase;
      for (final id in idsToSyncOntoFilesystem) {
        final wasSyncedAt = _syncedOntoFilesystemAtPhase[id];
        if (wasSyncedAt != null) {
          // Skip if already synced at this phase.
          if (wasSyncedAt == phase) {
            continue;
          }
          // Skip if synced at an equivalent other phase.
          if (!buildStep.phasedReader.hasChanged(
            id,
            comparedToPhase: wasSyncedAt,
          )) {
            continue;
          }
        }

        _syncedOntoFilesystemAtPhase[id] = phase;

        // Tracking has already been done by calling `inputTracker` directly.
        // Use `phasedReader` for the read instead of the `buildStep` methods
        // `canRead` and `readAsString`, which would call `inputTracker`.
        final content = await buildStep.phasedReader.readAtPhase(id);
        if (content == null) {
          filesystem.deleteFile(id.asPath);
        } else {
          filesystem.writeFile(id.asPath, content);
        }
      }

      // Notify the analyzer of changes and wait for it to update its internal
      // state.
      for (final path in filesystem.changedPaths) {
        driver.changeFile(path);
      }
      filesystem.clearChangedPaths();
      await driver.applyPendingFileChanges();
    });
  }
}

extension _AssetIdExtensions on AssetId {
  /// Asset path for the in-memory filesystem.
  String get asPath => AnalysisDriverFilesystem.assetPath(this);
}
