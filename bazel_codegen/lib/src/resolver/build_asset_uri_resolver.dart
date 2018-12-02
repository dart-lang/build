// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:build/build.dart' show AssetId;
import 'package:path/path.dart' as p;

typedef Future<String> ReadAsset(AssetId assetId);

/// A [UriResolver] which can read build assets by reading them as strings.
///
/// Will only read each asset once. This resolver does not handle cases where
/// assets may change during a build process.
class BuildAssetUriResolver extends UriResolver {
  final _cachedAssets = Set<AssetId>();
  final resourceProvider = MemoryResourceProvider();

  /// Read all [assets] with the extension '.dart' using the [read] function up
  /// front and cache them as a [Source].
  Future<Null> addAssets(Iterable<AssetId> assets, ReadAsset read) async {
    for (var asset in assets
        .where((asset) => asset.path.endsWith('.dart'))
        .where(_cachedAssets.add)) {
      resourceProvider.newFile(assetPath(asset), await read(asset));
    }
  }

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    final cachedId = _lookupAsset(uri);
    if (cachedId == null) return null;
    return resourceProvider
        .getFile(assetPath(cachedId))
        .createSource(cachedId.uri);
  }

  @override
  Uri restoreAbsolute(Source source) => _lookupAsset(source.uri)?.uri;

  /// Attempts to parse [uri] into an [AssetId] and returns it if it is cached.
  ///
  /// Handles 'package:' or 'asset:' URIs, as well as 'file:' URIs that have the
  /// same pattern used by [assetPath].
  ///
  /// Returns null if the Uri cannot be parsed or is not cached.
  AssetId _lookupAsset(Uri uri) {
    if (uri.isScheme('dart')) return null;
    final id = (uri.isScheme('package') ||
            uri.isScheme('asset') ||
            uri.isScheme('file'))
        ? AssetId.resolve('$uri')
        : null;
    return _cachedAssets.lookup(id);
  }
}

String assetPath(AssetId assetId) =>
    p.url.join('/${assetId.package}', assetId.path);
