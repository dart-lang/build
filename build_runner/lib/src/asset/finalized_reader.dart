// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';

import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../asset_graph/optional_output_tracker.dart';

/// An [AssetReader] which ignores deleted files.
class FinalizedReader implements AssetReader {
  final AssetReader _delegate;
  final AssetGraph _assetGraph;
  final OptionalOutputTracker _optionalOutputTracker;

  /// Clears the cache of which assets were required.
  void reset() {
    _optionalOutputTracker.reset();
  }

  FinalizedReader(
      this._delegate, this._assetGraph, this._optionalOutputTracker);

  /// Returns a reason why [id] is not readable, or null if it is readable.
  Future<UnreadableReason> unreadableReason(AssetId id) async {
    if (!_assetGraph.contains(id)) return UnreadableReason.notFound;
    var node = _assetGraph.get(id);
    if (node.isDeleted) return UnreadableReason.deleted;
    if (!node.isReadable) return UnreadableReason.assetType;
    if (node is GeneratedAssetNode) {
      if (node.isFailure) return UnreadableReason.failed;
      if (!(node.wasOutput && _optionalOutputTracker.isRequired(node.id))) {
        return UnreadableReason.notOutput;
      }
    }
    if (await _delegate.canRead(id)) return null;
    return UnreadableReason.unknown;
  }

  @override
  Future<bool> canRead(AssetId id) async =>
      (await unreadableReason(id)) == null;

  @override
  Future<Digest> digest(AssetId id) => _delegate.digest(id);

  @override
  Future<List<int>> readAsBytes(AssetId id) => _delegate.readAsBytes(id);

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: utf8}) async {
    if (_assetGraph.get(id)?.isDeleted ?? true) {
      throw new AssetNotFoundException(id);
    }
    return _delegate.readAsString(id, encoding: encoding);
  }

  @override
  Stream<AssetId> findAssets(Glob glob) => _delegate.findAssets(glob);
}

enum UnreadableReason {
  notFound,
  notOutput,
  assetType,
  deleted,
  failed,
  unknown,
}
