import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';

typedef Future RunPhaseForInput(int phaseNumber, AssetId primaryInput);

/// A [MultiPackageAssetReader] with the additional `lastModified` method.
abstract class RunnerAssetReader extends MultiPackageAssetReader {
  /// Asynchronously gets the last modified [DateTime] of [id].
  Future<DateTime> lastModified(AssetId id);
}

/// An [AssetReader] with a lifetime equivalent to that of a single Phase in a
/// build.
///
/// Tracks the assets read during the build and prevents reading files output
/// during the current or future phases.
class SinglePhaseReader implements AssetReader {
  final AssetGraph _assetGraph;
  final _assetsRead = new Set<AssetId>();
  final AssetReader _delegate;
  final _globsRan = new Set<Glob>();
  final int _phaseNumber;
  final String _primaryPackage;
  final RunPhaseForInput _runPhaseForInput;

  SinglePhaseReader(this._delegate, this._assetGraph, this._phaseNumber,
      this._primaryPackage, this._runPhaseForInput);

  Iterable<AssetId> get assetsRead => _assetsRead;
  Iterable<Glob> get globsRan => _globsRan;

  bool _isReadable(AssetId id) {
    var node = _assetGraph.get(id);
    if (node == null) return false;
    if (node is! GeneratedAssetNode) return true;
    return (node as GeneratedAssetNode).phaseNumber < _phaseNumber;
  }

  @override
  Future<bool> canRead(AssetId id) async {
    if (!_isReadable(id)) return new Future.value(false);
    _assetsRead.add(id);
    await _ensureAssetIsBuilt(id);
    return _delegate.canRead(id);
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    if (!_isReadable(id)) throw new AssetNotFoundException(id);
    _assetsRead.add(id);
    await _ensureAssetIsBuilt(id);
    return _delegate.readAsBytes(id);
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) async {
    if (!_isReadable(id)) throw new AssetNotFoundException(id);
    _assetsRead.add(id);
    await _ensureAssetIsBuilt(id);
    return _delegate.readAsString(id, encoding: encoding);
  }

  @override
  Stream<AssetId> findAssets(Glob glob) async* {
    _globsRan.add(glob);
    var potentialMatches = _assetGraph.allNodes
        .where((n) => n.id.package == _primaryPackage)
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
}
