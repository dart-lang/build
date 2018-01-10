// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';

typedef Future RunPhaseForInput(int phaseNumber, AssetId primaryInput);

/// A [RunnerAssetReader] must implement [MultiPackageAssetReader].
abstract class RunnerAssetReader implements MultiPackageAssetReader {}

/// An [AssetReader] with a lifetime equivalent to that of a single step in a
/// build.
///
/// A step is a single Builder and primary input (or package for package
/// builders) combination.
///
/// Limits reads to the assets which are sources or were generated by previous
/// phases.
///
/// Tracks the assets and globs read during this step for input dependency
/// tracking.
class SingleStepReader implements AssetReader {
  final AssetGraph _assetGraph;
  final _assetsRead = new Set<AssetId>();
  final AssetReader _delegate;
  final _globsRan = new Set<Glob>();
  final int _phaseNumber;
  final String _primaryPackage;
  final RunPhaseForInput _runPhaseForInput;

  SingleStepReader(this._delegate, this._assetGraph, this._phaseNumber,
      this._primaryPackage, this._runPhaseForInput);

  Set<AssetId> get assetsRead => _assetsRead;

  /// The [Glob]s which have been searched with [findAssets].
  ///
  /// A change in the set of assets matching a searched glob indicates that the
  /// builder may behave differently on the next build.
  Iterable<Glob> get globsRan => _globsRan;

  bool _isReadable(AssetId id) {
    _assetsRead.add(id);
    var node = _assetGraph.get(id);
    if (node == null) {
      _assetGraph.add(new SyntheticSourceAssetNode(id));
      return false;
    }
    if (node.isGenerated) {
      return (node as GeneratedAssetNode).phaseNumber < _phaseNumber;
    }
    return node.isReadable;
  }

  @override
  Future<bool> canRead(AssetId id) async {
    if (!_isReadable(id)) return new Future.value(false);
    await _ensureAssetIsBuilt(id);
    var node = _assetGraph.get(id);
    bool result;
    if (node is GeneratedAssetNode) {
      // Short circut, we know this file exists because its readable and it was
      // output.
      result = node.wasOutput;
    } else {
      result = await _delegate.canRead(id);
    }
    if (result) await _ensureDigest(id);
    return result;
  }

  @override
  Future<Digest> digest(AssetId id) async {
    if (!_isReadable(id)) throw new AssetNotFoundException(id);
    await _ensureAssetIsBuilt(id);
    return _ensureDigest(id);
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    if (!_isReadable(id)) throw new AssetNotFoundException(id);
    await _ensureAssetIsBuilt(id);
    await _ensureDigest(id);
    return _delegate.readAsBytes(id);
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) async {
    if (!_isReadable(id)) throw new AssetNotFoundException(id);
    await _ensureAssetIsBuilt(id);
    await _ensureDigest(id);
    return _delegate.readAsString(id, encoding: encoding);
  }

  @override
  Stream<AssetId> findAssets(Glob glob) async* {
    _globsRan.add(glob);
    var potentialMatches = _assetGraph
        .packageNodes(_primaryPackage)
        .where((n) => glob.matches(n.id.path));
    for (var node in potentialMatches) {
      if (node is GeneratedAssetNode) {
        if (node.phaseNumber >= _phaseNumber) continue;
        await _ensureAssetIsBuilt(node.id);
        if (node.wasOutput) yield node.id;
      } else {
        yield node.id;
      }
    }
  }

  Future<Null> _ensureAssetIsBuilt(AssetId id) async {
    if (_runPhaseForInput == null) return null;
    var node = _assetGraph.get(id);
    if (node is GeneratedAssetNode && node.needsUpdate) {
      await _runPhaseForInput(node.phaseNumber, node.primaryInput);
    }
  }

  Future<Digest> _ensureDigest(AssetId id) async {
    var node = _assetGraph.get(id);
    return node.lastKnownDigest ??= await _delegate.digest(id);
  }
}
