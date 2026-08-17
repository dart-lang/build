// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'asset_location.g.dart';

/// An [AssetId] and its location, either in the source tree or in the hidden
/// build cache.
abstract class AssetLocation
    implements Built<AssetLocation, AssetLocationBuilder> {
  static Serializer<AssetLocation> get serializer => _$assetLocationSerializer;

  AssetId get id;

  /// Whether the asset is in the hidden build cache instead of the source tree.
  bool get hidden;

  factory AssetLocation([void Function(AssetLocationBuilder)? updates]) =
      _$AssetLocation;
  AssetLocation._();

  /// An asset in the visible source tree.
  factory AssetLocation.source(AssetId id) => AssetLocation(
    (b) => b
      ..id = id
      ..hidden = false,
  );

  /// An asset in the hidden build cache.
  factory AssetLocation.cache(AssetId id) => AssetLocation(
    (b) => b
      ..id = id
      ..hidden = true,
  );
}
