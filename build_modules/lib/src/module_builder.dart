// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

import 'meta_module.dart';
import 'meta_module_builder.dart';
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

void _cacheAssetToPrimary(
    MetaModule meta, Map<AssetId, AssetId> assetToPrimary) {
  for (var module in meta.modules) {
    for (var source in module.sources) {
      assetToPrimary[source] = module.primarySource;
    }
  }
}

/// Removes dependencies from the provided [Module] so that only those with
/// corresponding module files remain.
Future<Module> _cleanModuleDeps(
    BuildStep buildStep, Module module, Map<AssetId, AssetId> assetToPrimary,
    {bool isCourseStrategy: false}) async {
  var cleanedDeps = new Set<AssetId>();
  for (var dep in module.directDependencies) {
    if (!isCourseStrategy) {
      // Since we are not using the ccourse strategy we can safely add
      // all dependencies in the same package as they will have a
      // corresponding module file.
      if (dep.package == module.primarySource.package) {
        cleanedDeps.add(dep);
        continue;
        // It is possible that this dep came from another fine grained
        // module. Look for the corresponding module file.
      } else if (await buildStep
          .canRead(dep.changeExtension(moduleExtension))) {
        cleanedDeps.add(dep);
        continue;
      }
    }
    var primaryDep = assetToPrimary[dep];
    if (primaryDep == null) {
      // We don't know the primary source for the dep so look for it
      // using the meta module file.
      var depMeta = new MetaModule.fromJson(json.decode(
              await buildStep.readAsString(
                  new AssetId(dep.package, 'lib/$metaModuleExtension')))
          as Map<String, dynamic>);
      _cacheAssetToPrimary(depMeta, assetToPrimary);
    }
    cleanedDeps.add(assetToPrimary[dep]);
  }
  return new Module(module.primarySource, module.sources, cleanedDeps);
}

/// Processes a [MetaModule] and adds to the [primaryToClean] cache.
Future<Null> _cacheCleanedModules(
    BuildStep buildStep,
    MetaModule meta,
    Map<AssetId, Module> primaryToClean,
    Map<AssetId, AssetId> assetToPrimary) async {
  _cacheAssetToPrimary(meta, assetToPrimary);
  for (var module in meta.modules) {
    primaryToClean[module.primarySource] = await _cleanModuleDeps(
        buildStep, module, assetToPrimary,
        isCourseStrategy: true);
  }
}

/// Creates `.module` files for any `.dart` file that is the primary dart
/// source of a [Module].
class ModuleBuilder implements Builder {
  final bool _isCoarse;
  const ModuleBuilder({bool isCourse: false}) : _isCoarse = isCourse;

  factory ModuleBuilder.forOptions(BuilderOptions options) {
    return new ModuleBuilder(isCourse: options.config['strategy'] == 'coarse');
  }

  @override
  final buildExtensions = const {
    '.dart': const [moduleExtension]
  };

  @override
  Future build(BuildStep buildStep) async {
    Module outputModule;
    var assetToPrimary = await buildStep.fetchResource(_assetToPrimary);
    if (_isCoarse) {
      var readMetas = await buildStep.fetchResource(_readMetas);
      var primaryToClean = await buildStep.fetchResource(_primaryToClean);
      var asset =
          new AssetId(buildStep.inputId.package, 'lib/$metaModuleExtension');
      // Even though the meta file may have already been processed call canRead
      // to ensure it is properly marked as a dependency.
      await buildStep.canRead(asset);
      if (!readMetas.contains(asset)) {
        var meta = new MetaModule.fromJson(
            json.decode(await buildStep.readAsString(asset))
                as Map<String, dynamic>);
        await _cacheCleanedModules(
            buildStep, meta, primaryToClean, assetToPrimary);
        readMetas.add(asset);
      }
      outputModule = primaryToClean[buildStep.inputId];
    } else {
      if (!await buildStep.resolver.isLibrary(buildStep.inputId)) return;

      var library = await buildStep.inputLibrary;
      if (!isPrimary(library)) return;

      var module = new Module.forLibrary(library);
      outputModule = await _cleanModuleDeps(buildStep, module, assetToPrimary);
    }
    if (outputModule == null) return;
    if (outputModule.primarySource != buildStep.inputId) return;
    await buildStep.writeAsString(
        buildStep.inputId.changeExtension(moduleExtension),
        json.encode(outputModule.toJson()));
  }
}
