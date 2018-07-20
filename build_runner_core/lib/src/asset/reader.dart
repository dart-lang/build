// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';

typedef Future _RunPhaseForInput(int phaseNumber, AssetId primaryInput);

/// A [RunnerAssetReader] must implement some additional interfaces.
abstract class RunnerAssetReader implements MultiPackageAssetReader {}

/// An [AssetReader] that can provide actual paths to assets on disk.
abstract class PathProvidingAssetReader implements AssetReader {
  String pathTo(AssetId id);
}

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
  final AssetReader _delegate;
  final _globsRan = new Set<Glob>();
  final int _phaseNumber;
  final String _primaryPackage;
  final _RunPhaseForInput _runPhaseForInput;

  /// Whether the action using this reader writes to the generated directory.
  ///
  /// Actions which do not hide their outptus may not read assets produced in
  /// other packages by actions which do hide their outputs.
  final bool _outputsHidden;

  /// The assets read during this step in sorted order.
  final assetsRead = new SplayTreeSet<AssetId>();

  SingleStepReader(this._delegate, this._assetGraph, this._phaseNumber,
      this._outputsHidden, this._primaryPackage, this._runPhaseForInput);

  /// The [Glob]s which have been searched with [findAssets].
  ///
  /// A change in the set of assets matching a searched glob indicates that the
  /// builder may behave differently on the next build.
  Iterable<Glob> get globsRan => _globsRan;

  /// Checks whether [id] can be read by this step - attempting to build the
  /// asset if necessary.
  FutureOr<bool> _isReadable(AssetId id) {
    assetsRead.add(id);
    var node = _assetGraph.get(id);
    if (node == null) {
      _assetGraph.add(new SyntheticSourceAssetNode(id));
      return false;
    }
    return _isReadableNode(node);
  }

  /// Checks whether [node] can be read by this step - attempting to build the
  /// asset if necessary.
  FutureOr<bool> _isReadableNode(AssetNode node) {
    if (node is GeneratedAssetNode) {
      if (node.phaseNumber >= _phaseNumber) return false;
      if (!_outputsHidden &&
          node.isHidden &&
          node.id.package != _primaryPackage) return false;
      return _doAfter(_ensureAssetIsBuilt(node.id),
          (_) => node.wasOutput && !node.isFailure);
    }
    return node.isReadable && node.isValidInput;
  }

  @override
  Future<bool> canRead(AssetId id) {
    return _toFuture(_doAfter(_isReadable(id), (bool isReadable) {
      if (!isReadable) return false;
      var node = _assetGraph.get(id);
      FutureOr<bool> _canRead() {
        if (node is GeneratedAssetNode) {
          // Short circut, we know this file exists because its readable and it was
          // output.
          return true;
        } else {
          return _delegate.canRead(id);
        }
      }

      return _doAfter(_canRead(), (bool canRead) {
        if (!canRead) return false;
        return _doAfter(_ensureDigest(id), (_) => true);
      });
    }));
  }

  @override
  Future<Digest> digest(AssetId id) {
    return _toFuture(_doAfter(_isReadable(id), (bool isReadable) {
      if (!isReadable) {
        return new Future.error(new AssetNotFoundException(id));
      }
      return _ensureDigest(id);
    }));
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) {
    return _toFuture(_doAfter(_isReadable(id), (bool isReadable) {
      if (!isReadable) {
        return new Future.error(new AssetNotFoundException(id));
      }
      return _doAfter(_ensureDigest(id), (_) => _delegate.readAsBytes(id));
    }));
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) {
    return _toFuture(_doAfter(_isReadable(id), (bool isReadable) {
      if (!isReadable) {
        return new Future.error(new AssetNotFoundException(id));
      }
      return _doAfter(_ensureDigest(id),
          (_) => _delegate.readAsString(id, encoding: encoding));
    }));
  }

  @override
  Stream<AssetId> findAssets(Glob glob) async* {
    _globsRan.add(glob);
    var potentialMatches = _assetGraph
        .packageNodes(_primaryPackage)
        .where((n) => glob.matches(n.id.path))
        .toList();
    for (var node in potentialMatches) {
      if (await _isReadableNode(node)) yield node.id;
    }
  }

  FutureOr<dynamic> _ensureAssetIsBuilt(AssetId id) {
    if (_runPhaseForInput == null) return null;
    var node = _assetGraph.get(id);
    if (node is GeneratedAssetNode &&
        node.state != GeneratedNodeState.upToDate) {
      return _runPhaseForInput(node.phaseNumber, node.primaryInput);
    }
    return null;
  }

  FutureOr<Digest> _ensureDigest(AssetId id) {
    var node = _assetGraph.get(id);
    if (node?.lastKnownDigest != null) return node.lastKnownDigest;
    return _delegate.digest(id).then((digest) => node.lastKnownDigest = digest);
  }
}

/// Invokes [callback] and returns the result as soon as possible. This will
/// happen synchronously if [value] is available.
FutureOr<S> _doAfter<T, S>(FutureOr<T> value, FutureOr<S> callback(T value)) {
  if (value is Future<T>) {
    return value.then(callback);
  } else {
    return callback(value as T);
  }
}

/// Converts [value] to a [Future] if it is not already.
Future<T> _toFuture<T>(FutureOr<T> value) =>
    value is Future<T> ? value : new Future.value(value);
