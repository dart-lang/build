// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:build/build.dart';

import '../errors.dart';

/// Peform package name resolution and turn file paths into [AssetId]s.
Iterable<AssetId> findAssetIds(Iterable<String> inputs, String packagePath,
    Map<String, String> packageMap) sync* {
  final packageName = _findPackageName(packageMap, packagePath);
  for (var input in inputs) {
    if (!input.startsWith(packagePath)) {
      throw new CodegenError(
          'Cannot generate files for source "$input" because it is not '
          'in the current package ($packagePath). '
          'If this file is needed to generate other files, please add it to '
          'the `src_deps` of this rule');
    }
    var path = packagePath.isNotEmpty
        ? input.substring(packagePath.length + 1)
        : input;
    yield new AssetId(packageName, path);
  }
}

String _findPackageName(Map<String, String> packageMap, String packagePath) {
  for (var packageName in packageMap.keys) {
    if (packageMap[packageName] == packagePath) return packageName;
  }
  throw new CodegenError('Could not find package name for path $packagePath');
}
