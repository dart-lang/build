import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';

typedef Future RunPhaseForInput(int phaseNumber, AssetId primaryInput);

abstract class DigestAssetReader implements AssetReader {
  /// Asynchronously compute the digest for [id].
  Future<Digest> digest(AssetId id);
}

/// A [MultiPackageAssetReader] with the additional `lastModified` method.
abstract class RunnerAssetReader extends MultiPackageAssetReader
    implements DigestAssetReader {
  /// Asynchronously gets the last modified [DateTime] of [id].
  Future<DateTime> lastModified(AssetId id);
}

/// A [DigestAssetReader] that uses [md5] to compute [Digest]s.
abstract class Md5DigestReader implements DigestAssetReader, RunnerAssetReader {
  @override
  Future<Digest> digest(AssetId id) async {
    var bytes = await readAsBytes(id);
    return md5.convert(bytes);
  }
}

/// An [AssetReader] with a lifetime equivalent to that of a single Phase in a
/// build.
///
/// Tracks the assets read during the build and prevents reading files output
/// during the current or future phases.
class SinglePhaseReader implements AssetReader {
  final AssetGraph _assetGraph;
  final _assetsRead = new Set<AssetId>();
  final DigestAssetReader _delegate;
  final _globsRan = new Set<Glob>();
  final int _phaseNumber;
  final String _primaryPackage;
  final RunPhaseForInput _runPhaseForInput;

  SinglePhaseReader(this._delegate, this._assetGraph, this._phaseNumber,
      this._primaryPackage, this._runPhaseForInput);

  Iterable<AssetId> get assetsRead => _assetsRead;
  Iterable<Glob> get globsRan => _globsRan;

  bool _isReadable(AssetId id) {
    _assetsRead.add(id);
    var node = _assetGraph.get(id);
    if (node == null) {
      _assetGraph.add(new SyntheticAssetNode(id));
      return false;
    }
    if (node is SyntheticAssetNode) return false;
    if (node is SourceAssetNode) return true;
    assert(node is GeneratedAssetNode);
    return (node as GeneratedAssetNode).phaseNumber < _phaseNumber;
  }

  @override
  Future<bool> canRead(AssetId id) async {
    if (!_isReadable(id)) return new Future.value(false);
    await _ensureAssetIsBuilt(id);
    await _ensureDigest(id);
    var node = _assetGraph.get(id);
    if (node is GeneratedAssetNode) {
      // Short circut, we know this file exists because its readable and it was
      // output.
      return node.wasOutput;
    } else {
      return _delegate.canRead(id);
    }
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
    var node = _assetGraph.get(id);
    if (node is GeneratedAssetNode && node.needsUpdate) {
      await _runPhaseForInput(node.phaseNumber, node.primaryInput);
    }
  }

  Future<Null> _ensureDigest(AssetId id) async {
    var node = _assetGraph.get(id);
    node.lastKnownDigest ??= await _delegate.digest(id);
  }
}
