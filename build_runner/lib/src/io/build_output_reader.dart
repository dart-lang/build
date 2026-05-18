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
  final AssetGraph? _assetGraph;
  final Set<AssetId>? _processedOutputs;
  final ReaderWriter? _readerWriter;

  late final Set<AssetId> _assetsDeletedByPostProcessBuilders =
      _collectAssetsDeletedByPostProcessBuilders();

  /// For an unexpected failure condition, a fully empty output.
  BuildOutputReader.empty()
    : _assetGraph = null,
      _buildPlan = null,
      _readerWriter = null,
      _processedOutputs = null;

  /// For testing: a build output that does not check build phases to determine
  /// whether outputs were required.
  @visibleForTesting
  BuildOutputReader.graphOnly({
    required ReaderWriter readerWriter,
    required AssetGraph assetGraph,
  }) : _buildPlan = null,
       _assetGraph = assetGraph,
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
    required AssetGraph assetGraph,
    required Set<AssetId> processedOutputs,
  }) : _readerWriter = readerWriter,
       _assetGraph = assetGraph,
       _buildPlan = buildPlan,
       _processedOutputs = processedOutputs;

  Set<AssetId> _collectAssetsDeletedByPostProcessBuilders() {
    final assetGraph = _assetGraph;
    if (assetGraph == null) return const {};
    final result = <AssetId>{};
    for (final packageResults
        in assetGraph.allPostProcessBuildStepResults.values) {
      for (final entry in packageResults.entries) {
        if (entry.value.deletedPrimaryInput) {
          result.add(entry.key.input);
        }
      }
    }
    return result;
  }

  /// Returns a reason why [id] is not readable, or null if it is readable.
  Future<UnreadableReason?> unreadableReason(AssetId id) async {
    if (_assetGraph == null || _readerWriter == null) {
      return UnreadableReason.notFound;
    }
    if (!_assetGraph.contains(id)) {
      return UnreadableReason.notFound;
    }
    if (_assetsDeletedByPostProcessBuilders.contains(id)) {
      return UnreadableReason.deleted;
    }
    if (!_assetGraph.isFile(id)) return UnreadableReason.assetType;

    if (_assetGraph.isPostGenerated(id)) {
      return null;
    }
    if (_assetGraph.isGenerated(id)) {
      if (_processedOutputs?.contains(id) == false) {
        // The generated output was not considered for building because its
        // transitive input(s) did not match build dirs and/or build filters.
        return UnreadableReason.notOutput;
      }
      final config = _assetGraph.generatedNodeConfigurationFor(id)!;
      final stepResult = _assetGraph.buildStepResultFor(config.buildStepId);
      if (stepResult != null && stepResult.result == false) {
        return UnreadableReason.failed;
      }
      if (!_assetGraph.wasOutput(id)) return UnreadableReason.notOutput;

      // No need to explicitly check readability for generated files, their
      // readability is recorded in the node state.
      return null;
    }

    if (_assetGraph.isSource(id) && await _readerWriter.canRead(id)) {
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
    if (_assetGraph == null || _readerWriter == null) return;
    for (final id in _assetGraph.packageFileIds(package, glob: glob)) {
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
    final digest = _assetGraph!.digestFor(id);
    if (digest != null) return digest;
    return _readerWriter!.digest(id).then((digest) {
      _assetGraph.setDigest(id, digest);
      return digest;
    });
  }

  /// A lazily computed view of all the assets available after a build.
  List<AssetId> allAssets({String? rootDir}) {
    if (_assetGraph == null) return [];
    return _assetGraph.allNodeIds
        .where((id) => !_shouldSkipId(id, rootDir))
        .toList();
  }

  bool _shouldSkipId(AssetId id, String? rootDir) {
    if (_buildPlan == null) return false;
    if (!_assetGraph!.isFile(id)) return true;
    if (_assetsDeletedByPostProcessBuilders.contains(id)) return true;

    // Exclude non-lib assets if they're outside of the root directory or not
    // an output package of the build.
    if (!id.path.startsWith('lib/')) {
      if (rootDir != null && !p.isWithin(rootDir, id.path)) return true;
      if (!_buildPlan.buildPackages.outputPackages.contains(id.package)) {
        return true;
      }
    }

    if (_assetGraph.isPostGenerated(id)) {
      return false;
    }
    if (_assetGraph.isGenerated(id)) {
      final config = _assetGraph.generatedNodeConfigurationFor(id)!;
      final stepResult = _assetGraph.buildStepResultFor(config.buildStepId);
      if (!_assetGraph.wasOutput(id) ||
          (stepResult == null || stepResult.result == false)) {
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
