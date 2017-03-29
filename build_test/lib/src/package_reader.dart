// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:package_resolver/package_resolver.dart';

/// Resolves using a [SyncPackageResolver] before reading from the file system.
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
  static Future<PackageAssetReader> currentIsolate({String rootPackage}) async {
    var resolver = PackageResolver.current;
    return new PackageAssetReader(await resolver.asSync, rootPackage);
  }

  File _resolve(AssetId id) {
    // Gets around inconsistencies with asset URIs.
    //
    // Sometimes build_test|build_test.dart = package:build_test/build_test.dart
    // and sometimes you need |lib/build_test.dart. The package resolver is the
    // former, so a prefix of 'lib/' results in 'lib/lib/'.
    //
    // TODO: https://github.com/dart-lang/build/issues/238.
    if (id.path.startsWith('lib/')) {
      id = new AssetId(id.package, id.path.substring('lib/'.length));
    }
    return new File.fromUri(_packageResolver.urlFor(id.package, id.path));
  }

  @override
  Iterable<AssetId> findAssets(Glob glob) {
    if (_rootPackage == null) {
      throw new UnsupportedError('Root package must be provided to use.');
    }
    var rootPackagePath = _packageResolver.packagePath(_rootPackage);
    return glob
        .listSync(root: rootPackagePath)
        .where((entity) => entity is File)
        .map((file) => _toAsset(file.path, rootPackagePath, glob));
  }

  AssetId _toAsset(String path, String rootPackagePath, Glob glob) {
    var relative = glob.context.relative(path, from: rootPackagePath);
    return new AssetId(_rootPackage, relative);
  }

  @override
  Future<bool> hasInput(AssetId id) async => _resolve(id).exists();

  @override
  Future<List<int>> readAsBytes(AssetId id) => _resolve(id).readAsBytes();

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) async {
    return _resolve(id).readAsString(encoding: encoding);
  }
}
