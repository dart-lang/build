// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../build/asset_graph/graph.dart';
import '../build_plan/build_plan.dart';
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
  final BuildState? _buildState;
  final Set<AssetId>? _processedOutputs;
  final ReaderWriter? _readerWriter;

  late final Set<AssetId> _assetsDeletedByPostProcessBuilders =
      _collectAssetsDeletedByPostProcessBuilders();

  /// For an unexpected failure condition, a fully empty output.
  BuildOutputReader.empty()
    : _buildState = null,
      _buildPlan = null,
      _readerWriter = null,
      _processedOutputs = null;

  /// For testing: a build output that does not check build phases to determine
  /// whether outputs were required.
  @visibleForTesting
  BuildOutputReader.graphOnly({
    required ReaderWriter readerWriter,
    required BuildState buildState,
  }) : _buildPlan = null,
       _buildState = buildState,
       _readerWriter = readerWriter,
       _processedOutputs = null;

  /// Creates from build results.
  ///
  /// [processedOutputs] is the set of generated outputs in the build that were
  /// considered for building. This excludes generated outputs that were skipped
  /// due to not matching build dirs or not matching build filters.
  BuildOutputReader({
    required BuildPlan buildPlan,
    required ReaderWriter readerWriter,
    required BuildState buildState,
    required Set<AssetId> processedOutputs,
  }) : _readerWriter = readerWriter,
       _buildState = buildState,
       _buildPlan = buildPlan,
       _processedOutputs = processedOutputs;

  Set<AssetId> _collectAssetsDeletedByPostProcessBuilders() {
    final buildState = _buildState;
    if (buildState == null) return const {};
    final result = <AssetId>{};
    for (final entry in buildState.postProcessBuildStepResults) {
      if (entry.value.deletedPrimaryInput) {
        result.add(entry.key.input);
      }
    }
    return result;
  }

  /// Returns a reason why [id] is not readable, or null if it is readable.
  Future<UnreadableReason?> unreadableReason(AssetId id) async {
    if (_buildState == null || _readerWriter == null) {
      return UnreadableReason.notFound;
    }
    if (!_buildState.isFile(id)) {
      return UnreadableReason.notFound;
    }
    if (_assetsDeletedByPostProcessBuilders.contains(id)) {
      return UnreadableReason.deleted;
    }
    if (!_buildState.isFile(id)) return UnreadableReason.assetType;

    if (_buildState.isActualPostOutput(id)) {
      return null;
    }
    if (_buildState.isDeclaredOutput(id)) {
      final step = _buildState.stepForDeclaredOutput(id);
      if (_processedOutputs?.contains(id) == false) {
        // The generated output was not considered for building because its
        // transitive input(s) did not match build dirs and/or build filters.
        return UnreadableReason.notOutput;
      }
      final stepResult = _buildState.stepResult(step);
      if (stepResult.failed) {
        return UnreadableReason.failed;
      }
      if (!_buildState.isActualOutput(id)) return UnreadableReason.notOutput;

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
    for (final id in _buildState.findFiles(package: package, glob: glob)) {
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
    final digest = _buildState!.digestOf(id);
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
    for (final id in buildState.declaredOutputs) {
      if (!_shouldSkipId(buildState, id, rootDir)) {
        result.add(id);
      }
    }
    result.addAll(buildState.actualPostOutputs);
    return result;
  }

  bool _shouldSkipId(BuildState buildState, AssetId id, String? rootDir) {
    if (_buildPlan == null) return false;
    if (!buildState.isFile(id)) return true;
    if (_assetsDeletedByPostProcessBuilders.contains(id)) return true;

    // Exclude non-lib assets if they're outside of the root directory or not
    // an output package of the build.
    if (!id.path.startsWith('lib/')) {
      if (rootDir != null && !p.isWithin(rootDir, id.path)) return true;
      if (!_buildPlan.buildPackages.outputPackages.contains(id.package)) {
        return true;
      }
    }

    if (buildState.isActualPostOutput(id)) {
      return false;
    }
    if (buildState.isDeclaredOutput(id)) {
      final step = buildState.stepForDeclaredOutput(id);
      final stepResult = buildState.stepResult(step);
      if (!buildState.isActualOutput(id) || (stepResult.failed)) {
        return true;
      }
      return !_processedOutputs!.contains(id);
    }
    if (id.path == '.packages') return true;
    if (id.path == '.dart_tool/package_config.json') return true;
    return false;
  }
}

enum UnreadableReason {
  notFound,
  notOutput,
  assetType,
  deleted,
  failed,
  unknown,
}
