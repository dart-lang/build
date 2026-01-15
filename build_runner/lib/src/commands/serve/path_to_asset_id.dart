// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:path/path.dart' as p;

/// Converts [pathSegments] to `AssetId`s.
///
/// A path segment of `packages` is special, it is followed by a path segment
/// giving the package name then path segments giving the path under `lib`.
/// In this case, two `AssetId`s are returned: one ignoring the package mapping
/// then one with the package mapping.
List<AssetId> pathToAssetIds(
  String outputRootPackage,
  String rootDir,
  List<String> pathSegments,
) {
  final result = <AssetId>[
    AssetId(outputRootPackage, p.joinAll([rootDir, ...pathSegments])),
  ];
  final packagesIndex = pathSegments.indexOf('packages');
  if (packagesIndex >= 0 && pathSegments.length - packagesIndex > 2) {
    final package = pathSegments[packagesIndex + 1];
    final path = p.joinAll(pathSegments.sublist(packagesIndex + 2));
    result.add(AssetId(package, p.join('lib', path)));
  }
  return result;
}

/// Returns null for paths that neither a lib nor starts from a rootDir
String? assetIdToPath(AssetId assetId, String rootDir) =>
    assetId.path.startsWith('lib/')
        ? assetId.path.replaceFirst('lib/', 'packages/${assetId.package}/')
        : assetId.path.startsWith('$rootDir/')
        ? assetId.path.substring(rootDir.length + 1)
        : null;
