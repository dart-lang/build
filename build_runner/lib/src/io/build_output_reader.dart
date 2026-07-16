// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import '../build/asset_content.dart';
import '../build/br_outputs.dart';
import '../build/build_state/build_state.dart';
import '../build/builder_filesystem.dart';
import '../build/resolver/asset_ids.dart';
import '../build_plan/build_step_plan.dart';

/// A view of the build output.
///
/// If [canRead] returns false, [unreadableReason] explains why the file is
/// missing; for example, it might say that generation failed.
///
/// Files are only visible if they were a required part of the build, even if
/// they exist on disk from a previous build.
class BuildOutputReader {
  final BuilderFilesystem _builderFilesystem;

  BuildState get _buildState => _builderFilesystem.buildState;
  BuildStepPlan get _buildStepPlan => _builderFilesystem.buildStepPlan;

  late final Set<AssetId> _assetsDeletedByPostProcessBuilders =
      _collectAssetsDeletedByPostProcessBuilders();

  /// Creates from build results.
  BuildOutputReader({required BuilderFilesystem builderFilesystem})
    : _builderFilesystem = builderFilesystem;

  Set<AssetId> _collectAssetsDeletedByPostProcessBuilders() =>
      _buildState.assetsDeletedByPostProcess;

  String pathFor(AssetId id) {
    return _builderFilesystem.readerWriter.assetPathProvider.pathFor(
      id,
      hide: id.isHidden(buildStepPlan: _buildStepPlan, buildState: _buildState),
    );
  }

  /// Returns a reason why [id] is not readable, or null if it is readable.
  Future<UnreadableReason?> unreadableReason(AssetId id) async {
    final buildState = _buildState;
    final builderFilesystem = _builderFilesystem;

    if (id.isBrOutput) {
      final primaryInputId = id.primaryInputForBrOutputId;
      if (primaryInputId != null) {
        final parts = buildState.partContributionsFor(primaryInputId);
        if (parts.isNotEmpty) return null;
      }
      return UnreadableReason.notFound;
    }

    if (!_isFile(id)) {
      return UnreadableReason.notFound;
    }
    if (_assetsDeletedByPostProcessBuilders.contains(id)) {
      return UnreadableReason.deleted;
    }

    if (buildState.isActualPostOutput(id)) {
      return null;
    }
    final step = _buildStepPlan.stepForDeclaredOutputOrNull(id);
    if (step != null) {
      if (!buildState.isProcessedOutput(
        buildStepPlan: _buildStepPlan,
        id: id,
      )) {
        // The generated output was not considered for building because its
        // transitive input(s) did not match build dirs and/or build filters.
        return UnreadableReason.notOutput;
      }
      final stepResult = buildState.stepResult(step);
      if (stepResult.failed) {
        return UnreadableReason.failed;
      }
      if (!buildState.isActualOutput(buildStepPlan: _buildStepPlan, id: id)) {
        return UnreadableReason.notOutput;
      }

      // No need to explicitly check readability for generated files, their
      // readability is recorded in the build state.
      return null;
    }

    if (buildState.isSource(id) &&
        await builderFilesystem.readerWriter.canRead(
          id,
          hidden: id.isHidden(
            buildStepPlan: _buildStepPlan,
            buildState: buildState,
          ),
        )) {
      return null;
    }
    return UnreadableReason.notFound;
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

  Future<List<int>> readAsBytes(AssetId id) async {
    try {
      final content = await _builderFilesystem.contentOf(id);
      return content.bytes;
      // ignore: avoid_catching_errors
    } on StateError {
      // BuilderFilesystem throws StateError if !isFile(id) or missing.
      throw AssetNotFoundException(id);
    }
  }


  Future<String> readAsString(AssetId id) async {
    try {
      final content = await _builderFilesystem.contentOf(id);
      return content.stringValue();
      // ignore: avoid_catching_errors
    } on StateError {
      // BuilderFilesystem throws StateError if !isFile(id).
      throw AssetNotFoundException(id);
    }
  }

  Stream<AssetId> findAssets(Glob glob, {required String package}) async* {
    for (final id in _buildState.findFiles(
      package: package,
      buildStepPlan: _buildStepPlan,
      glob: glob,
    )) {
      if (await canRead(id)) {
        yield id;
      }
    }
  }

  /// Returns the `lastKnownDigest` of [id], computing and caching it if
  /// necessary.
  ///
  /// Note that [id] must exist in the asset graph.
  FutureOr<Digest> _ensureDigest(AssetId id) async {
    final content = _buildState.contentOf(
      buildStepPlan: _buildStepPlan,
      id: id,
    );
    if (content != null) return content.digest;
    final bytes = await readAsBytes(id);
    return AssetContent.bytes(bytes).digest;
  }

  /// A lazily computed view of all the assets available after a build.
  List<AssetId> allAssets({String? rootDir}) {
    final result = <AssetId>[];
    for (final id in _buildState.sources) {
      if (!_shouldSkipId(id, rootDir)) {
        result.add(id);
      }
    }
    for (final id in _buildStepPlan.declaredOutputs) {
      if (!_shouldSkipId(id, rootDir)) {
        result.add(id);
      }
    }
    result.addAll(_buildState.actualPostOutputs);
    for (final primaryInput in _buildState.primaryInputsWithParts) {
      final partId = primaryInput.brOutputIdForPrimaryInput;
      if (!_shouldSkipId(partId, rootDir)) {
        result.add(partId);
      }
    }
    return result;
  }

  bool _shouldSkipId(AssetId id, String? rootDir) {
    if (id.isBrOutput) {
      final primaryInputId = id.primaryInputForBrOutputId;
      if (primaryInputId == null) return true;
      final parts = _buildState.partContributionsFor(primaryInputId);
      if (parts.isEmpty) return true;
    } else {
      if (!_isFile(id)) return true;
      if (_assetsDeletedByPostProcessBuilders.contains(id)) return true;
    }

    // Exclude non-lib assets if they're outside of the root directory or not
    // an output package of the build.
    if (!id.path.startsWith('lib/')) {
      if (rootDir != null && !p.isWithin(rootDir, id.path)) return true;
      if (!_builderFilesystem.buildPackages.outputPackages.contains(
        id.package,
      )) {
        return true;
      }
    }

    if (_buildState.isActualPostOutput(id)) {
      return false;
    }
    final step = _buildStepPlan.stepForDeclaredOutputOrNull(id);
    if (step != null) {
      final stepResult = _buildState.stepResultOrNull(step);
      if (stepResult == null ||
          stepResult.failed ||
          !stepResult.outputs.containsKey(id)) {
        return true;
      }
      return !_buildState.isProcessedOutput(
        buildStepPlan: _buildStepPlan,
        id: id,
      );
    }
    if (id.path == '.packages') return true;
    if (id.path == '.dart_tool/package_config.json') return true;
    return false;
  }

  bool _isFile(AssetId id) =>
      _buildState.isFile(buildStepPlan: _buildStepPlan, id: id);
}

enum UnreadableReason { notFound, notOutput, deleted, failed }
