// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:mirrors';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../asset/reader.dart';
import '../asset_graph/graph.dart';
import '../package_graph/package_graph.dart';

class BuildScriptUpdates {
  final Set<AssetId> _allSources;
  final bool _supportsIncrementalRebuilds;

  BuildScriptUpdates._(this._supportsIncrementalRebuilds, this._allSources);

  static Future<BuildScriptUpdates> create(RunnerAssetReader reader,
      PackageGraph packageGraph, AssetGraph graph) async {
    bool supportsIncrementalRebuilds = true;
    var rootPackage = packageGraph.root.name;
    Set<AssetId> allSources;
    var logger = new Logger('BuildScriptUpdates');
    try {
      allSources = _urisForThisScript
          .map((id) => _idForUri(id, rootPackage))
          .where((id) => id != null)
          .toSet();
      var missing = allSources.firstWhere((id) => !graph.contains(id),
          orElse: () => null);
      if (missing != null) {
        supportsIncrementalRebuilds = false;
        logger.warning('$missing was not found in the asset graph, '
            'incremental builds will not work.\n This probably means you '
            'don\'t have your dependencies specified fully in your '
            'pubspec.yaml.');
      } else {
        // Make sure we are tracking changes for all ids in [allSources].
        for (var id in allSources) {
          var node = graph.get(id);
          node.lastKnownDigest ??= await reader.digest(id);
        }
      }
    } on ArgumentError catch (_) {
      supportsIncrementalRebuilds = false;
      allSources = new Set<AssetId>();
    }
    return new BuildScriptUpdates._(supportsIncrementalRebuilds, allSources);
  }

  static Iterable<Uri> get _urisForThisScript =>
      currentMirrorSystem().libraries.keys;

  /// Checks if the current running program has been updated, based on
  /// [updatedIds].
  bool hasBeenUpdated(Set<AssetId> updatedIds) {
    if (!_supportsIncrementalRebuilds) return true;
    return updatedIds.intersection(_allSources).isNotEmpty;
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
        var relativePath = p.relative(uri.toFilePath(), from: p.current);
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
