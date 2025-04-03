// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  AssetSet inputs = AssetSet();

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

  void add(AssetId input) =>
      inputs = inputs.rebuild((b) => b..assets.add(input));

  void addAll({required Iterable<AssetId> inputs}) =>
      this.inputs = this.inputs.rebuild((b) => b..assets.addAll(inputs));

  void addGraph(LibraryCycleGraph graph) =>
      inputs = inputs.rebuild((b) => b..graphs.add(graph));

  void clear() {
    inputs = AssetSet();
  }
}
