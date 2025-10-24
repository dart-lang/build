// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

/// A persistent shared [FrontendServerState] for DDC workers that interact with
/// the Frontend Server.
final frontendServerState = FrontendServerState();

class FrontendServerState {
  /// The built app's main entrypoint file.
  ///
  /// This must be set before any asset builders run when compiling with DDC and
  /// hot reload.
  late AssetId entrypointAssetId;
}

/// A shared [Resource] for a [FrontendServerState].
final frontendServerStateResource = Resource<FrontendServerState>(() async {
  return frontendServerState;
});
