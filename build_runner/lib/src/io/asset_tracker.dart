// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:watcher/watcher.dart';

import '../build_plan/asset_file.dart';
import '../build_plan/build_configs.dart';
import '../build_plan/build_packages.dart';
import '../build_plan/build_target.dart';
import '../build_plan/previous_build.dart';
import '../constants.dart';
import '../logging/timed_activities.dart';
import 'reader_writer.dart';

/// Finds build assets and computes changes to build assets.
class AssetTracker {
  final ReaderWriter _readerWriter;
  final BuildPackages _buildPackages;
  final BuildConfigs _buildConfigs;

  AssetTracker(this._readerWriter, this._buildPackages, this._buildConfigs);

  /// Checks for and returns any file system changes compared to the previous
  /// build.
  Future<Map<AssetFile, ChangeType>> collectChanges({
    required PreviousBuild previousBuild,
  }) async {
    final diskFiles = await findFiles();
    final actualOutputs = [
      ...previousBuild.actualOutputs,
      ...previousBuild.actualPostOutputs,
    ];
    return computeSourceUpdates(diskFiles, previousBuild, actualOutputs);
  }

  /// Returns all assets found on disk: both package path files and artifact
  /// tree files.
  Future<Set<AssetFile>> findFiles() async {
    final inputSources = await findInputSources();
    final artifactTreeFiles = await findArtifactTreeFiles();
    return {
      ...inputSources.map(AssetFile.atPackagePath),
      ...artifactTreeFiles.map(AssetFile.inArtifactTree),
    };
  }

  /// Returns all the assets found in the artifact tree.
  Future<Set<AssetId>> findArtifactTreeFiles() =>
      _listArtifactTreeAssetIds().toSet();

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
  /// by taking a difference between the assets in the previous build and the
  /// assets on disk.
  Future<Map<AssetFile, ChangeType>> computeSourceUpdates(
    Set<AssetFile> diskFiles,
    PreviousBuild previousBuild,
    Iterable<AssetId> actualOutputs,
  ) async {
    final previousFiles = <AssetFile>{
      ...previousBuild.sources.map(AssetFile.atPackagePath),
      ...actualOutputs.map(
        (id) =>
            AssetFile(id, inArtifactTree: previousBuild.isInArtifactTree(id)),
      ),
    };

    final updates = <AssetFile, ChangeType>{};

    for (final file in diskFiles.difference(previousFiles)) {
      updates[file] = ChangeType.ADD;
    }

    for (final file in previousFiles.difference(diskFiles)) {
      updates[file] = ChangeType.REMOVE;
    }

    for (final file in previousFiles.intersection(diskFiles)) {
      final originalDigest = previousBuild.digestOf(file.id);
      if (originalDigest == null) continue;

      final currentDigest = await _readerWriter.digest(
        file.id,
        inArtifactTree: file.inArtifactTree,
      );
      if (currentDigest != originalDigest) {
        updates[file] = ChangeType.MODIFY;
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
                      _buildPackages[buildTarget.package]!,
                    ),
                  )
                  .where((id) => !buildTarget.excludesSource(id)),
            ),
          );
  }

  Stream<AssetId> _listArtifactTreeAssetIds() {
    final glob = Glob('$artifactTreePath/**');

    return _listIdsSafe(glob, package: _buildPackages.outputRoot)
        .map((id) {
          final packagePath = id.path.substring(artifactTreePath.length + 1);
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
