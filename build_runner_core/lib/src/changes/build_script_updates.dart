// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:mirrors';

import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../asset_graph/graph.dart';
import '../package_graph/package_graph.dart';

/// Functionality for detecting if the build script itself or any of its
/// transitive imports have changed.
abstract class BuildScriptUpdates {
  /// Checks if the current running program has been updated, based on
  /// [updatedIds].
  bool hasBeenUpdated(Set<AssetId> updatedIds);

  /// Creates a [BuildScriptUpdates] object, using [reader] to ensure that
  /// the [assetGraph] is tracking digests for all transitive sources.
  ///
  /// If [disabled] is `true` then all checks are skipped and
  /// [hasBeenUpdated] will always return `false`.
  static Future<BuildScriptUpdates> create(
    AssetReader reader,
    PackageGraph packageGraph,
    AssetGraph assetGraph, {
    bool disabled = false,
  }) async {
    if (disabled) return _NoopBuildScriptUpdates();
    return _MirrorBuildScriptUpdates.create(reader, packageGraph, assetGraph);
  }
}

/// Uses mirrors to find all transitive imports of the current script.
class _MirrorBuildScriptUpdates implements BuildScriptUpdates {
  final Set<AssetId> _allSources;
  final bool _supportsIncrementalRebuilds;

  _MirrorBuildScriptUpdates._(
    this._supportsIncrementalRebuilds,
    this._allSources,
  );

  static Future<BuildScriptUpdates> create(
    AssetReader reader,
    PackageGraph packageGraph,
    AssetGraph graph,
  ) async {
    var supportsIncrementalRebuilds = true;
    Set<AssetId> allSources;
    var logger = Logger('BuildScriptUpdates');
    try {
      allSources =
          _urisForThisScript
              .map((id) => idForUri(id, packageGraph))
              .nonNulls
              .toSet();
      var missing = allSources.firstWhereOrNull((id) => !graph.contains(id));
      if (missing != null) {
        supportsIncrementalRebuilds = false;
        logger.warning(
          '$missing was not found in the asset graph, '
          'incremental builds will not work.\n This probably means you '
          'don\'t have your dependencies specified fully in your '
          'pubspec.yaml.',
        );
      } else {
        // Make sure we are tracking changes for all ids in [allSources].
        for (var id in allSources) {
          final node = graph.get(id)!;
          if (node.digest == null) {
            final digest = await reader.digest(id);
            graph.updateNode(id, (nodeBuilder) {
              nodeBuilder.digest = digest;
            });
          }
        }
      }
    } on ArgumentError // ignore: avoid_catching_errors
    catch (_) {
      supportsIncrementalRebuilds = false;
      allSources = <AssetId>{};
    }
    return _MirrorBuildScriptUpdates._(supportsIncrementalRebuilds, allSources);
  }

  static Iterable<Uri> get _urisForThisScript =>
      currentMirrorSystem().libraries.keys;

  /// Checks if the current running program has been updated, based on
  /// [updatedIds].
  @override
  bool hasBeenUpdated(Set<AssetId> updatedIds) {
    if (!_supportsIncrementalRebuilds) return true;
    return updatedIds.intersection(_allSources).isNotEmpty;
  }
}

/// Always returns false for [hasBeenUpdated], used when we want to skip
/// the build script checks.
class _NoopBuildScriptUpdates implements BuildScriptUpdates {
  @override
  bool hasBeenUpdated(void _) => false;
}

/// Attempts to return an [AssetId] for [uri].
///
/// Returns `null` if the uri should be ignored, or throws an [ArgumentError]
/// if the [uri] is not recognized.
@visibleForTesting
AssetId? idForUri(Uri uri, PackageGraph packageGraph) {
  switch (uri.scheme) {
    case 'dart':
      // TODO: check for sdk updates!
      break;
    case 'package':
      var parts = uri.pathSegments;
      return AssetId(
        parts[0],
        p.url.joinAll(['lib', ...parts.getRange(1, parts.length)]),
      );
    case 'file':
      final package = packageGraph.asPackageConfig.packageOf(
        Uri.file(p.canonicalize(uri.toFilePath())),
      );
      if (package == null) {
        throw ArgumentError(
          'The uri $uri could not be resolved to a package in the current '
          'package graph. Do you have a dependency on the package '
          'containing this uri?',
        );
      }
      // The `AssetId` constructor normalizes this path to a URI style.
      var relativePath = p.relative(
        uri.toFilePath(),
        from: package.root.toFilePath(),
      );
      return AssetId(package.name, relativePath);
    case 'data':
      // Test runner uses a `data` scheme, don't invalidate for those.
      if (uri.path.contains('package:test')) break;
      continue unsupported;
    case 'http':
      continue unsupported;
    unsupported:
    default:
      throw ArgumentError(
        'Unsupported uri scheme `${uri.scheme}` found for '
        'library in build script.\n'
        'This probably means you are running in an unsupported '
        'context, such as in an isolate or via `dart run`.\n'
        'Full uri was: $uri.',
      );
  }
  return null;
}
