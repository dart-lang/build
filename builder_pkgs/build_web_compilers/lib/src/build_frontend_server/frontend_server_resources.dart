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
    final webEntrypointAsset = AssetId(
      buildStep.inputId.package,
      '.web.entrypoint.json',
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
      } finally {
        if (_activeCompilation == completer.future) {
          _activeCompilation = Future.value();
        }
        completer.complete();
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
