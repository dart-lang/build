// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner_core/build_runner_core.dart';

PackageGraph buildPackageGraph(Map<PackageNode, Iterable<String>> packages) {
  var packagesByName = new Map<String, PackageNode>.fromIterable(packages.keys,
      key: (p) => (p as PackageNode).name);
  for (final package in packages.keys) {
    package.dependencies
        .addAll(packages[package].map((name) => packagesByName[name]));
  }
  var root = packages.keys.singleWhere((n) => n.isRoot);
  return new PackageGraph.fromRoot(root);
}

PackageNode package(String packageName, {String path, DependencyType type}) =>
    new PackageNode(packageName, path, type);

PackageNode rootPackage(String packageName, {String path}) =>
    new PackageNode(packageName, path, DependencyType.path, isRoot: true);
