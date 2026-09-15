// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_value/built_value.dart';

part 'asset_file.g.dart';

/// An asset with its physical location on disk: either at its package path or
/// in the artifact tree.
abstract class AssetFile implements Built<AssetFile, AssetFileBuilder> {
  /// The logical asset identifier.
  AssetId get id;

  /// Whether the file is located in the artifact tree.
  bool get inArtifactTree;

  /// Whether the file is located at its package path.
  bool get atPackagePath => !inArtifactTree;

  factory AssetFile(AssetId id, {required bool inArtifactTree}) =>
      _$AssetFile._(id: id, inArtifactTree: inArtifactTree);

  /// An asset at its package path.
  factory AssetFile.atPackagePath(AssetId id) =>
      _$AssetFile._(id: id, inArtifactTree: false);

  /// An asset in the artifact tree.
  factory AssetFile.inArtifactTree(AssetId id) =>
      _$AssetFile._(id: id, inArtifactTree: true);

  AssetFile._();
}
