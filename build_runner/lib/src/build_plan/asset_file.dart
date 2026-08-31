// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_value/built_value.dart';

part 'asset_file.g.dart';

/// An asset with its physical location on disk: either in the source directory
/// or in the hidden cache directory.
abstract class AssetFile implements Built<AssetFile, AssetFileBuilder> {
  /// The logical asset identifier.
  AssetId get id;

  /// Whether the file is located in the hidden cache directory.
  bool get hidden;

  factory AssetFile(AssetId id, {required bool hidden}) =>
      _$AssetFile._(id: id, hidden: hidden);

  /// An asset in the source directory.
  factory AssetFile.source(AssetId id) => _$AssetFile._(id: id, hidden: false);

  /// An asset in the hidden cache directory.
  factory AssetFile.cache(AssetId id) => _$AssetFile._(id: id, hidden: true);

  AssetFile._();
}
