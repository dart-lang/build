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

  /// Returns a reason why [id] is not readable, or null if it is readable.
  Future<UnreadableReason?> unreadableReason(AssetId id) async {
    if (_assetGraph == null || _readerWriter == null) {
      return UnreadableReason.notFound;
    }
    if (!_assetGraph.contains(id)) {
      return UnreadableReason.notFound;
    }
    final node = _assetGraph.get(id)!;
    if (node.isDeleted) return UnreadableReason.deleted;
    if (!node.isFile) return UnreadableReason.assetType;

    if (node.type == NodeType.generated) {
      if (_processedOutputs?.contains(node.id) == false) {
        // The generated output was not considered for building because its
        // transitive input(s) did not match build dirs and/or build filters.
        return UnreadableReason.notOutput;
      }
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
      if (!_buildPlan.buildPackages.outputPackages.contains(node.id.package)) {
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
      return !_processedOutputs!.contains(node.id);
    }
    if (node.id.path == '.packages') return true;
    if (node.id.path == '.dart_tool/package_config.json') return true;
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
