// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:build/build.dart';

import 'common.dart';
import 'meta_module.dart';
import 'meta_module_clean_builder.dart';
import 'modules.dart';

/// The extension for serialized module assets.
const moduleExtension = '.module';

/// A map of package to corresponding clean [MetaModule].
final _cleanMetaModules = new Resource<_CleanMetaModuleCache>(
    () => new _CleanMetaModuleCache(),
    dispose: (c) => c.dispose());

class _CleanMetaModuleCache {
  final _modules = <String, Future<Result<MetaModule>>>{};

  void dispose() => _modules.clear();

  Future<MetaModule> find(String packageName, AssetReader reader) async {
    var cleanMetaAsset =
        new AssetId(packageName, 'lib/$metaModuleCleanExtension');
    if (!await reader.canRead(cleanMetaAsset)) return null;
    var metaResult = _modules.putIfAbsent(
        packageName,
        () => Result.capture(reader.readAsString(cleanMetaAsset).then((c) =>
            new MetaModule.fromJson(jsonDecode(c) as Map<String, dynamic>))));
    return Result.release(metaResult);
  }
}

/// Updates dependencies from the provided [Module] so that they point to the
/// primary resource of the dependencies corresponding [Module].
///
/// Note that this will process the clean meta modules for the module
/// dependencies if necessary.
Future<Module> _cleanModuleDeps(
    BuildStep buildStep, Module module, _CleanMetaModuleCache cache) async {
  var cleanedDeps = new Set<AssetId>();
  var depAssetToModules = <AssetId, Module>{};
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
    var metaModule = await cache.find(dep.package, buildStep);
    if (metaModule == null) {
      // The dep is also fine but it's individual modules will come in a later
      // phase. Need to recompute them.
      if (!depAssetToModules.containsKey(dep)) {
        var depLibrary = await buildStep.resolver.libraryFor(dep);
        var depModule = new Module.forLibrary(depLibrary);
        for (var source in depModule.sources) {
          depAssetToModules[source] = depModule;
        }
      }
      cleanedDeps.add(depAssetToModules[dep].primarySource);
    } else {
      // The dep has a course strategy
      cleanedDeps.add(metaModule.modules
          .firstWhere((m) => m.sources.contains(dep))
          .primarySource);
    }
  }
  return new Module(module.primarySource, module.sources, cleanedDeps);
}

/// Creates `.module` files for any `.dart` file that is the primary dart
/// source of a [Module].
class ModuleBuilder implements Builder {
  final bool _isCoarse;
  const ModuleBuilder({bool isCoarse}) : _isCoarse = isCoarse ?? true;

  factory ModuleBuilder.forOptions(BuilderOptions options) {
    return new ModuleBuilder(
        isCoarse: moduleStrategy(options) == ModuleStrategy.coarse);
  }

  @override
  final buildExtensions = const {
    '.dart': const [moduleExtension]
  };

  @override
  Future build(BuildStep buildStep) async {
    Module outputModule;
    var cleanMetaModules = await buildStep.fetchResource(_cleanMetaModules);
    var cleanMetaAsset =
        new AssetId(buildStep.inputId.package, 'lib/$metaModuleCleanExtension');
    // If we can't read the clean meta module it is likely that this package
    // is in a module cycle so fall back to the fine strategy.
    if (_isCoarse && await buildStep.canRead(cleanMetaAsset)) {
      var metaModule =
          await cleanMetaModules.find(buildStep.inputId.package, buildStep);
      outputModule = metaModule.modules
          .firstWhere((m) => m.sources.contains(buildStep.inputId));
    } else {
      if (!await buildStep.resolver.isLibrary(buildStep.inputId)) return;

      var library = await buildStep.inputLibrary;
      if (!isPrimary(library)) return;

      var module = new Module.forLibrary(library);
      outputModule =
          await _cleanModuleDeps(buildStep, module, cleanMetaModules);
    }
    if (outputModule == null) return;
    if (outputModule.primarySource != buildStep.inputId) return;
    await buildStep.writeAsString(
        buildStep.inputId.changeExtension(moduleExtension),
        json.encode(outputModule.toJson()));
  }
}
