// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:scratch_space/scratch_space.dart';

/// A persistent shared [FrontendServerState] for DDC workers that interact with
/// the Frontend Server.
final frontendServerState = FrontendServerState();

/// The asset in [package] that `WebEntrypointMarkerBuilder` records the app's
/// entrypoint in.
///
/// That builder runs on the `$web$` placeholder, which is always `web/$web$`,
/// so its `.web.entrypoint.json` output always lands directly under `web`.
/// Everything that writes or reads the file goes through here so the two can't
/// drift apart.
AssetId webEntrypointStateAssetId(String package) =>
    AssetId(package, 'web/.web.entrypoint.json');

class FrontendServerState {
  /// The built app's main entrypoint file.
  ///
  /// This must be set before any asset builders run when
  /// compiling with DDC and hot reload enabled.
  ///
  /// `WebEntrypointMarkerBuilder` sets it, and also stages it into the scratch
  /// space; see [stagedEntrypointAssetId].
  AssetId? entrypointAssetId;

  /// The entrypoint that has been copied into the scratch space, if any.
  ///
  /// Build steps in other packages can't read a generated entrypoint
  /// themselves, so `WebEntrypointMarkerBuilder` stages a copy for them to
  /// compile against and records it here.
  ///
  /// The scratch space outlives an individual build, so this is not reset
  /// between builds; it is only unset for as long as nothing has been staged
  /// into the current scratch space.
  AssetId? stagedEntrypointAssetId;

  /// The scratch space where the Frontend Server writes its outputs (`.js`,
  /// `.map`, and `.metadata` files).
  ///
  /// These files are read by downstream builders to create build assets.
  ///
  /// When not null, the scratch space should be initialized over an existing
  /// directory (rather than a fresh one).
  ScratchSpace? fesScratchSpace;

  /// Whether the next recompile should be a recompile-restart.
  bool needsRecompileRestart = false;

  /// Looks for and loads a `.web.entrypoint.json` file if it exists.
  ///
  /// Returns whether or not the `.web.entrypoint.json` was found and loaded.
  ///
  /// Note that a build step can never read its own output, so this only ever
  /// loads state written by an earlier build phase, or by an earlier build.
  Future<bool> checkAndDeserializeState(BuildStep buildStep) async {
    final webEntrypointAsset = webEntrypointStateAssetId(
      buildStep.inputId.package,
    );
    if (!await buildStep.canRead(webEntrypointAsset)) return false;
    final contents = json.decode(
      await buildStep.readAsString(webEntrypointAsset),
    ) as Map<String, Object?>;
    // `WebEntrypointMarkerBuilder` writes an empty object when it doesn't find
    // an entrypoint, in which case there is no state to restore.
    if (contents['entrypoint'] case final String entrypoint) {
      entrypointAssetId = AssetId.parse(entrypoint);
      return true;
    }
    return false;
  }

  /// The active background compilation future.
  ///
  /// Allows arbitrary DDC builders to share a single compiler execution run for
  /// the entrypoint. Sequential calls chain onto the previous compilation.
  Future<void> _activeCompilation = Future.value();

  /// Returns a future that completes when the active compilation is complete.
  Future<void> waitForCompilation(AssetId entrypointId) {
    _verifyEntrypoint(entrypointId);
    return _activeCompilation;
  }

  /// Initiates the compilation of [entrypointId] using [compileFn].
  ///
  /// Sequential calls for the same entrypoint will subscribe to and share
  /// the same compilation future chain.
  void triggerSharedCompilation(
    AssetId entrypointId,
    Future<void> Function() compileFn,
  ) {
    _verifyEntrypoint(entrypointId);
    entrypointAssetId ??= entrypointId;

    final previous = _activeCompilation;
    final completer = Completer<void>();
    _activeCompilation = completer.future;

    () async {
      try {
        await previous;
        await compileFn();
        completer.complete();
      } catch (e, s) {
        completer.completeError(e, s);
      } finally {
        if (_activeCompilation == completer.future) {
          _activeCompilation = Future.value();
        }
      }
    }();
  }

  void _verifyEntrypoint(AssetId entrypointId) {
    if (entrypointAssetId != null && entrypointAssetId != entrypointId) {
      throw StateError(
        'Cannot compile a different entrypoint: '
        'expected $entrypointAssetId but got $entrypointId.',
      );
    }
  }
}

/// A shared [Resource] for a [FrontendServerState].
final frontendServerStateResource = Resource<FrontendServerState>(() async {
  return frontendServerState;
});
