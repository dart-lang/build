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
class BuildAssetUriResolver implements UriResolver {
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
    if (uri.isScheme('dart')) return null;
    final id = (uri.isScheme('package') || uri.isScheme('asset'))
        ? AssetId.resolve('$uri')
        : AssetId(p.split(uri.path).elementAt(1),
            p.joinAll(p.split(uri.path).skip(2)));
    if (!_cachedAssets.contains(id)) return null;
    return resourceProvider.getFile(assetPath(id)).createSource();
  }

  @override
  Uri restoreAbsolute(Source source) => p.toUri(source.fullName);
}

Uri assetUri(AssetId assetId) =>
    p.toUri(p.url.join('/${assetId.package}', assetId.path));

String assetPath(AssetId assetId) =>
    p.url.join('/${assetId.package}', assetId.path);
