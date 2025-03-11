import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';

import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../util/constants.dart';

/// Wraps an [AssetPathProvider] to place hidden generated files in the build
/// cache directory.
///
/// Assets that are in the provided [AssetGraph], have node type
/// [NodeType.generated] and have `isHidden == true` are mapped to
/// [generatedOutputDirectory].
class BuildCacheAssetPathProvider implements AssetPathProvider {
  final AssetPathProvider _delegate;
  final AssetGraph _assetGraph;
  final String _rootPackage;

  BuildCacheAssetPathProvider({
    required AssetPathProvider delegate,
    required AssetGraph assetGraph,
    required String rootPackage,
  }) : _delegate = delegate,
       _assetGraph = assetGraph,
       _rootPackage = rootPackage;

  @override
  String pathFor(AssetId id) => _delegate.pathFor(_cacheLocation(id));

  AssetId _cacheLocation(AssetId id) {
    if (id.path.startsWith(generatedOutputDirectory) ||
        id.path.startsWith(cacheDir)) {
      return id;
    }
    if (!_assetGraph.contains(id)) {
      return id;
    }
    final assetNode = _assetGraph.get(id)!;
    if (assetNode.type == NodeType.generated &&
        assetNode.generatedNodeConfiguration.isHidden) {
      return AssetId(
        _rootPackage,
        '$generatedOutputDirectory/${id.package}/${id.path}',
      );
    }
    return id;
  }
}
