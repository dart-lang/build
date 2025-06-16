// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';

/// Records inputs for a `BuildStep`.
class InputTracker {
  /// If set, when an `InputTracker` is instantiated it is stored in
  /// `inputTrackers`.
  static bool captureInputTrackersForTesting = false;

  /// All `InputTracker`s created when `captureInputTrackersForTesting` is set,
  /// keyed by filesystem to split by test case.
  ///
  /// TODO(davidmorgan): find a nicer way to do this.
  static Map<Filesystem, List<InputTracker>> inputTrackersForTesting =
      Map.identity();

  final HashSet<AssetId> _inputs = HashSet<AssetId>();
  final HashSet<AssetId> _resolverEntrypoints = HashSet<AssetId>();

  /// Creates an input tracker.
  ///
  /// [filesystem] is used to distinguish input trackers for testing, because
  /// each test case creates a new in-memory filesystem. It's not used
  /// otherwise.
  InputTracker(Filesystem filesystem) {
    if (captureInputTrackersForTesting) {
      inputTrackersForTesting.putIfAbsent(filesystem, () => []).add(this);
    }
  }

  void add(AssetId input) => _inputs.add(input);

  void addResolverEntrypoint(AssetId graph) => _resolverEntrypoints.add(graph);

  Set<AssetId> get inputs => _inputs;
  Set<AssetId> get resolverEntrypoints => _resolverEntrypoints;

  void clear() {
    _inputs.clear();
    _resolverEntrypoints.clear();
  }
}
