// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

import 'meta_module.dart';
import 'meta_module_clean_builder.dart';
import 'modules.dart';

/// The extension for serialized module assets.
const moduleExtension = '.module';

/// A map of primary [AssetId] to corresponding [Module].
final _primaryToClean =
    new Resource<Map<AssetId, Module>>(() => {}, dispose: (map) => map.clear());

/// Set of all [MetaModule]s which have been processed.
final _readMetas = new Resource<Set<AssetId>>(() => new Set<AssetId>(),
    dispose: (s) => s.clear());

/// Map of [AssetId] to corresponding primary [AssetId] within the same
/// [Module].
final _assetToPrimary = new Resource<Map<AssetId, AssetId>>(() => {},
    dispose: (map) => map.clear());

/// Updates dependencies from the provided [Module] so that they point to the
/// primary resource of the dependencies corresponding [Module].
///
/// Note that this will process the clean meta modules for the module
/// dependencies if necessary.
Future<Module> _cleanModuleDeps(
    BuildStep buildStep,
    Module module,
    Map<AssetId, AssetId> assetToPrimary,
    Map<AssetId, Module> primaryToClean,
    Set<AssetId> readMetas) async {
  var cleanedDeps = new Set<AssetId>();
  for (var dep in module.directDependencies) {
    // Since we are not using the course strategy we can safely add
    // all dependencies in the same package as they will have a
    // corresponding module file.
    if (dep.package == module.primarySource.package) {
      cleanedDeps.add(dep);
      continue;
      // It is possible that this dep came from another fine grained
      // module. Look for the corresponding module file.
    } else if (await buildStep.canRead(dep.changeExtension(moduleExtension))) {
      cleanedDeps.add(dep);
      continue;
    }
    // The dep must have come from a coarse module. Look for the corresponding
    // primary source.
    var depAsset = new AssetId(dep.package, 'lib/$metaModuleCleanExtension');
    if (await buildStep.canRead(depAsset) && !readMetas.contains(depAsset)) {
      await _processMeta(
          buildStep, depAsset, primaryToClean, assetToPrimary, readMetas);
    }
    var primaryDep = assetToPrimary[dep];
    cleanedDeps.add(primaryDep);
  }
  return new Module(module.primarySource, module.sources, cleanedDeps);
}

Future<Null> _processMeta(
    BuildStep buildStep,
    AssetId asset,
    Map<AssetId, Module> primaryToClean,
    Map<AssetId, AssetId> assetToPrimary,
    Set<AssetId> readMetas) async {
  readMetas.add(asset);
  var meta = new MetaModule.fromJson(
      json.decode(await buildStep.readAsString(asset)) as Map<String, dynamic>);
  for (var module in meta.modules) {
    primaryToClean[module.primarySource] = module;
    for (var source in module.sources) {
      assetToPrimary[source] = module.primarySource;
    }
  }
}

enum Strategy { fine, course }

/// Creates `.module` files for any `.dart` file that is the primary dart
/// source of a [Module].
class ModuleBuilder implements Builder {
  final bool _isCoarse;
  const ModuleBuilder({bool isCourse: false}) : _isCoarse = isCourse;

  static Strategy _getStrategy(BuilderOptions options) {
    var config = (options.config['strategy'] ?? 'coarse') as String;
    switch (config) {
      case 'coarse':
        return Strategy.course;
      case 'fine':
        return Strategy.fine;
        break;
      default:
        throw 'Unexpected ModuleBuilder strategy: ${options.config['strategy']}';
    }
  }

  factory ModuleBuilder.forOptions(BuilderOptions options) {
    return new ModuleBuilder(
        isCourse: _getStrategy(options) == Strategy.course);
  }

  @override
  final buildExtensions = const {
    '.dart': const [moduleExtension]
  };

  @override
  Future build(BuildStep buildStep) async {
    Module outputModule;
    var assetToPrimary = await buildStep.fetchResource(_assetToPrimary);
    var readMetas = await buildStep.fetchResource(_readMetas);
    var primaryToClean = await buildStep.fetchResource(_primaryToClean);
    if (_isCoarse) {
      var asset = new AssetId(
          buildStep.inputId.package, 'lib/$metaModuleCleanExtension');
      // Even though the meta file may have already been processed call canRead
      // to ensure it is properly marked as a dependency.
      await buildStep.canRead(asset);
      if (!readMetas.contains(asset)) {
        await _processMeta(
            buildStep, asset, primaryToClean, assetToPrimary, readMetas);
      }
      outputModule = primaryToClean[buildStep.inputId];
    } else {
      if (!await buildStep.resolver.isLibrary(buildStep.inputId)) return;

      var library = await buildStep.inputLibrary;
      if (!isPrimary(library)) return;

      var module = new Module.forLibrary(library);
      outputModule = await _cleanModuleDeps(
          buildStep, module, assetToPrimary, primaryToClean, readMetas);
    }
    if (outputModule == null) return;
    if (outputModule.primarySource != buildStep.inputId) return;
    await buildStep.writeAsString(
        buildStep.inputId.changeExtension(moduleExtension),
        json.encode(outputModule.toJson()));
  }
}
