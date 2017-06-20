// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:package_resolver/package_resolver.dart';
import 'package:path/path.dart' as p;

/// Resolves using a [SyncPackageResolver] before reading from the file system.
///
/// For a simple implementation that uses the current isolate's package
/// resolution logic (i.e. whatever you have generated in `.packages` in most
/// cases), use [currentIsolate]:
/// ```dart
/// var assetReader = await PackageAssetReader.currentIsolate();
/// ```
class PackageAssetReader implements AssetReader {
  final SyncPackageResolver _packageResolver;

  /// What package is the originating build occurring in.
  final String _rootPackage;

  /// Wrap a [SyncPackageResolver] to identify where files are located.
  ///
  /// To use a normal [PackageResolver] use `asSync`:
  /// ```
  /// new PackageAssetReader(await packageResolver.asSync);
  /// ```
  const PackageAssetReader(this._packageResolver, [this._rootPackage]);

  /// A reader that can resolve files known to the current isolate.
  ///
  /// A [rootPackage] should be provided for full API compatibility.
  static Future<PackageAssetReader> currentIsolate({String rootPackage}) async {
    var resolver = PackageResolver.current;
    return new PackageAssetReader(await resolver.asSync, rootPackage);
  }

  File _resolve(AssetId id) => new File(p
      .canonicalize(p.join(_packageResolver.packagePath(id.package), id.path)));

  @override
  Iterable<AssetId> findAssets(Glob glob) {
    if (_rootPackage == null) {
      throw new UnsupportedError('Root package must be provided to use.');
    }
    var rootPackagePath = _packageResolver.packagePath(_rootPackage);
    if (rootPackagePath == null) {
      throw new StateError('Could not resolve "$_rootPackage".');
    }
    return _globAssets(_rootPackage, rootPackagePath, glob);
  }

  @override
  FutureOr<bool> canRead(AssetId id) => _resolve(id).exists();

  @override
  Future<List<int>> readAsBytes(AssetId id) => _resolve(id).readAsBytes();

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) =>
      _resolve(id).readAsString(encoding: encoding);
}

/// Returns all assets that match [glob] in [package] with a [path].
Iterable<AssetId> _globAssets(String package, String path, Glob glob) {
  return glob
      .listSync(root: path)
      .where((entity) => entity is File)
      .map((file) {
    var relative = p.relative(file.path, from: path);
    return new AssetId(package, relative);
  });
}
