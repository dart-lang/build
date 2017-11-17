// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner/build_runner.dart';

PackageGraph buildPackageGraph(
    String rootPackage, Map<PackageNode, Iterable<String>> packages) {
  var packagesByName = new Map<String, PackageNode>.fromIterable(packages.keys,
      key: (p) => (p as PackageNode).name);
  for (final package in packages.keys) {
    package.dependencies
        .addAll(packages[package].map((name) => packagesByName[name]));
  }
  return new PackageGraph.fromRoot(packagesByName[rootPackage]);
}

PackageNode package(String packageName, {String path, List<String> includes}) =>
    new PackageNode(packageName, '1.0.0', PackageDependencyType.path, path,
        includes: includes);
