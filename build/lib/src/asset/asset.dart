// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'id.dart';

/// Abstract representation of an asset. See [StringAsset] or [BytesAsset] for
/// concrete implementation.
abstract class Asset {
  AssetId get id;
}

/// A fully realized asset whose contents are a [String].
class StringAsset implements Asset {
  @override
  final AssetId id;

  final String string;

  StringAsset(this.id, this.string);

  @override
  String toString() => 'StringAsset: $id';
}

/// A fully realized asset whose contents are a [List<int>].
class BytesAsset implements Asset {
  @override
  final AssetId id;

  final List<int> bytes;

  BytesAsset(this.id, this.bytes);

  @override
  String toString() => 'BytesAsset: $id';
}
