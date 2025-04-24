// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';

import '../../build_runner_core.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../asset_graph/optional_output_tracker.dart';
import '../generate/build_phases.dart';
import '../package_graph/target_graph.dart';

/// A view of the build output.
///
/// If [canRead] returns false, [unreadableReason] explains why the file is
/// missing; for example, it might say that generation failed.
class FinalizedReader {
  late final AssetFinder assetFinder = FunctionAssetFinder(_findAssets);

  final AssetReader _delegate;
  final AssetGraph _assetGraph;
  final TargetGraph _targetGraph;
  OptionalOutputTracker? _optionalOutputTracker;
  final String _rootPackage;
  final BuildPhases _buildPhases;

  void reset(Set<String> buildDirs, Set<BuildFilter> buildFilters) {
    _optionalOutputTracker = OptionalOutputTracker(
      _assetGraph,
      _targetGraph,
      buildDirs,
      buildFilters,
      _buildPhases,
    );
  }

  FinalizedReader(
    this._delegate,
    this._assetGraph,
    this._targetGraph,
    this._buildPhases,
    this._rootPackage,
  );

  /// Returns a reason why [id] is not readable, or null if it is readable.
  Future<UnreadableReason?> unreadableReason(AssetId id) async {
    if (!_assetGraph.contains(id)) return UnreadableReason.notFound;
    var node = _assetGraph.get(id)!;
    if (_optionalOutputTracker != null &&
        !_optionalOutputTracker!.isRequired(node.id)) {
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

    if (node.isTrackedInput && await _delegate.canRead(id)) return null;
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

  Future<List<int>> readAsBytes(AssetId id) => _delegate.readAsBytes(id);

  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async {
    if (_assetGraph.get(id)?.isDeleted ?? true) {
      throw AssetNotFoundException(id);
    }
    return _delegate.readAsString(id, encoding: encoding);
  }

  Stream<AssetId> _findAssets(Glob glob, String? _) async* {
    var potentialNodes =
        _assetGraph
            .packageNodes(_rootPackage)
            .where((n) => glob.matches(n.id.path))
            .toList();
    var potentialIds = potentialNodes.map((n) => n.id).toList();

    for (var id in potentialIds) {
      if (await _delegate.canRead(id)) {
        yield id;
      }
    }
  }

  /// Returns the `lastKnownDigest` of [id], computing and caching it if
  /// necessary.
  ///
  /// Note that [id] must exist in the asset graph.
  FutureOr<Digest> _ensureDigest(AssetId id) {
    var node = _assetGraph.get(id)!;
    if (node.digest != null) return node.digest!;
    return _delegate.digest(id).then((digest) {
      _assetGraph.updateNode(id, (nodeBuilder) {
        nodeBuilder.digest = digest;
      });
      return digest;
    });
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
