// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../build/build_state/build_state.dart';
import '../build_plan/build_plan.dart';
import '../build_plan/build_step_plan.dart';
import 'reader_writer.dart';

/// A view of the build output.
///
/// If [canRead] returns false, [unreadableReason] explains why the file is
/// missing; for example, it might say that generation failed.
///
/// Files are only visible if they were a required part of the build, even if
/// they exist on disk from a previous build.
class BuildOutputReader {
  final BuildPlan? _buildPlan;
  final BuildStepPlan? _buildStepPlan;
  final BuildState? _buildState;
  final ReaderWriter? _readerWriter;

  late final Set<AssetId> _assetsDeletedByPostProcessBuilders =
      _collectAssetsDeletedByPostProcessBuilders();

  /// For an unexpected failure condition, a fully empty output.
  BuildOutputReader.empty()
    : _buildState = null,
      _buildPlan = null,
      _buildStepPlan = null,
      _readerWriter = null;

  /// For testing: a build output that does not check build phases to determine
  /// whether outputs were required.
  @visibleForTesting
  BuildOutputReader.buildStateOnly({
    required ReaderWriter readerWriter,
    required BuildState buildState,
    BuildStepPlan? buildStepPlan,
  }) : _buildPlan = null,
       _buildStepPlan = buildStepPlan,
       _buildState = buildState,
       _readerWriter = readerWriter;

  /// Creates from build results.
  BuildOutputReader({
    required BuildPlan buildPlan,
    required BuildState buildState,
  }) : _readerWriter = buildPlan.readerWriter,
       _buildState = buildState,
       _buildPlan = buildPlan,
       _buildStepPlan = buildPlan.buildStepPlan;

  Set<AssetId> _collectAssetsDeletedByPostProcessBuilders() =>
      _buildState?.assetsDeletedByPostProcess ?? const {};

  /// Returns a reason why [id] is not readable, or null if it is readable.
  Future<UnreadableReason?> unreadableReason(AssetId id) async {
    if (_buildState == null || _readerWriter == null) {
      return UnreadableReason.notFound;
    }
    if (!_isFile(id)) {
      return UnreadableReason.notFound;
    }
    if (_assetsDeletedByPostProcessBuilders.contains(id)) {
      return UnreadableReason.deleted;
    }
    if (!_isFile(id)) return UnreadableReason.assetType;

    if (_buildState.isActualPostOutput(id)) {
      return null;
    }
    final step = _buildStepPlan?.stepForDeclaredOutputOrNull(id);
    if (step != null) {
      if (!_buildState.isProcessedOutput(
        buildStepPlan: _buildStepPlan,
        id: id,
      )) {
        // The generated output was not considered for building because its
        // transitive input(s) did not match build dirs and/or build filters.
        return UnreadableReason.notOutput;
      }
      final stepResult = _buildState.stepResult(step);
      if (stepResult.failed) {
        return UnreadableReason.failed;
      }
      if (!_buildState.isActualOutput(buildStepPlan: _buildStepPlan!, id: id)) {
        return UnreadableReason.notOutput;
      }

      // No need to explicitly check readability for generated files, their
      // readability is recorded in the build state.
      return null;
    }

    if (_buildState.isSource(id) && await _readerWriter.canRead(id)) {
      return null;
    }
    return UnreadableReason.unknown;
  }

  Future<bool> canRead(AssetId id) async =>
      (await unreadableReason(id)) == null;

  Future<Digest> digest(AssetId id) async {
    final unreadableReason = await this.unreadableReason(id);
    // Do provide digests for generated files that are known but not output
    // or known to be deleted. `build serve` uses these digests, which
    // reflect that the file is missing.
    if (unreadableReason != null &&
        unreadableReason != UnreadableReason.notOutput &&
        unreadableReason != UnreadableReason.deleted) {
      throw AssetNotFoundException(id);
    }
    return _ensureDigest(id);
  }

  Future<List<int>> readAsBytes(AssetId id) => _readerWriter!.readAsBytes(id);

  Stream<AssetId> findAssets(Glob glob, {required String package}) async* {
    if (_buildState == null || _readerWriter == null) return;
    for (final id in _buildState.findFiles(
      package: package,
      buildStepPlan: _buildStepPlan,
      glob: glob,
    )) {
      if (await _readerWriter.canRead(id)) {
        yield id;
      }
    }
  }

  /// Returns the `lastKnownDigest` of [id], computing and caching it if
  /// necessary.
  ///
  /// Note that [id] must exist in the asset graph.
  FutureOr<Digest> _ensureDigest(AssetId id) {
    final digest = _buildState!.digestOf(buildStepPlan: _buildStepPlan, id: id);
    if (digest != null) return digest;
    return _readerWriter!.digest(id).then((digest) {
      _buildState.updateSourceDigest(id, digest);
      return digest;
    });
  }

  /// A lazily computed view of all the assets available after a build.
  List<AssetId> allAssets({String? rootDir}) {
    final buildState = _buildState;
    if (buildState == null) return [];
    final result = <AssetId>[];
    for (final id in buildState.sources) {
      if (!_shouldSkipId(buildState, id, rootDir)) {
        result.add(id);
      }
    }
    final buildStepPlan = _buildStepPlan;
    if (buildStepPlan != null) {
      for (final id in buildStepPlan.declaredOutputs) {
        if (!_shouldSkipId(buildState, id, rootDir)) {
          result.add(id);
        }
      }
    }
    result.addAll(buildState.actualPostOutputs);
    return result;
  }

  bool _shouldSkipId(BuildState buildState, AssetId id, String? rootDir) {
    if (_buildPlan == null) return false;
    if (!_isFile(id)) return true;
    if (_assetsDeletedByPostProcessBuilders.contains(id)) return true;

    // Exclude non-lib assets if they're outside of the root directory or not
    // an output package of the build.
    if (!id.path.startsWith('lib/')) {
      if (rootDir != null && !p.isWithin(rootDir, id.path)) return true;
      if (!_buildPlan.buildSpec.buildPackages.outputPackages.contains(
        id.package,
      )) {
        return true;
      }
    }

    if (buildState.isActualPostOutput(id)) {
      return false;
    }
    final step = _buildStepPlan?.stepForDeclaredOutputOrNull(id);
    if (step != null) {
      final stepResult = buildState.stepResultOrNull(step);
      if (stepResult == null ||
          stepResult.failed ||
          !stepResult.outputs.containsKey(id)) {
        return true;
      }
      return !buildState.isProcessedOutput(
        buildStepPlan: _buildStepPlan,
        id: id,
      );
    }
    if (id.path == '.packages') return true;
    if (id.path == '.dart_tool/package_config.json') return true;
    return false;
  }

  bool _isFile(AssetId id) =>
      _buildState!.isFile(buildStepPlan: _buildStepPlan, id: id);
}

enum UnreadableReason {
  notFound,
  notOutput,
  assetType,
  deleted,
  failed,
  unknown,
}
