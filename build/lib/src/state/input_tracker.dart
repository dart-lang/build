// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import '../asset/id.dart';

/// Records inputs for each generator.
class InputTracker {
  final _inputs = HashMap<AssetId, HashSet<AssetId>>();

  HashSet<AssetId> _getInputs(AssetId primaryInput) =>
      _inputs.putIfAbsent(primaryInput, HashSet.new);

  void add({required AssetId primaryInput, required AssetId input}) {
    _getInputs(primaryInput).add(input);
  }

  void addAll({
    required AssetId primaryInput,
    required Iterable<AssetId> inputs,
  }) {
    _getInputs(primaryInput).addAll(inputs);
  }

  Set<AssetId> inputsOf({required AssetId primaryInput}) =>
      _getInputs(primaryInput);

  Set<AssetId> allInputs() => _inputs.values.expand((s) => s).toSet();

  void clear({required AssetId primaryInput}) {
    _getInputs(primaryInput).clear();
  }
}
