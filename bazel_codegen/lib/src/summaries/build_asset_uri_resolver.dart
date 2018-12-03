// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:analyzer/src/generated/engine.dart' show TimestampedData;
import 'package:analyzer/src/generated/source.dart';
import 'package:build/build.dart' show AssetId;
import 'package:path/path.dart' as p;

typedef Future<String> ReadAsset(AssetId assetId);

/// A [UriResolver] which can read build assets by reading them as strings.
///
/// Will only read each asset once. This resolver does not handle cases where
/// assets may change during a build process.
class BuildAssetUriResolver implements UriResolver {
  final _knownAssets = <Uri, Source>{};

  /// Read all [assets] with the extension '.dart' using the [read] function up
  /// front and cache them as a [Source].
  Future<Null> addAssets(Iterable<AssetId> assets, ReadAsset read) async {
    for (var asset in assets.where((asset) => asset.path.endsWith('.dart'))) {
      var uri = assetUri(asset);
      if (!_knownAssets.containsKey(uri)) {
        _knownAssets[uri] = AssetSource(asset, await read(asset), true);
      }
    }
  }

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) => _knownAssets.putIfAbsent(
      uri,
      () => uri.scheme == 'dart'
          ? null
          : AssetSource(AssetId.resolve(uri.toString()), null, false));

  @override
  Uri restoreAbsolute(Source source) {
    throw UnimplementedError();
  }
}

class AssetSource implements Source {
  final AssetId _assetId;
  final String _content;
  final bool _exists;

  AssetSource(this._assetId, this._content, this._exists);

  @override
  TimestampedData<String> get contents => _exists
      ? TimestampedData(0, _content)
      : throw StateError('Attempted to read non-existent source');

  @override
  String get encoding => '$_assetId';

  @override
  String get fullName => '$_assetId';

  @override
  int get hashCode => _assetId.hashCode;

  @override
  bool get isInSystemLibrary => false;

  @override
  Source get librarySource => null;

  @override
  int get modificationStamp => 0;

  @override
  String get shortName => p.basename(_assetId.path);

  @override
  Source get source => this;

  @override
  Uri get uri => assetUri(_assetId);

  @override
  UriKind get uriKind {
    if (_assetId.path.startsWith('lib/')) return UriKind.PACKAGE_URI;
    return UriKind.FILE_URI;
  }

  @override
  bool operator ==(Object other) =>
      other is AssetSource && other._assetId == _assetId;

  @override
  bool exists() => _exists;

  @override
  String toString() => 'AssetSource[$_assetId]';
}

Uri assetUri(AssetId assetId) => assetId.path.startsWith('lib/')
    ? Uri(
        scheme: 'package',
        path: '${assetId.package}/${assetId.path.replaceFirst('lib/', '')}')
    : Uri(scheme: 'asset', path: '${assetId.package}/${assetId.path}');
