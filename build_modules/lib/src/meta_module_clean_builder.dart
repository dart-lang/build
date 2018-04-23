// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:graphs/graphs.dart';

import 'package:build/build.dart';
import 'meta_module.dart';
import 'meta_module_builder.dart';
import 'modules.dart';

/// The extension for serialized clean meta module assets.
///
/// Clean in this context means all dependencies are primary sources.
/// Furthermore cyclic modules are merged into a single module.
const metaModuleCleanExtension = '.meta_module.clean';

/// Creates `.meta_module.clean` file for any Dart library.
///
/// This file contains information about the full computed
/// module structure for the package where each module's dependencies
/// are only primary sources.
///
/// Note if the raw meta module file can't be found for any of the
/// module's transitive dependencies there will be no output.
class MetaModuleCleanBuilder implements Builder {
  const MetaModuleCleanBuilder();

  @override
  final buildExtensions = const {
    '$metaModuleExtension': const [metaModuleCleanExtension]
  };

  @override
  Future build(BuildStep buildStep) async {
    var assetToModule = await buildStep.fetchResource(_assetToModule);
    var assetToPrimary = await buildStep.fetchResource(_assetToPrimary);
    SplayTreeSet<Module> cleanModules;
    try {
      var modules = await _transitiveModules(
          buildStep, buildStep.inputId, assetToModule, assetToPrimary);
      var connectedComponents = stronglyConnectedComponents<AssetId, Module>(
          modules,
          (m) => m.primarySource,
          (m) => m.directDependencies
              .map((d) => assetToModule[d])
              .where((d) => d != null));
      Module merge(List<Module> c) => _mergeComponent(c, assetToPrimary);
      bool hasSourceInPackage(Module m) =>
          m.sources.any((s) => s.package == buildStep.inputId.package);
      // Ensure deterministic output by sorting the modules.
      cleanModules = new SplayTreeSet<Module>(
          (a, b) => a.primarySource.compareTo(b.primarySource))
        ..addAll(connectedComponents.map(merge).where(hasSourceInPackage));
    } on AssetNotFoundException {
      // Could not find the raw meta module file for one of this module's
      // dependency so we will forgo outputing a file to signal to the
      // module builder that it should use the fine strategy.
      return;
    }
    await buildStep.writeAsString(
        new AssetId(buildStep.inputId.package, 'lib/$metaModuleCleanExtension'),
        json.encode(new MetaModule(cleanModules.toList())));
  }
}

/// Map of [AssetId] to corresponding non clean containing [Module].
final _assetToModule =
    new Resource<Map<AssetId, Module>>(() => {}, dispose: (map) => map.clear());

/// Map of [AssetId] to corresponding primary [AssetId] within the same
/// clean [Module].
final _assetToPrimary = new Resource<Map<AssetId, AssetId>>(() => {},
    dispose: (map) => map.clear());

/// Returns a set of all modules transitively reachable from the provided meta
/// module asset.
Future<Set<Module>> _transitiveModules(
    BuildStep buildStep,
    AssetId metaAsset,
    Map<AssetId, Module> assetToModule,
    Map<AssetId, AssetId> assetToPrimary) async {
  var dependentModules = new Set<Module>();
  // Ensures we only process a meta file once.
  var seenMetas = new Set<AssetId>()..add(metaAsset);
  var meta = new MetaModule.fromJson(
      json.decode(await buildStep.readAsString(buildStep.inputId))
          as Map<String, dynamic>);
  var nextModules = <Module>[];
  nextModules.addAll(meta.modules);
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
      var depMetaAsset = new AssetId(dep.package, 'lib/$metaModuleExtension');
      // The testing package is an odd package used by package:frontend_end
      // which doesn't really exist.
      // https://github.com/dart-lang/sdk/issues/32952
      if (seenMetas.contains(depMetaAsset) || dep.package == 'testing') {
        continue;
      }
      seenMetas.add(depMetaAsset);
      var depMeta = new MetaModule.fromJson(
          json.decode(await buildStep.readAsString(depMetaAsset))
              as Map<String, dynamic>);
      nextModules.addAll(depMeta.modules);
    }
  }
  return dependentModules;
}

/// Merges the modules in a strongly connected component.
///
/// Note this will clean the module dependencies as the merge happens.
/// The result will be that all dependencies are primary sources.
Module _mergeComponent(
    List<Module> connectedComponent, Map<AssetId, AssetId> assetToPrimary) {
  var sources = new Set<AssetId>();
  var deps = new Set<AssetId>();
  // Sort the modules to deterministicly select the primary source.
  var components = new SplayTreeSet<Module>(
      (a, b) => a.primarySource.compareTo(b.primarySource))
    ..addAll(connectedComponent);
  var primarySource = components.first.primarySource;
  for (var module in connectedComponent) {
    sources.addAll(module.sources);
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
  var mergedModule = new Module(primarySource, sources, deps);
  for (var source in mergedModule.sources) {
    assetToPrimary[source] = mergedModule.primarySource;
  }
  return mergedModule;
}
