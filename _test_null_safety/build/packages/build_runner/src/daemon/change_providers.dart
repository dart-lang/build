// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_daemon/change_provider.dart';
// ignore: implementation_imports
import 'package:build_runner_core/src/asset_graph/graph.dart';
// ignore: implementation_imports
import 'package:build_runner_core/src/generate/build_definition.dart';
import 'package:watcher/watcher.dart' show WatchEvent;

/// Continually updates the [changes] stream as watch events are seen on the
/// input stream.
///
/// The [collectChanges] method is a no-op for this implementation.
class AutoChangeProvider implements ChangeProvider {
  @override
  final Stream<List<WatchEvent>> changes;

  AutoChangeProvider(this.changes);

  @override
  Future<List<WatchEvent>> collectChanges() async => [];
}

/// Computes changes with a file scan when requested by a call to
/// [collectChanges].
class ManualChangeProvider implements ChangeProvider {
  final AssetGraph _assetGraph;
  final AssetTracker _assetTracker;

  ManualChangeProvider(this._assetTracker, this._assetGraph);

  @override
  Future<List<WatchEvent>> collectChanges() async {
    var updates = await _assetTracker.collectChanges(_assetGraph);
    return List.of(updates.entries
        .map((entry) => WatchEvent(entry.value, '${entry.key}')));
  }

  @override
  Stream<List<WatchEvent>> get changes => Stream.empty();
}
