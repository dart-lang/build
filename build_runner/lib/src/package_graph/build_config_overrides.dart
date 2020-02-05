// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build_config/build_config.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

final _log = Logger('BuildConfigOverrides');

Future<Map<String, BuildConfig>> findBuildConfigOverrides(
    PackageGraph packageGraph, String configKey) async {
  final configs = <String, BuildConfig>{};
  final configFiles = Glob('*.build.yaml').list();
  await for (final file in configFiles) {
    if (file is File) {
      final packageName = p.basename(file.path).split('.').first;
      final packageNode = packageGraph.allPackages[packageName];
      if (packageNode == null) {
        _log.warning('A build config override is provided for $packageName but '
            'that package does not exist. '
            'Remove the ${p.basename(file.path)} override or add a dependency '
            'on $packageName.');
        continue;
      }
      final yaml = file.readAsStringSync();
      final config = BuildConfig.parse(
        packageName,
        packageNode.dependencies.map((n) => n.name),
        yaml,
        configYamlPath: file.path,
      );
      configs[packageName] = config;
    }
  }
  if (configKey != null) {
    final file = File('build.$configKey.yaml');
    if (!file.existsSync()) {
      _log.warning('Cannot find build.$configKey.yaml for specified config.');
      throw CannotBuildException();
    }
    final yaml = file.readAsStringSync();
    final config = BuildConfig.parse(
      packageGraph.root.name,
      packageGraph.root.dependencies.map((n) => n.name),
      yaml,
      configYamlPath: file.path,
    );
    configs[packageGraph.root.name] = config;
  }
  return configs;
}
