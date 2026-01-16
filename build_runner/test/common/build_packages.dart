// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner/src/internal.dart';
import 'package:package_config/package_config.dart';

BuildPackages createBuildPackages(
  Map<BuildPackage, Iterable<String>> packages,
) {
  final packagesByName = Map<String, BuildPackage>.fromIterable(
    packages.keys,
    key: (p) => (p as BuildPackage).name,
  );
  for (final package in packages.keys) {
    package.dependencies.addAll(
      packages[package]!.map((name) => packagesByName[name]!),
    );
  }
  final root = packages.keys.singleWhere((n) => n.isRoot);
  return BuildPackages.fromRoot(root);
}

BuildPackage package(
  String packageName, {
  String? path,
  LanguageVersion? languageVersion,
  bool isEditable = true,
}) => BuildPackage(
  packageName,
  path ?? '/$packageName',
  languageVersion,
  isEditable: isEditable,
);

BuildPackage rootPackage(
  String packageName, {
  String? path,
  LanguageVersion? languageVersion,
}) => BuildPackage(
  packageName,
  path ?? '/$packageName',
  languageVersion,
  isEditable: true,
  isRoot: true,
);
