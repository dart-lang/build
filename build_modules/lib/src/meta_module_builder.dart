// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:glob/glob.dart';

import 'common.dart';
import 'meta_module.dart';
import 'module_cache.dart';
import 'module_library_builder.dart';
import 'platform.dart';

/// The extension for serialized meta module assets for a specific platform.
String metaModuleExtension(DartPlatform platform) =>
    '.${platform.name}.meta_module.raw';

/// Creates `.meta_module` file for any Dart library.
///
/// This file contains information about the full computed
/// module structure for the package.
class MetaModuleBuilder implements Builder {
  @override
  final Map<String, List<String>> buildExtensions;

  final ModuleStrategy strategy;

  final DartPlatform _platform;

  MetaModuleBuilder(this._platform, {ModuleStrategy strategy})
      : strategy = strategy ?? ModuleStrategy.coarse,
        buildExtensions = {
          r'$lib$': [metaModuleExtension(_platform)]
        };

  factory MetaModuleBuilder.forOptions(
          DartPlatform platform, BuilderOptions options) =>
      MetaModuleBuilder(platform, strategy: moduleStrategy(options));

  @override
  Future build(BuildStep buildStep) async {
    if (buildStep.inputId.package == r'$sdk') return;

    var libraryAssets =
        await buildStep.findAssets(Glob('**$moduleLibraryExtension')).toList();

    var metaModule = await MetaModule.forLibraries(
        buildStep, libraryAssets, strategy, _platform);
    var id = AssetId(
        buildStep.inputId.package, 'lib/${metaModuleExtension(_platform)}');
    var metaModules = await buildStep.fetchResource(metaModuleCache);
    await metaModules.write(id, buildStep, metaModule);
  }
}
