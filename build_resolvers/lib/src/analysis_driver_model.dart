// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// ignore: implementation_imports
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
// ignore: implementation_imports
import 'package:build_runner_core/src/generate/build_step_impl.dart';

import 'analysis_driver_filesystem.dart';

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
///
/// TODO(davidmorgan): the implementation here is unfinished and not used
/// anywhere; finish it. See `build_asset_uri_resolver.dart` for the current
/// implementation.
class AnalysisDriverModel {
  /// In-memory filesystem for the analyzer.
  final AnalysisDriverFilesystem filesystem = AnalysisDriverFilesystem();

  /// The import graph of all sources needed for analysis.
  final LibraryCycleGraphLoader _graphLoader = LibraryCycleGraphLoader();

  /// Assets that have been synced into the in-memory filesystem
  /// [filesystem].
  final _syncedOntoFilesystem = <AssetId>{};

  /// Notifies that [step] has completed.
  ///
  /// All build steps must complete before [reset] is called.
  void notifyComplete(BuildStep step) {
    // This implementation doesn't keep state per `BuildStep`, nothing to do.
  }

  /// Clear cached information specific to an individual build.
  void reset() {
    _graphLoader.clear();
    _syncedOntoFilesystem.clear();
  }

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
    // Immediately take the lock on `driver` so that the whole class state,
    // is only mutated by one build step at a time.
    await withDriverResource((driver) async {
      // TODO(davidmorgan): it looks like this is only ever called with a single
      // entrypoint, consider doing a breaking release to simplify the API.
      for (final entrypoint in entrypoints) {
        await _performResolve(
          driver,
          buildStep as BuildStepImpl,
          entrypoint,
          withDriverResource,
          transitive: transitive,
        );
      }
    });
  }

  Future<void> _performResolve(
    AnalysisDriverForPackageBuild driver,
    BuildStepImpl buildStep,
    AssetId entrypoint,
    Future<void> Function(
      FutureOr<void> Function(AnalysisDriverForPackageBuild),
    )
    withDriverResource, {
    required bool transitive,
  }) async {
    Iterable<AssetId> idsToSyncOntoFilesystem = [entrypoint];

    // If requested, find transitive imports.
    if (transitive) {
      final nodeLoader = AssetDepsLoader(buildStep.phasedReader);
      final graph = await _graphLoader.transitiveDepsGraphOf(
        nodeLoader,
        entrypoint,
      );
      idsToSyncOntoFilesystem = graph.transitiveDeps;
      buildStep.inputTracker.addGraph(graph);
    } else {
      // Notify [buildStep] of its inputs.
      buildStep.inputTracker.add(entrypoint);
    }

    // Sync changes onto the "URI resolver", the in-memory filesystem.
    for (final id in idsToSyncOntoFilesystem) {
      if (!_syncedOntoFilesystem.add(id)) {
        continue;
      }
      final content =
          await buildStep.canRead(id) ? await buildStep.readAsString(id) : null;
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
  }
}

extension _AssetIdExtensions on AssetId {
  /// Asset path for the in-memory filesystem.
  String get asPath => AnalysisDriverFilesystem.assetPath(this);
}
