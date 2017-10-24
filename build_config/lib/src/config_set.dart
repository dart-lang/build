// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'build_config.dart';
import 'pubspec.dart';

/// The [BuildConfig]s for a package and it's dependencies.
class BuildConfigSet {
  final BuildConfig local;
  final Map<String, BuildConfig> dependencies;

  static Future<BuildConfigSet> forPackages(
          String localPackagePath,
          Map<String, String> dependencyPaths,
          Map<String, Pubspec> dependencyPubspecs) async =>
      new BuildConfigSet(await _readLocalBuildConfig(localPackagePath),
          await _readBuildConfigs(dependencyPaths, dependencyPubspecs));

  BuildConfigSet(this.local, this.dependencies);

  BuildConfig operator [](String packageName) =>
      packageName == local.packageName ? local : dependencies[packageName];

  bool get hasCodegen =>
      _hasCodegen(local) || dependencies.values.any(_hasCodegen);
}

bool _hasCodegen(BuildConfig config) => config.builderDefinitions.isNotEmpty;

/// Returns a Map from packageName to the [BuildConfig] for the package.
Future<Map<String, BuildConfig>> _readBuildConfigs(
    Map<String, String> packagePaths, Map<String, Pubspec> pubspecs) async {
  final buildConfigs = <String, BuildConfig>{};
  for (var package in packagePaths.keys) {
    buildConfigs[package] = await BuildConfig.fromPackageDir(
        pubspecs[package], packagePaths[package]);
  }
  return buildConfigs;
}

Future<BuildConfig> _readLocalBuildConfig(String packagePath) async {
  final pubspec = await Pubspec.fromPackageDir(packagePath);
  return BuildConfig.fromPackageDir(pubspec, packagePath,
      includeWebSources: true);
}
