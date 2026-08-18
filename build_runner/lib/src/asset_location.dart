// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:path/path.dart' as p;

import 'build_plan/build_package.dart';
import 'constants.dart';
import 'io/asset_path_provider.dart';

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

  /// Converts a filesystem [path] within [package] to an [AssetLocation].
  factory AssetLocation.fromPath(BuildPackage package, String path) {
    final relativePath = _normalizeRelativePath(package, path);
    if (relativePath.startsWith('$generatedOutputDirectory/')) {
      final packagePath = relativePath.substring(
        generatedOutputDirectory.length + 1,
      );
      final firstSlash = packagePath.indexOf('/');
      if (firstSlash != -1) {
        final targetPackage = packagePath.substring(0, firstSlash);
        final targetPath = packagePath.substring(firstSlash + 1);
        return AssetLocation.cache(AssetId(targetPackage, targetPath));
      }
    }
    return AssetLocation.source(AssetId(package.name, relativePath));
  }

  static String _normalizeRelativePath(BuildPackage package, String path) {
    final pkgPath = package.path;
    final absolutePath = p.isAbsolute(path) ? path : p.absolute(path);
    if (!p.isWithin(pkgPath, absolutePath)) {
      throw ArgumentError('"$absolutePath" is not in "$pkgPath".');
    }
    return p.relative(absolutePath, from: pkgPath);
  }

  /// Converts this location to an [AssetId], hiding under [outputRoot] if in
  /// cache.
  AssetId toAssetId(String outputRoot) =>
      hidden ? AssetPathProvider.hide(id, outputRoot) : id;

  /// Converts [assetId] to an [AssetLocation], unpacking
  /// `.dart_tool/build/generated` paths if present.
  factory AssetLocation.fromAssetId(AssetId assetId) {
    if (assetId.path.startsWith('$generatedOutputDirectory/')) {
      final packagePath = assetId.path.substring(
        generatedOutputDirectory.length + 1,
      );
      final firstSlash = packagePath.indexOf('/');
      if (firstSlash != -1) {
        final targetPackage = packagePath.substring(0, firstSlash);
        final targetPath = packagePath.substring(firstSlash + 1);
        return AssetLocation.cache(AssetId(targetPackage, targetPath));
      }
    }
    return AssetLocation.source(assetId);
  }
}
