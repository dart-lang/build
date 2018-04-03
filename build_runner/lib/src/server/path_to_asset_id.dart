// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:path/path.dart' as p;

AssetId pathToAssetId(
    String rootPackage, String rootDir, List<String> pathSegments) {
  var packagesIndex = pathSegments.indexOf('packages');
  return packagesIndex >= 0
      ? new AssetId(pathSegments[packagesIndex + 1],
          p.join('lib', p.joinAll(pathSegments.sublist(packagesIndex + 2))))
      : new AssetId(rootPackage, p.joinAll([rootDir].followedBy(pathSegments)));
}
