// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:mirrors';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../asset_graph/graph.dart';
import '../generate/options.dart';

class BuildScriptUpdates {
  final Set<AssetId> _allAssetIds;
  final bool _supportsIncrementalRebuilds;

  BuildScriptUpdates._(this._supportsIncrementalRebuilds, this._allAssetIds);

  static Future<BuildScriptUpdates> create(
      BuildOptions options, AssetGraph graph) async {
    bool supportsIncrementalRebuilds = true;
    var rootPackage = options.packageGraph.root.name;
    Set<AssetId> allAssetIds;
    var logger = new Logger('BuildScriptUpdates');
    try {
      allAssetIds = _urisForThisScript
          .map((id) => _idForUri(id, rootPackage))
          .where((id) => id != null)
          .toSet();
      var missing = allAssetIds.firstWhere((id) => !graph.contains(id),
          orElse: () => null);
      if (missing != null) {
        supportsIncrementalRebuilds = false;
        logger.warning('$missing was not found in the asset graph, '
            'incremental builds will not work.\n This probably means you '
            'don\'t have your dependencies specified fully in your '
            'pubspec.yaml.');
      } else {
        // Make sure we are tracking changes for all ids in [allAssetIds].
        for (var id in allAssetIds) {
          var node = graph.get(id);
          if (node.lastKnownDigest == null) {
            node.lastKnownDigest = await options.reader.digest(id);
          }
        }
      }
    } on ArgumentError catch (_) {
      supportsIncrementalRebuilds = false;
      allAssetIds = new Set<AssetId>();
    }
    return new BuildScriptUpdates._(supportsIncrementalRebuilds, allAssetIds);
  }

  static Iterable<Uri> get _urisForThisScript =>
      currentMirrorSystem().libraries.keys;

  /// Checks if the current running program has been updated, based on
  /// [updatedIds].
  bool hasBeenUpdated(Set<AssetId> updatedIds) {
    if (!_supportsIncrementalRebuilds) return true;
    return updatedIds.intersection(_allAssetIds).isNotEmpty;
  }

  /// Attempts to return an [AssetId] for [uri].
  ///
  /// Returns `null` if the uri should be ignored, or throws an [ArgumentError]
  /// if the [uri] is not recognized.
  static AssetId _idForUri(Uri uri, String _rootPackage) {
    switch (uri.scheme) {
      case 'dart':
        // TODO: check for sdk updates!
        break;
      case 'package':
        var parts = uri.pathSegments;
        return new AssetId(parts[0],
            p.url.joinAll(['lib']..addAll(parts.getRange(1, parts.length))));
      case 'file':
        var relativePath = p.relative(uri.path, from: p.current);
        return new AssetId(_rootPackage, relativePath);
      case 'data':
        // Test runner uses a `data` scheme, don't invalidate for those.
        if (uri.path.contains('package:test')) break;
        continue unsupported;
      case 'http':
        continue unsupported;
      unsupported:
      default:
        throw new ArgumentError(
            'Unsupported uri scheme `${uri.scheme}` found for '
            'library in build script.\n'
            'This probably means you are running in an unsupported '
            'context, such as in an isolate or via `pub run`.\n'
            'Full uri was: $uri.');
    }
    return null;
  }
}
