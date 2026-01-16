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
import '../build_plan/build_configs.dart';
import '../build_plan/build_packages.dart';
import '../build_plan/build_target.dart';
import '../constants.dart';
import '../logging/timed_activities.dart';
import 'reader_writer.dart';

/// Finds build assets and computes changes to build assets.
class AssetTracker {
  final ReaderWriter _readerWriter;
  final BuildPackages _buildPackages;
  final BuildConfigs _buildConfigs;

  AssetTracker(this._readerWriter, this._buildPackages, this._buildConfigs);

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
    final targets = Stream<BuildTarget>.fromIterable(
      _buildConfigs.buildTargets.values,
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

  Stream<AssetId> _listAssetIds(BuildTarget buildTarget) {
    return buildTarget.sourceIncludes.isEmpty
        ? const Stream<AssetId>.empty()
        : StreamGroup.merge(
          buildTarget.sourceIncludes.map(
            (glob) => _listIdsSafe(glob, package: buildTarget.package)
                .where(
                  (id) => _buildConfigs.isVisibleInBuild(
                    id,
                    _buildPackages.allPackages[buildTarget.package]!,
                  ),
                )
                .where((id) => !buildTarget.excludesSource(id)),
          ),
        );
  }

  Stream<AssetId> _listGeneratedAssetIds() {
    final glob = Glob('$generatedOutputDirectory/**');

    return _listIdsSafe(glob, package: _buildPackages.outputRoot.name)
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
  Stream<AssetId> _listIdsSafe(Glob glob, {required String package}) =>
      _readerWriter.assetFinder
          .find(glob, package: package)
          .handleError(
            (void _) {},
            test: (e) => e is FileSystemException && e.osError?.errorCode == 2,
          );
}
