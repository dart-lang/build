// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:glob/glob.dart';
import 'package:watcher/watcher.dart';

import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../package_graph/target_graph.dart';
import '../util/constants.dart';

/// Finds build assets and computes changes to build assets.
class AssetTracker {
  final AssetReader _reader;
  final TargetGraph _targetGraph;

  AssetTracker(this._reader, this._targetGraph);

  /// Checks for and returns any file system changes compared to the current
  /// state of the asset graph.
  Future<Map<AssetId, ChangeType>> collectChanges(AssetGraph assetGraph) async {
    var inputSources = await findInputSources();
    var generatedSources = await findCacheDirSources();
    var internalSources = await findInternalSources();
    return computeSourceUpdates(
      inputSources,
      generatedSources,
      internalSources,
      assetGraph,
    );
  }

  /// Returns the all the sources found in the cache directory.
  Future<Set<AssetId>> findCacheDirSources() =>
      _listGeneratedAssetIds().toSet();

  /// Returns the set of original package inputs on disk.
  Future<Set<AssetId>> findInputSources() {
    final targets = Stream<TargetNode>.fromIterable(
      _targetGraph.allModules.values,
    );
    return targets.asyncExpand(_listAssetIds).toSet();
  }

  /// Returns all the internal sources, such as those under [entryPointDir].
  Future<Set<AssetId>> findInternalSources() async {
    var ids = await _listIdsSafe(Glob('$entryPointDir/**')).toSet();
    var packageConfigId = AssetId(
      _targetGraph.rootPackageConfig.packageName,
      '.dart_tool/package_config.json',
    );

    if (await _reader.canRead(packageConfigId)) {
      ids.add(packageConfigId);
    }
    return ids;
  }

  /// Finds the asset changes which have happened while unwatched between builds
  /// by taking a difference between the assets in the graph and the assets on
  /// disk.
  Future<Map<AssetId, ChangeType>> computeSourceUpdates(
    Set<AssetId> inputSources,
    Set<AssetId> generatedSources,
    Set<AssetId> internalSources,
    AssetGraph assetGraph,
  ) async {
    final allSources =
        <AssetId>{}
          ..addAll(inputSources)
          ..addAll(generatedSources)
          ..addAll(internalSources);
    var updates = <AssetId, ChangeType>{};
    void addUpdates(Iterable<AssetId> assets, ChangeType type) {
      for (var asset in assets) {
        updates[asset] = type;
      }
    }

    var newSources = inputSources.difference(
      assetGraph.allNodes
          .where((node) => node.isTrackedInput)
          .map((node) => node.id)
          .toSet(),
    );
    addUpdates(newSources, ChangeType.ADD);
    var removedAssets = assetGraph.allNodes
        .where((n) {
          if (!n.isFile) return false;
          if (n.type == NodeType.generated) {
            return n.wasOutput;
          }
          return true;
        })
        .map((n) => n.id)
        .where((id) => !allSources.contains(id));

    addUpdates(removedAssets, ChangeType.REMOVE);

    var originalGraphSources = assetGraph.sources.toSet();
    var preExistingSources = originalGraphSources.intersection(inputSources)
      ..addAll(internalSources.where(assetGraph.contains));
    for (final id in preExistingSources) {
      var node = assetGraph.get(id)!;
      var originalDigest = node.digest;
      if (originalDigest == null) continue;
      _reader.cache.invalidate([id]);
      var currentDigest = await _reader.digest(id);
      if (currentDigest != originalDigest) {
        updates[id] = ChangeType.MODIFY;
      }
    }
    return updates;
  }

  Stream<AssetId> _listAssetIds(TargetNode targetNode) {
    return targetNode.sourceIncludes.isEmpty
        ? const Stream<AssetId>.empty()
        : StreamGroup.merge(
          targetNode.sourceIncludes.map(
            (glob) => _listIdsSafe(glob, package: targetNode.package.name)
                .where(
                  (id) => _targetGraph.isVisibleInBuild(id, targetNode.package),
                )
                .where((id) => !targetNode.excludesSource(id)),
          ),
        );
  }

  Stream<AssetId> _listGeneratedAssetIds() {
    var glob = Glob('$generatedOutputDirectory/**');

    return _listIdsSafe(glob)
        .map((id) {
          var packagePath = id.path.substring(
            generatedOutputDirectory.length + 1,
          );
          var firstSlash = packagePath.indexOf('/');
          if (firstSlash == -1) return null;
          var package = packagePath.substring(0, firstSlash);
          var path = packagePath.substring(firstSlash + 1);
          return AssetId(package, path);
        })
        .where((id) => id != null)
        .cast<AssetId>();
  }

  /// Lists asset IDs and swallows file not found errors.
  ///
  /// Ideally we would warn but in practice the default sources list will give
  /// this error a lot and it would be noisy.
  Stream<AssetId> _listIdsSafe(Glob glob, {String? package}) => _reader
      .assetFinder
      .find(glob, package: package)
      .handleError(
        (void _) {},
        test: (e) => e is FileSystemException && e.osError?.errorCode == 2,
      );
}
