// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../asset/id.dart';
import 'asset_deps.dart';
import 'phased_value.dart';

part 'phased_asset_deps.g.dart';

/// Serializable data from which library cycle graphs can be reconstructed.
///
/// Pass to `AssetDepsLoader.fromDeps` then use that to create a
/// `LibraryCycleGraphLoader`.
abstract class PhasedAssetDeps
    implements Built<PhasedAssetDeps, PhasedAssetDepsBuilder> {
  static Serializer<PhasedAssetDeps> get serializer =>
      _$phasedAssetDepsSerializer;

  BuiltMap<AssetId, PhasedValue<AssetDeps>> get assetDeps;

  factory PhasedAssetDeps([void Function(PhasedAssetDepsBuilder) b]) =
      _$PhasedAssetDeps;
  PhasedAssetDeps._();

  factory PhasedAssetDeps.of(Map<AssetId, PhasedValue<AssetDeps>> assetDeps) =>
      _$PhasedAssetDeps._(assetDeps: assetDeps.build());

  /// Returns `this` data with [other] added to it.
  ///
  /// For each asset: if [other] has a complete value for that asset, use the
  /// new value. Otherwise, use the old value from `this`.
  PhasedAssetDeps update(PhasedAssetDeps other) {
    final result = toBuilder();
    for (final entry in other.assetDeps.entries) {
      final updatedValue = entry.value;
      if (updatedValue.isComplete) {
        result.assetDeps[entry.key] = updatedValue;
      } else {
        // The only allow "not available yet" value is `AssetDeps.empty`.
        if (updatedValue.values.length != 1 ||
            updatedValue.values.single.value != AssetDeps.empty) {
          throw StateError('Unexpected value: $updatedValue');
        }
      }
    }
    return result.build();
  }

  /// The max phase before there is any incomplete data, or 0xffffffff if there
  /// is no incomplete data.
  @memoized
  int get phase {
    int? result;
    for (final entry in assetDeps.values) {
      if (!entry.isComplete) {
        if (result == null) {
          result = entry.expiresAfter;
        } else {
          result = min(result, entry.expiresAfter!);
        }
      }
    }
    return result ?? 0xffffffff;
  }
}
