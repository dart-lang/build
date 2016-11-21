// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import '../asset/id.dart';
import 'build_step.dart';
import 'builder.dart';

/// A [Builder] that runs multiple delegate builders asynchronously.
///
/// **Note**: All builders are ran without ordering guarantees. Thus, none of
/// the builders can use the outputs of other builders in this group. All
/// builders must also have distinct outputs.
class MultiplexingBuilder implements Builder {
  final Iterable<Builder> _builders;

  MultiplexingBuilder(this._builders);

  @override
  Future build(BuildStep buildStep) =>
      Future.wait(_builders.map((builder) => builder.build(buildStep)));

  /// Collects declared outputs from all of the builders.
  ///
  /// If multiple builders declare the same output it will appear in this List
  /// more than once. This should be considered an error.
  @override
  List<AssetId> declareOutputs(AssetId inputId) =>
      _collectOutputs(inputId).toList();

  Iterable<AssetId> _collectOutputs(AssetId id) sync* {
    for (var builder in _builders) {
      yield* builder.declareOutputs(id);
    }
  }

  @override
  String toString() => '$_builders';
}
