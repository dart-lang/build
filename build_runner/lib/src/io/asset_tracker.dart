// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:watcher/watcher.dart';

import '../build/asset_graph/graph.dart';
import '../build/asset_graph/node.dart';
import '../build_plan/target_graph.dart';
import '../constants.dart';
import '../logging/timed_activities.dart';
import 'reader_writer.dart';

/// Finds build assets and computes changes to build assets.
class AssetTracker {
  final ReaderWriter _readerWriter;
  final Iterable<TargetGraph> _targetGraphs;

  AssetTracker(this._readerWriter, this._targetGraphs);

  /// Checks for and returns any file system changes compared to the current
  /// state of the asset graph.
  Future<Map<AssetId, ChangeType>> collectChanges(AssetGraph assetGraph) async {
    final inputSources = await findInputSources();
    final generatedSources = await findCacheDirSources();
    return computeSourceUpdates(inputSources, generatedSources, assetGraph);
  }

  /// Returns the all the sources found in the cache directory.
  Future<Set<AssetId>> findCacheDirSources() =>
      _listGeneratedAssetIds().toSet();

  /// Returns the set of original package inputs on disk.
  Future<Set<AssetId>> findInputSources() {
    final targets = Stream<TargetNode>.fromIterable(
      // TODO: dedup before glob?
      _targetGraphs.expand((t) => t.allModules.values),
    );
    return TimedActivity.read.runAsync(
      () => targets.asyncExpand(_listAssetIds).toSet(),
    );
  }

  /// Finds the asset changes which have happened while unwatched between builds
  /// by taking a difference between the assets in the graph and the assets on
  /// disk.
  Future<Map<AssetId, ChangeType>> computeSourceUpdates(
    Set<AssetId> inputSources,
    Set<AssetId> generatedSources,
    AssetGraph assetGraph,
  ) async {
    final allSources =
        <AssetId>{}
          ..addAll(inputSources)
          ..addAll(generatedSources);
    final updates = <AssetId, ChangeType>{};
    void addUpdates(Iterable<AssetId> assets, ChangeType type) {
      for (final asset in assets) {
        updates[asset] = type;
      }
    }

    final newSources = inputSources.difference(
      assetGraph.allNodes
          .where((node) => node.isTrackedInput)
          .map((node) => node.id)
          .toSet(),
    );
    addUpdates(newSources, ChangeType.ADD);
    final removedAssets = assetGraph.allNodes
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

    final originalGraphSources = assetGraph.sources.toSet();
    final preExistingSources = originalGraphSources.intersection(inputSources);
    for (final id in preExistingSources) {
      final node = assetGraph.get(id)!;
      final originalDigest = node.digest;
      if (originalDigest == null) continue;
      _readerWriter.cache.invalidate([id]);
      final currentDigest = await _readerWriter.digest(id);
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
                  (id) => _targetGraphs.any(
                    (t) => t.isVisibleInBuild(id, targetNode.package),
                  ),
                )
                .where((id) => !targetNode.excludesSource(id)),
          ),
        );
  }

  Stream<AssetId> _listGeneratedAssetIds() {
    final glob = Glob('$generatedOutputDirectory/**');

    return _listIdsSafe(glob)
        .map((id) {
          final packagePath = id.path.substring(
            generatedOutputDirectory.length + 1,
          );
          final firstSlash = packagePath.indexOf('/');
          if (firstSlash == -1) return null;
          final package = packagePath.substring(0, firstSlash);
          final path = packagePath.substring(firstSlash + 1);
          return AssetId(package, path);
        })
        .where((id) => id != null)
        .cast<AssetId>();
  }

  /// Lists asset IDs and swallows file not found errors.
  ///
  /// Ideally we would warn but in practice the default sources list will give
  /// this error a lot and it would be noisy.
  Stream<AssetId> _listIdsSafe(Glob glob, {String? package}) => _readerWriter
      .assetFinder
      .find(glob, package: package)
      .handleError(
        (void _) {},
        test: (e) => e is FileSystemException && e.osError?.errorCode == 2,
      );
}
