// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../../contracts.dart';
import 'asset_deps.dart';
import 'phased_value.dart';

part 'phased_asset_deps.g.dart';

/// Serializable data from which library cycle graphs can be reconstructed.
///
/// Pass to `AssetDepsLoader.fromDeps` then use that to create a
/// `LibraryCycleGraphLoader`.
@Invariant(
  'assetDeps.keys.every((id) => id.package.isNotEmpty && id.path.isNotEmpty)',
)
abstract class PhasedAssetDeps
    implements Built<PhasedAssetDeps, PhasedAssetDepsBuilder> {
  static Serializer<PhasedAssetDeps> get serializer =>
      _$phasedAssetDepsSerializer;

  BuiltMap<AssetId, PhasedValue<AssetDeps>> get assetDeps;

  factory PhasedAssetDeps([void Function(PhasedAssetDepsBuilder) b]) =
      _$PhasedAssetDeps;
  PhasedAssetDeps._();

  /// Returns `this` data with [other] added to it.
  ///
  /// For each asset: if the value in [other] is
  /// [PhasedValue.isUnavailable], keep the old value from `this`; otherwise
  /// use the new value.
  ///
  /// A new value can be incomplete and still worth keeping: a shared part
  /// accumulates contributions phase by phase, so its deps are only final
  /// after the last phase that can contribute, which might be the last phase
  /// of the build.
  PhasedAssetDeps update(PhasedAssetDeps other) {
    final result = toBuilder();
    for (final entry in other.assetDeps.entries) {
      if (entry.value.isUnavailable) continue;
      result.assetDeps[entry.key] = entry.value;
    }
    return result.build();
  }

  PhasedAssetDeps complete() => rebuild((b) {
    for (final entry in assetDeps.entries) {
      final value = entry.value;
      if (!value.isComplete) {
        b.assetDeps[entry.key] = value.completed;
      }
    }
  });
}
