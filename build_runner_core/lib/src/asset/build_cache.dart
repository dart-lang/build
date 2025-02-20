import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';

import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../util/constants.dart';
import 'writer.dart';

/// [AssetPathProvider] that places "hidden" generated output in the build
/// cache directory.
class BuildCacheAssetPathProvider implements AssetPathProvider {
  final AssetPathProvider _delegate;
  final AssetGraph _assetGraph;
  final String _rootPackage;

  BuildCacheAssetPathProvider(
    this._delegate,
    this._assetGraph,
    this._rootPackage,
  );

  @override
  String pathFor(AssetId id) =>
      _delegate.pathFor(_cacheLocation(id, _assetGraph, _rootPackage));
}

// TODO(davidmorgan): refactor this in the same way as the reader.
class BuildCacheWriter implements RunnerAssetWriter {
  final AssetGraph _assetGraph;
  final RunnerAssetWriter _delegate;
  final String _rootPackage;

  BuildCacheWriter(this._delegate, this._assetGraph, this._rootPackage);

  @override
  Future writeAsBytes(AssetId id, List<int> content) => _delegate.writeAsBytes(
    _cacheLocation(id, _assetGraph, _rootPackage),
    content,
  );

  @override
  Future writeAsString(
    AssetId id,
    String content, {
    Encoding encoding = utf8,
  }) => _delegate.writeAsString(
    _cacheLocation(id, _assetGraph, _rootPackage),
    content,
    encoding: encoding,
  );

  @override
  Future delete(AssetId id) =>
      _delegate.delete(_cacheLocation(id, _assetGraph, _rootPackage));

  @override
  Future<void> completeBuild() async {}
}

AssetId _cacheLocation(AssetId id, AssetGraph assetGraph, String rootPackage) {
  if (id.path.startsWith(generatedOutputDirectory) ||
      id.path.startsWith(cacheDir)) {
    return id;
  }
  if (!assetGraph.contains(id)) {
    return id;
  }
  final assetNode = assetGraph.get(id);
  if (assetNode is GeneratedAssetNode && assetNode.isHidden) {
    return AssetId(
      rootPackage,
      '$generatedOutputDirectory/${id.package}/${id.path}',
    );
  }
  return id;
}
