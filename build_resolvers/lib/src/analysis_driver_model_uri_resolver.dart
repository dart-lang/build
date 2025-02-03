// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/source/file_source.dart';
// ignore: implementation_imports
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import 'analysis_driver_model.dart';

const _ignoredSchemes = ['dart', 'dart-ext'];

/// A [UriResolver] on top of [AnalysisDriverModel]'s in-memory filesystem
///
/// This is the analyzer's view of the current build: the files that
/// `build_runner` wants the analyzer to analyze.
///
/// The in-memory filesystem uses POSIX-style paths with `package:foo/bar'
/// mapping to `/foo/bar`.
class AnalysisDriverModelUriResolver implements UriResolver {
  final AnalysisDriverModel analysisDriverModel;
  AnalysisDriverModelUriResolver(this.analysisDriverModel);

  @override
  Source? resolveAbsolute(Uri uri, [Uri? actualUri]) {
    final assetId = parseAsset(uri);
    if (assetId == null) return null;

    var file = analysisDriverModel.resourceProvider.getFile(assetPath(assetId));
    return FileSource(file, assetId.uri);
  }

  @override
  Uri pathToUri(String path) {
    var pathSegments = p.posix.split(path);
    var packageName = pathSegments[1];
    if (pathSegments[2] == 'lib') {
      return Uri(
        scheme: 'package',
        pathSegments: [packageName].followedBy(pathSegments.skip(3)),
      );
    } else {
      return Uri(
        scheme: 'asset',
        pathSegments: [packageName].followedBy(pathSegments.skip(2)),
      );
    }
  }

  /// Attempts to parse [uri] into an [AssetId].
  ///
  /// Handles 'package:' or 'asset:' URIs, as well as 'file:' URIs that have the
  /// same pattern used by [assetPath].
  ///
  /// Returns null if the Uri cannot be parsed.
  static AssetId? parseAsset(Uri uri) {
    if (_ignoredSchemes.any(uri.isScheme)) return null;
    if (uri.isScheme('package') || uri.isScheme('asset')) {
      return AssetId.resolve(uri);
    }
    if (uri.isScheme('file')) {
      final parts = p.split(uri.path);
      return AssetId(parts[1], p.posix.joinAll(parts.skip(2)));
    }
    return null;
  }

  static String assetPath(AssetId assetId) =>
      p.posix.join('/${assetId.package}', assetId.path);
}
