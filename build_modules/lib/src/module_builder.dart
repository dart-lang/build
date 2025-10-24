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
import 'scratch_space.dart';

/// The extension for serialized module assets.
String moduleExtension(DartPlatform platform) => '.${platform.name}.module';

/// Creates `.module` files for any `.dart` file that is the primary dart
/// source of a [Module].
class ModuleBuilder implements Builder {
  final DartPlatform _platform;

  /// Emits DDC code with the Library Bundle module system, which supports hot
  /// reload.
  ///
  /// If set, this builder will consume raw meta modules (instead of clean).
  /// Clean meta modules are only used for DDC's AMD module system due its
  /// requirement that self-referential libraries be bundled.
  final bool usesWebHotReload;

  ModuleBuilder(this._platform, {this.usesWebHotReload = false})
    : buildExtensions = {
        '.dart': [moduleExtension(_platform)],
      };

  @override
  final Map<String, List<String>> buildExtensions;

  @override
  Future build(BuildStep buildStep) async {
    final metaModules = await buildStep.fetchResource(metaModuleCache);
    final metaModuleExtensionString =
        usesWebHotReload
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
    final serializedLibrary = await buildStep.readAsString(
      buildStep.inputId.changeExtension(moduleLibraryExtension),
    );
    final libraryModule = ModuleLibrary.deserialize(
      buildStep.inputId,
      serializedLibrary,
    );
    final scratchSpace = await buildStep.fetchResource(scratchSpaceResource);
    if (outputModule == null && libraryModule.hasMain) {
      outputModule = metaModule.modules.firstWhere(
        (m) => m.sources.contains(buildStep.inputId),
      );
    }
    if (outputModule == null) return;
    final modules = await buildStep.fetchResource(moduleCache);
    await modules.write(
      buildStep.inputId.changeExtension(moduleExtension(_platform)),
      buildStep,
      outputModule,
    );
    if (usesWebHotReload) {
      // All sources must be declared before the Frontend Server is invoked, as
      // it only accepts the main entrypoint as its compilation target.
      await buildStep.trackStage(
        'EnsureAssets',
        () => scratchSpace.ensureAssets(outputModule!.sources, buildStep),
      );
    }
  }
}
