// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:build/build.dart';

import 'package:path/path.dart' as p;

/// A filter for determining whether an Asset can be read during the active
/// phase.
///
/// Valid assets are known ahead of time when running in worker mode, but not
/// when running locally. For consistency disallow reading assets that are
/// written in the current phase.
class AssetFilter {
  final Set<String> _knownValidAssets;
  final Map<String, String> _packageMap;
  AssetWriterSpy _assetWriter;

  AssetFilter(this._knownValidAssets, this._packageMap);

  bool isValid(AssetId id) {
    assert(_assetWriter != null);
    if (_knownValidAssets != null) {
      var packagePath = _packageMap[id.package];
      if (packagePath == null) return false;
      return _knownValidAssets.contains(p.join(packagePath, id.path));
    }
    return !_assetWriter.assetsWritten.contains(id);
  }

  void startPhase(AssetWriterSpy assetWriter) => _assetWriter = assetWriter;
}
