import 'package:build/build.dart';

import 'package:path/path.dart' as p;

import 'asset_writer.dart';

/// A filter for determining whether an Asset can be read during the active
/// phase.
///
/// Valid assets are known ahead of time when running in worker mode, but not
/// when running locally. For consistency disallow reading assets that are
/// written in the current phase.
class AssetFilter {
  final Set<String> _knownValidAssets;
  final Map<String, String> _packageMap;
  final BazelAssetWriter _assetWriter;

  AssetFilter(this._knownValidAssets, this._packageMap, this._assetWriter);

  bool isValid(AssetId id) {
    if (_knownValidAssets != null) {
      var packagePath = _packageMap[id.package];
      if (packagePath == null) return false;
      return _knownValidAssets.contains(p.join(packagePath, id.path));
    }
    return !_assetWriter.assetsWritten.containsKey(id);
  }
}
