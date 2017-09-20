import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';

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
  final AssetReader _delegate;
  final Set<AssetId> _assetsRead = new Set();
  final AssetGraph _assetGraph;
  final int _phaseNumber;
  final String _primaryPackage;

  SinglePhaseReader(this._delegate, this._assetGraph, this._phaseNumber,
      this._primaryPackage);

  Iterable<AssetId> get assetsRead => _assetsRead;

  bool _isReadable(AssetId id) {
    var node = _assetGraph.get(id);
    if (node == null) return false;
    if (node is! GeneratedAssetNode) return true;
    return (node as GeneratedAssetNode).phaseNumber < _phaseNumber;
  }

  @override
  Future<bool> canRead(AssetId id) {
    if (!_isReadable(id)) return new Future.value(false);
    _assetsRead.add(id);
    return _delegate.canRead(id);
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    if (!_isReadable(id)) throw new AssetNotFoundException(id);
    _assetsRead.add(id);
    return _delegate.readAsBytes(id);
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: UTF8}) async {
    if (!_isReadable(id)) throw new AssetNotFoundException(id);
    _assetsRead.add(id);
    return _delegate.readAsString(id, encoding: encoding);
  }

  @override
  Iterable<AssetId> findAssets(Glob glob) => _assetGraph.allNodes
          .where((n) => n.id.package == _primaryPackage)
          .where((n) => glob.matches(n.id.path))
          .where((n) {
        if (n is GeneratedAssetNode) {
          return n.wasOutput && n.phaseNumber < _phaseNumber;
        } else {
          return true;
        }
      }).map((n) => n.id);
}
