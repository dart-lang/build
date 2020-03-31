// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner_core/build_runner_core.dart';
import 'package:package_config/package_config.dart';

PackageGraph buildPackageGraph(Map<PackageNode, Iterable<String>> packages) {
  var packagesByName = Map<String, PackageNode>.fromIterable(packages.keys,
      key: (p) => (p as PackageNode).name);
  for (final package in packages.keys) {
    package.dependencies
        .addAll(packages[package].map((name) => packagesByName[name]));
  }
  var root = packages.keys.singleWhere((n) => n.isRoot);
  return PackageGraph.fromRoot(root);
}

PackageNode package(String packageName,
        {String path, DependencyType type, LanguageVersion languageVersion}) =>
    PackageNode(
        packageName, path, type, languageVersion ?? LanguageVersion(0, 0));

PackageNode rootPackage(String packageName,
        {String path, LanguageVersion languageVersion}) =>
    PackageNode(packageName, path, DependencyType.path,
        languageVersion ?? LanguageVersion(0, 0),
        isRoot: true);
