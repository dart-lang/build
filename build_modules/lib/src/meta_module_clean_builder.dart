// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:graphs/graphs.dart';

import 'meta_module.dart';
import 'meta_module_builder.dart';
import 'module_cache.dart';
import 'modules.dart';
import 'platform.dart';

/// The extension for serialized clean meta module assets.
///
/// Clean in this context means all dependencies are primary sources.
/// Furthermore cyclic modules are merged into a single module.
String metaModuleCleanExtension(DartPlatform platform) =>
    '.${platform.name}.meta_module.clean';

/// Creates `.meta_module.clean` file for any Dart library.
///
/// This file contains information about the full computed
/// module structure for the package where each module's dependencies
/// are only primary sources.
///
/// Note if the raw meta module file can't be found for any of the
/// module's transitive dependencies there will be no output.
class MetaModuleCleanBuilder implements Builder {
  @override
  final Map<String, List<String>> buildExtensions;

  final DartPlatform _platform;

  MetaModuleCleanBuilder(this._platform)
      : buildExtensions = {
          metaModuleExtension(_platform): [metaModuleCleanExtension(_platform)]
        };

  @override
  Future build(BuildStep buildStep) async {
    var assetToModule = (await buildStep.fetchResource(_assetToModule))
        .putIfAbsent(_platform, () => {});
    var assetToPrimary = (await buildStep.fetchResource(_assetToPrimary))
        .putIfAbsent(_platform, () => {});
    var modules = await _transitiveModules(
        buildStep, buildStep.inputId, assetToModule, assetToPrimary, _platform);
    var connectedComponents = stronglyConnectedComponents<Module>(
        modules,
        (m) => m.directDependencies.map((d) =>
            assetToModule[d] ??
            Module(d, [d], [], _platform, false, isMissing: true)),
        equals: (a, b) => a.primarySource == b.primarySource,
        hashCode: (m) => m.primarySource.hashCode);
    Module merge(List<Module> c) =>
        _mergeComponent(c, assetToPrimary, _platform);
    bool primarySourceInPackage(Module m) =>
        m.primarySource.package == buildStep.inputId.package;
    // Ensure deterministic output by sorting the modules.
    var cleanModules = SplayTreeSet<Module>(
        (a, b) => a.primarySource.compareTo(b.primarySource))
      ..addAll(connectedComponents.map(merge).where(primarySourceInPackage));
    await buildStep.writeAsString(
        AssetId(buildStep.inputId.package,
            'lib/${metaModuleCleanExtension(_platform)}'),
        jsonEncode(MetaModule(cleanModules.toList())));
  }
}

/// Map of [AssetId] to corresponding non clean containing [Module] per
/// [DartPlatform].
final _assetToModule = Resource<Map<DartPlatform, Map<AssetId, Module>>>(
    () => {},
    dispose: (map) => map.clear());

/// Map of [AssetId] to corresponding primary [AssetId] within the same
/// clean [Module] per platform.
final _assetToPrimary = Resource<Map<DartPlatform, Map<AssetId, AssetId>>>(
    () => {},
    dispose: (map) => map.clear());

/// Returns a set of all modules transitively reachable from the provided meta
/// module asset.
Future<Set<Module>> _transitiveModules(
    BuildStep buildStep,
    AssetId metaAsset,
    Map<AssetId, Module> assetToModule,
    Map<AssetId, AssetId> assetToPrimary,
    DartPlatform platform) async {
  var dependentModules = <Module>{};
  // Ensures we only process a meta file once.
  var seenMetas = <AssetId>{}..add(metaAsset);
  var metaModules = await buildStep.fetchResource(metaModuleCache);
  var meta = await metaModules.find(buildStep.inputId, buildStep);
  var nextModules = List.of(meta.modules);
  while (nextModules.isNotEmpty) {
    var module = nextModules.removeLast();
    dependentModules.add(module);
    for (var source in module.sources) {
      assetToModule[source] = module;
      // The asset to primary map will be updated when the merged modules are
      // created. This is why we can't use the assetToModule map.
      assetToPrimary[source] = module.primarySource;
    }
    for (var dep in module.directDependencies) {
      var depMetaAsset =
          AssetId(dep.package, 'lib/${metaModuleExtension(platform)}');
      // The testing package is an odd package used by package:frontend_end
      // which doesn't really exist.
      // https://github.com/dart-lang/sdk/issues/32952
      if (seenMetas.contains(depMetaAsset) || dep.package == 'testing') {
        continue;
      }
      seenMetas.add(depMetaAsset);
      if (!await buildStep.canRead(depMetaAsset)) {
        log.warning('Unable to read module information for '
            'package:${depMetaAsset.package}, make sure you have a dependency '
            'on it in your pubspec.');
        continue;
      }
      var depMeta = await metaModules.find(depMetaAsset, buildStep);
      nextModules.addAll(depMeta.modules);
    }
  }
  return dependentModules;
}

/// Merges the modules in a strongly connected component.
///
/// Note this will clean the module dependencies as the merge happens.
/// The result will be that all dependencies are primary sources.
Module _mergeComponent(List<Module> connectedComponent,
    Map<AssetId, AssetId> assetToPrimary, DartPlatform platform) {
  var sources = <AssetId>{};
  var deps = <AssetId>{};
  // Sort the modules to deterministicly select the primary source.
  var components =
      SplayTreeSet<Module>((a, b) => a.primarySource.compareTo(b.primarySource))
        ..addAll(connectedComponent);
  var primarySource = components.first.primarySource;
  var isSupported = true;
  for (var module in connectedComponent) {
    sources.addAll(module.sources);
    isSupported = isSupported && module.isSupported;
    for (var dep in module.directDependencies) {
      var primaryDep = assetToPrimary[dep];
      if (primaryDep == null) continue;
      // This dep is now merged into sources so skip it.
      if (!components
          .map((c) => c.sources)
          .any((s) => s.contains(primaryDep))) {
        deps.add(primaryDep);
      }
    }
  }
  // Update map so that sources now point to the merged module.
  var mergedModule =
      Module(primarySource, sources, deps, platform, isSupported);
  for (var source in mergedModule.sources) {
    assetToPrimary[source] = mergedModule.primarySource;
  }
  return mergedModule;
}
