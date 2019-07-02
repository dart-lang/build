// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';

import 'meta_module_clean_builder.dart';
import 'module_cache.dart';
import 'module_library.dart';
import 'module_library_builder.dart' show moduleLibraryExtension;
import 'modules.dart';
import 'platform.dart';

/// The extension for serialized module assets.
String moduleExtension(DartPlatform platform) => '.${platform.name}.module';

/// Creates `.module` files for any `.dart` file that is the primary dart
/// source of a [Module].
class ModuleBuilder implements Builder {
  final DartPlatform _platform;

  ModuleBuilder(this._platform)
      : buildExtensions = {
          '.dart': [moduleExtension(_platform)]
        };

  @override
  final Map<String, List<String>> buildExtensions;

  @override
  Future build(BuildStep buildStep) async {
    final cleanMetaModules = await buildStep.fetchResource(metaModuleCache);
    final metaModule = await cleanMetaModules.find(
        AssetId(buildStep.inputId.package,
            'lib/${metaModuleCleanExtension(_platform)}'),
        buildStep);
    var outputModule = metaModule.modules.firstWhere(
        (m) => m.primarySource == buildStep.inputId,
        orElse: () => null);
    if (outputModule == null) {
      final serializedLibrary = await buildStep.readAsString(
          buildStep.inputId.changeExtension(moduleLibraryExtension));
      final libraryModule =
          ModuleLibrary.deserialize(buildStep.inputId, serializedLibrary);
      if (libraryModule.hasMain) {
        outputModule = metaModule.modules
            .firstWhere((m) => m.sources.contains(buildStep.inputId));
      }
    }
    if (outputModule == null) return;
    final modules = await buildStep.fetchResource(moduleCache);
    await modules.write(
        buildStep.inputId.changeExtension(moduleExtension(_platform)),
        buildStep,
        outputModule);
  }
}
