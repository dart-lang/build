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
import '../build/asset_graph/node.dart';
import '../build/build_dirs.dart';
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
  final ReaderWriter? _readerWriter;

  /// Results of checking if an output is required.
  final Map<AssetId, bool> _checkedOutputs = {};

  /// For an unexpected failure condition, a fully empty output.
  BuildOutputReader.empty()
    : _assetGraph = null,
      _buildPlan = null,
      _readerWriter = null;

  /// For testing: a build output that does not check build phases to determine
  /// whether outputs were required.
  @visibleForTesting
  BuildOutputReader.graphOnly({
    required ReaderWriter readerWriter,
    required AssetGraph assetGraph,
  }) : _buildPlan = null,
       _assetGraph = assetGraph,
       _readerWriter = readerWriter;

  BuildOutputReader({
    required BuildPlan buildPlan,
    required ReaderWriter readerWriter,
    required AssetGraph assetGraph,
  }) : _readerWriter = readerWriter,
       _assetGraph = assetGraph,
       _buildPlan = buildPlan;

  /// Returns a reason why [id] is not readable, or null if it is readable.
  Future<UnreadableReason?> unreadableReason(AssetId id) async {
    if (_assetGraph == null || _readerWriter == null) {
      return UnreadableReason.notFound;
    }
    if (!_assetGraph.contains(id)) {
      return UnreadableReason.notFound;
    }
    final node = _assetGraph.get(id)!;
    if (!isRequired(node.id)) {
      return UnreadableReason.notOutput;
    }
    if (node.isDeleted) return UnreadableReason.deleted;
    if (!node.isFile) return UnreadableReason.assetType;

    if (node.type == NodeType.generated) {
      final nodeState = node.generatedNodeState!;
      if (nodeState.result == false) return UnreadableReason.failed;
      if (!node.wasOutput) return UnreadableReason.notOutput;
      // No need to explicitly check readability for generated files, their
      // readability is recorded in the node state.
      return null;
    }

    if (node.isTrackedInput && await _readerWriter.canRead(id)) return null;
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
    final node = _assetGraph!.get(id)!;
    if (node.digest != null) return node.digest!;
    return _readerWriter!.digest(id).then((digest) {
      _assetGraph.updateNode(id, (nodeBuilder) {
        nodeBuilder.digest = digest;
      });
      return digest;
    });
  }

  /// A lazily computed view of all the assets available after a build.
  List<AssetId> allAssets({String? rootDir}) {
    if (_assetGraph == null) return [];
    return _assetGraph.allNodes
        .map((node) {
          if (_shouldSkipNode(node, rootDir)) {
            return null;
          }
          return node.id;
        })
        .whereType<AssetId>()
        .toList();
  }

  bool _shouldSkipNode(AssetNode node, String? rootDir) {
    if (_buildPlan == null) return false;
    if (!node.isFile) return true;
    if (node.isDeleted) return true;

    // Exclude non-lib assets if they're outside of the root directory or not
    // an output package of the build.
    if (!node.id.path.startsWith('lib/')) {
      if (rootDir != null && !p.isWithin(rootDir, node.id.path)) return true;
      if (!_buildPlan.buildPackages.packagesInBuild.contains(node.id.package)) {
        return true;
      }
    }

    if (node.type == NodeType.glob) {
      return true;
    }
    if (node.type == NodeType.generated) {
      if (!node.wasOutput || node.generatedNodeState!.result == false) {
        return true;
      }
      return !isRequired(node.id);
    }
    if (node.id.path == '.packages') return true;
    if (node.id.path == '.dart_tool/package_config.json') return true;
    return false;
  }

  /// Returns whether [output] was required.
  ///
  /// Non-required outputs might be present from a previous build, but they
  /// should not be served or copied to a merged output directory.
  bool isRequired(AssetId output, [Set<AssetId>? currentlyChecking]) {
    if (_buildPlan == null) return true;
    if (_assetGraph == null) return true;

    currentlyChecking ??= <AssetId>{};
    if (currentlyChecking.contains(output)) return false;
    currentlyChecking.add(output);

    final node = _assetGraph.get(output)!;
    if (node.type != NodeType.generated) return true;
    final nodeConfiguration = node.generatedNodeConfiguration!;
    final phase = _buildPlan.buildPhases[nodeConfiguration.phaseNumber];
    if (!phase.isOptional &&
        shouldBuildForDirs(
          output,
          buildDirs: _buildPlan.buildOptions.buildDirs,
          buildFilters: _buildPlan.buildOptions.buildFilters,
          phase: phase,
          buildConfigs: _buildPlan.buildConfigs,
        )) {
      return true;
    }
    return _checkedOutputs.putIfAbsent(
      output,
      () =>
          (_assetGraph.computeOutputs()[node.id] ?? <AssetId>{}).any(
            (o) => isRequired(o, currentlyChecking),
          ) ||
          _assetGraph
              .outputsForPhase(output.package, nodeConfiguration.phaseNumber)
              .where(
                (n) =>
                    n.generatedNodeConfiguration!.primaryInput ==
                    node.generatedNodeConfiguration!.primaryInput,
              )
              .map((n) => n.id)
              .any((o) => isRequired(o, currentlyChecking)),
    );
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
