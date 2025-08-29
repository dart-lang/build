// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:collection/collection.dart';

import 'meta_module_builder.dart';
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

  /// True if we use raw modules instead of clean modules.
  ///
  /// Clean meta modules are only used for DDC's AMD module system due its
  /// requirement that self-referential libraries be bundled.
  final bool useRawMetaModules;

  ModuleBuilder(this._platform, {this.useRawMetaModules = false})
    : buildExtensions = {
        '.dart': [moduleExtension(_platform)],
      };

  @override
  final Map<String, List<String>> buildExtensions;

  @override
  Future build(BuildStep buildStep) async {
    final metaModules = await buildStep.fetchResource(metaModuleCache);
    var metaModuleExtensionString =
        useRawMetaModules
            ? metaModuleExtension(_platform)
            : metaModuleCleanExtension(_platform);
    final metaModule =
        (await metaModules.find(
          AssetId(buildStep.inputId.package, 'lib/$metaModuleExtensionString'),
          buildStep,
        ))!;
    var outputModule = metaModule.modules.firstWhereOrNull(
      (m) => m.primarySource == buildStep.inputId,
    );
    if (outputModule == null) {
      final serializedLibrary = await buildStep.readAsString(
        buildStep.inputId.changeExtension(moduleLibraryExtension),
      );
      final libraryModule = ModuleLibrary.deserialize(
        buildStep.inputId,
        serializedLibrary,
      );
      if (libraryModule.hasMain) {
        outputModule = metaModule.modules.firstWhere(
          (m) => m.sources.contains(buildStep.inputId),
        );
      }
    }
    if (outputModule == null) return;
    final modules = await buildStep.fetchResource(moduleCache);
    await modules.write(
      buildStep.inputId.changeExtension(moduleExtension(_platform)),
      buildStep,
      outputModule,
    );
  }
}
