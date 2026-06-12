// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';

/// A persistent shared [FrontendServerState] for DDC workers that interact with
/// the Frontend Server.
final frontendServerState = FrontendServerState();

class FrontendServerState {
  /// The built app's main entrypoint file.
  ///
  /// This must be set before any asset builders run when compiling with DDC and
  /// hot reload.
  AssetId? entrypointAssetId;

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

  /// The custom scratch space path provided to the builder, if any.
  String? customScratchSpacePath;

  /// Looks for and loads a `.web.entrypoint.json` file if it exists.
  ///
  /// Returns whether or not the `.web.entrypoint.json` was found and loaded.
  Future<bool> checkAndDeserializeState(BuildStep buildStep) async {
    final rootDir = p.dirname(buildStep.inputId.path);
    final webEntrypointAsset = AssetId(
      buildStep.inputId.package,
      p.join(rootDir, '.web.entrypoint.json'),
    );
    if (await buildStep.canRead(webEntrypointAsset)) {
      final contents = json.decode(
        await buildStep.readAsString(webEntrypointAsset),
      ) as Map<String, Object?>;
      entrypointAssetId = AssetId.parse(contents['entrypoint'] as String);
      return true;
    }
    return false;
  }

  /// Tracks active background compilations keyed by their entrypoint [AssetId].
  ///
  /// Allows arbitrary DDC builders to share a single compiler execution run for
  /// an entrypoint. Typically the entrypoint for all builders - except for
  /// certain tests with multiple targets in the entrypoint.
  final Map<AssetId, Future<void>> _activeCompilations = {};

  /// Returns a future that completes when the compilation for [entrypointId]
  /// is complete, or immediately if there is no active compilation.
  Future<void> waitForCompilation(AssetId entrypointId) {
    return _activeCompilations[entrypointId] ?? Future.value();
  }

  /// Initiates the compilation of [entrypointId] using [compileFn] if no
  /// compilation is currently active.
  ///
  /// Concurrent calls for the same entrypoint will subscribe to and share
  /// the same compilation future. The future is automatically removed from
  /// the active registry once it completes or fails.
  void triggerSharedCompilation(
    AssetId entrypointId,
    Future<void> Function() compileFn,
  ) {
    _activeCompilations.putIfAbsent(entrypointId, () async {
      try {
        await compileFn();
      } finally {
        clearCompilation(entrypointId);
      }
    });
  }

  /// Cancels the cached compilation future for [entrypointId].
  void clearCompilation(AssetId entrypointId) {
    _activeCompilations.remove(entrypointId);
  }
}

/// A shared [Resource] for a [FrontendServerState].
final frontendServerStateResource = Resource<FrontendServerState>(() async {
  return frontendServerState;
});
