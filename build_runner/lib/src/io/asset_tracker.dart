// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../build/build_state/build_state.dart';
import '../build/resolver/asset_ids.dart';
import '../build_file.dart';
import '../build_plan/build_configs.dart';
import '../build_plan/build_packages.dart';
import '../build_plan/build_step_plan.dart';
import '../build_plan/build_target.dart';
import '../constants.dart';
import '../logging/timed_activities.dart';
import 'filesystem.dart';
import 'reader_writer.dart';

/// Finds build assets and computes changes to build assets.
class AssetTracker {
  final ReaderWriter _readerWriter;
  final BuildPackages _buildPackages;
  final BuildConfigs _buildConfigs;

  AssetTracker(this._readerWriter, this._buildPackages, this._buildConfigs);

  /// Checks for and returns any file system changes compared to the current
  /// build step plan and build state.
  Future<Map<AssetFile, ChangeType>> collectChanges({
    required BuildStepPlan buildStepPlan,
    required BuildState buildState,
  }) async {
    final inputSources = await findInputSources();
    final generatedSources = await findCacheDirSources();
    final declaredAndActualOutputs = [
      ...buildStepPlan.declaredOutputs,
      ...buildState.actualPostOutputs,
    ];
    return computeSourceUpdates(
      inputSources,
      generatedSources,
      buildState,
      declaredAndActualOutputs,
      buildStepPlan: buildStepPlan,
    );
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
  /// by taking a difference between the assets in the build state and the
  /// assets on disk.
  Future<Map<AssetFile, ChangeType>> computeSourceUpdates(
    Set<AssetId> inputSources,
    Set<AssetId> generatedSources,
    BuildState buildState,
    Iterable<AssetId> declaredAndActualOutputs, {
    required BuildStepPlan buildStepPlan,
  }) async {
    final updates = <AssetFile, ChangeType>{};

    final newSources = inputSources.difference(buildState.sources.toSet());
    for (final id in newSources) {
      updates[AssetFile.source(id)] = ChangeType.ADD;
    }
    for (final id in buildState.sources) {
      if (!inputSources.contains(id)) {
        updates[AssetFile.source(id)] = ChangeType.REMOVE;
      }
    }
    for (final id in declaredAndActualOutputs) {
      final isHidden = id.isHidden(
        buildStepPlan: buildStepPlan,
        buildState: buildState,
      );
      final exists = isHidden
          ? generatedSources.contains(id)
          : inputSources.contains(id);
      if (!exists) {
        updates[AssetFile(id, hidden: isHidden)] = ChangeType.REMOVE;
      }
    }

    final originalGraphSources = buildState.sources.toSet();
    final preExistingSources = originalGraphSources.intersection(inputSources);
    for (final id in preExistingSources) {
      final originalDigest = buildState.contentOfSource(id);
      if (originalDigest == null) continue;

      final currentDigest = await _readerWriter.digest(id);
      if (currentDigest != originalDigest.digest) {
        updates[AssetFile.source(id)] = ChangeType.MODIFY;
      }
    }

    final preExistingOutputs = declaredAndActualOutputs.toSet().where((id) {
      final isHidden = id.isHidden(
        buildStepPlan: buildStepPlan,
        buildState: buildState,
      );
      return isHidden
          ? generatedSources.contains(id)
          : inputSources.contains(id);
    });
    for (final id in preExistingOutputs) {
      final hidden = id.isHidden(
        buildStepPlan: buildStepPlan,
        buildState: buildState,
      );
      final file = AssetFile(id, hidden: hidden);
      final originalContent = buildState.contentAt(
        file,
        buildStepPlan: buildStepPlan,
      );
      if (originalContent == null) continue;

      final currentDigest = await _readerWriter.digest(id, hidden: hidden);
      if (currentDigest != originalContent.digest) {
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

  Stream<AssetId> _listGeneratedAssetIds() {
    final fs = _readerWriter.filesystem;
    if (fs is InMemoryFilesystem) {
      return Stream.fromIterable(
        fs.filePaths
            .where((path) => path.contains('$generatedOutputDirectory/'))
            .map((path) {
              final prefix = '$generatedOutputDirectory/';
              final idx = path.indexOf(prefix);
              final sub = path.substring(idx + prefix.length);
              final firstSlash = sub.indexOf('/');
              if (firstSlash == -1) return null;
              final package = sub.substring(0, firstSlash);
              final relPath = sub.substring(firstSlash + 1);
              return AssetId(package, relPath);
            })
            .whereType<AssetId>(),
      );
    }
    final generatedDirPath = p.join(
      _buildPackages.packages[_buildPackages.outputRoot]!.path,
      generatedOutputDirectory,
    );
    final generatedDir = Directory(generatedDirPath);
    if (!generatedDir.existsSync()) return const Stream.empty();
    return Glob('**')
        .list(followLinks: true, root: generatedDirPath)
        .where((e) => e is File && !p.basename(e.path).startsWith('._'))
        .cast<File>()
        .map((file) {
          final filePath = p.normalize(file.absolute.path);
          final relativePath = p.relative(filePath, from: generatedDirPath);
          final firstSlash = relativePath.indexOf(p.separator);
          if (firstSlash == -1) return null;
          final package = relativePath.substring(0, firstSlash);
          final subPath = relativePath.substring(firstSlash + 1);
          final normalizedSubPath = p.posix.normalize(
            subPath.replaceAll(r'\', '/'),
          );
          return AssetId(package, normalizedSubPath);
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
