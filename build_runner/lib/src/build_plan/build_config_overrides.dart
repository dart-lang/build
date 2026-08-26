// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/src/asset_id.dart';
import 'package:build_config/build_config.dart';
import 'package:built_collection/built_collection.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import '../exceptions.dart';
import '../io/reader_writer.dart';
import '../logging/build_log.dart';
import 'build_packages.dart';

Future<BuiltMap<String, BuildConfig>> findBuildConfigOverrides({
  required BuildPackages buildPackages,
  required ReaderWriter? readerWriter,
  required String? configKey,
}) async {
  final configs = <String, BuildConfig>{};
  final outputRoot = buildPackages.outputRoot;
  final configFiles = readerWriter!.assetFinder.find(
    Glob('*.build.yaml'),
    package: outputRoot,
  );
  await for (final id in configFiles) {
    final packageName = p.basename(id.path).split('.').first;
    final buildPackage = buildPackages[packageName];
    if (buildPackage == null) {
      buildLog.warning(
        'A build config override is provided for $packageName but '
        'that package does not exist. '
        'Remove the ${p.basename(id.path)} override or add a dependency '
        'on $packageName.',
      );
      continue;
    }
    final yaml = await readerWriter.readAsString(id);
    final config = BuildConfig.parse(
      packageName,
      buildPackage.dependencies,
      yaml,
      configYamlPath: id.path,
    );
    configs[packageName] = config;
  }
  if (configKey != null) {
    final id = AssetId(outputRoot, 'build.$configKey.yaml');
    if (!await readerWriter.canRead(id)) {
      buildLog.warning('Cannot find ${id.path} for specified config.');
      throw const CannotBuildException();
    }
    final yaml = await readerWriter.readAsString(id);
    final config = BuildConfig.parse(
      outputRoot,
      buildPackages[outputRoot]!.dependencies,
      yaml,
      configYamlPath: id.path,
    );
    if (config.builderDefinitions.isNotEmpty) {
      buildLog.warning(
        'Ignoring `builders` configuration in `build.$configKey.yaml` - '
        'overriding builder configuration is not supported.',
      );
    }
    configs[outputRoot] = config;
  }
  return configs.build();
}
