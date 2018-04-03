import 'dart:async';
import 'dart:convert';
import 'package:build/build.dart';
import 'package:build_runner/src/asset_graph/graph.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';

class FinalizedReader implements AssetReader {
  final AssetReader _delegate;
  final AssetGraph _assetGraph;

  FinalizedReader(
    this._delegate,
    this._assetGraph,
  );

  @override
  Future<bool> canRead(AssetId id) async {
    if (!await _delegate.canRead(id)) return false;
    if (_assetGraph.get(id).isDeleted) return false;
    return true;
  }

  @override
  Future<Digest> digest(AssetId id) => _delegate.digest(id);

  @override
  Future<List<int>> readAsBytes(AssetId id) => _delegate.readAsBytes(id);

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding: utf8}) =>
      _delegate.readAsString(id, encoding: encoding);

  @override
  Stream<AssetId> findAssets(Glob glob) => _delegate.findAssets(glob);
}
