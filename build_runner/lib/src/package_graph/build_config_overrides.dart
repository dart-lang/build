// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build_config/build_config.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import 'package_graph.dart';

Future<Map<String, BuildConfig>> findBuildConfigOverrides(
    PackageGraph packageGraph, String configKey) async {
  final configs = <String, BuildConfig>{};
  final configFiles = new Glob('*.build.yaml').list();
  await for (final file in configFiles) {
    if (file is File) {
      final packageName = p.basename(file.path).split('.').first;
      final packageNode = packageGraph.allPackages[packageName];
      final yaml = file.readAsStringSync();
      final config = new BuildConfig.parse(
          packageName, packageNode.dependencies.map((n) => n.name), yaml);
      configs[packageName] = config;
    }
  }
  if (configKey != null) {
    final file = new File('build.$configKey.yaml');
    final yaml = file.readAsStringSync();
    final config = new BuildConfig.parse(packageGraph.root.name,
        packageGraph.root.dependencies.map((n) => n.name), yaml);
    configs[packageGraph.root.name] = config;
  }
  return configs;
}
