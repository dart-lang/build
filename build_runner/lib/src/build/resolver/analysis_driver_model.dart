// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

// ignore: implementation_imports
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:pool/pool.dart';

import '../../logging/timed_activities.dart';
import '../input_tracker.dart';
import '../library_cycle_graph/asset_deps_loader.dart';
import '../library_cycle_graph/library_cycle_graph_loader.dart';
import '../library_cycle_graph/phased_asset_deps.dart';
import '../library_cycle_graph/phased_reader.dart';
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
class AnalysisDriverModel {
  final _pool = Pool(1);
  PoolResource? _lock;

  /// In-memory filesystem for the analyzer.
  final AnalysisDriverFilesystem filesystem = AnalysisDriverFilesystem();

  /// The import graph of all sources needed for analysis.
  final LibraryCycleGraphLoader _graphLoader = LibraryCycleGraphLoader();

  /// Starts a build.
  ///
  /// If another build has the lock, waits for it to finish.
  Future<void> takeLockAndStartBuild({
    required Iterable<AssetId>? invalidatedSources,
    required Iterable<AssetId>? disappearedOutputs,
  }) async {
    _lock = await _pool.request();
    filesystem.startBuild(
      invalidatedSources: invalidatedSources,
      disappearedOutputs: disappearedOutputs,
    );
  }

  /// Clears build state and frees the lock taken by [takeLockAndStartBuild].
  ///
  /// If no lock was taken, just clears build state.
  void endBuildAndUnlock() {
    _graphLoader.clear();
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

  /// Pushes [content] for [id] to the in-memory filesystem.
  void pushContent(AssetId id, String content, {int phase = -1}) {
    final hash = base64.encode(md5.convert(utf8.encode(content)).bytes);
    filesystem.writeContent(
      BuildRunnerFileContent(id.asPath, true, content, hash),
      phase: phase,
    );
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
    required InputTracker inputTracker,
    required bool transitive,
  }) async {
    // If requested, find transitive imports.
    if (transitive) {
      await TimedActivity.resolve.runAsync(() async {
        // Note: `transitiveDepsOf` can cause loads that cause builds that
        // cause a recursive `_performResolve` on this same `AnalysisDriver`
        // instance.
        final nodeLoader = AssetDepsLoader(phasedReader);
        inputTracker.addResolverEntrypoint(entrypoint);
        await _graphLoader.libraryCycleGraphOf(nodeLoader, entrypoint);
      });
    } else {
      // Notify [buildStep] of its inputs.
      inputTracker.add(entrypoint);
      // Trigger any builds required for the file to be generated.
      await phasedReader.readAtPhase(entrypoint);
    }

    await withDriver((driver) async {
      // Sync changes onto the "URI resolver", the in-memory filesystem.

      await TimedActivity.resolve.runAsync(() async {
        // Change `filesystem`'s view of the files to be at `phase`.
        filesystem.phase = phasedReader.phase;
      });

      // Notify the analyzer of changes and wait for it to update its internal
      // state.
      if (filesystem.changedPaths.isNotEmpty) {
        for (final path in filesystem.changedPaths) {
          driver.changeFile(path);
        }
        filesystem.clearChangedPaths();
        await TimedActivity.analyze.runAsync(driver.applyPendingFileChanges);
      }
    });
  }
}
