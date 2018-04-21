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
const metaModuleCleanExtension = '.meta_module_clean';

/// Map of [AssetId] to corresponding primary [AssetId] within the same
/// [Module].
final _assetToModule =
    new Resource<Map<AssetId, Module>>(() => {}, dispose: (map) => map.clear());

/// Returns a set of all modules transitvely reachable from the provided meta
/// module asset.
Future<Set<Module>> _transitiveModules(BuildStep buildStep, AssetId metaAsset,
    Map<AssetId, Module> assetToModule) async {
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
    }
    for (var dep in module.directDependencies) {
      var depMetaAsset = new AssetId(dep.package, 'lib/$metaModuleExtension');
      if (!seenMetas.contains(depMetaAsset)) {
        seenMetas.add(depMetaAsset);
        if (await buildStep.canRead(depMetaAsset)) {
          var depMeta = new MetaModule.fromJson(
              json.decode(await buildStep.readAsString(depMetaAsset))
                  as Map<String, dynamic>);
          nextModules.addAll(depMeta.modules);
        } else {
          log.info('Unable to find meta module for dependency: $dep '
              'Are you missing a dependency on package:${dep.package}?');
        }
      }
    }
  }
  return dependentModules;
}

/// Merges the modules in a strongly connected component.
///
/// Note this will clean the module dependencies as the merge happens.
/// The result will be that all dependencies are primary sources.
Module _mergeComponent(
    List<Module> connectedComponent, Map<AssetId, Module> assetToModule) {
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
      var depModule = assetToModule[dep];
      if (depModule == null) continue;
      // This dep is now merged into sources so skip it.
      if (!components.contains(depModule)) deps.add(depModule.primarySource);
    }
  }
  return new Module(primarySource, sources, deps);
}

/// Creates `.meta_module_clean` file for any Dart library.
///
/// This file contains information about the full computed
/// module structure for the package with cleaned dependencies.
class MetaModuleCleanBuilder implements Builder {
  const MetaModuleCleanBuilder();

  @override
  final buildExtensions = const {
    '$metaModuleExtension': const [metaModuleCleanExtension]
  };

  @override
  Future build(BuildStep buildStep) async {
    var assetToModule = await buildStep.fetchResource(_assetToModule);
    var modules =
        await _transitiveModules(buildStep, buildStep.inputId, assetToModule);
    var connectedComponents = stronglyConnectedComponents<AssetId, Module>(
        modules,
        (m) => m.primarySource,
        (m) => m.directDependencies
            .map((d) => assetToModule[d])
            .where((d) => d != null));
    // Ensure deterministic output by sorting the modules.
    var cleanModules = new SplayTreeSet<Module>(
        (a, b) => a.primarySource.compareTo(b.primarySource));
    for (var connectedComponent in connectedComponents) {
      var cleanModule = _mergeComponent(connectedComponent, assetToModule);
      for (var source in cleanModule.sources) {
        if (source.package == buildStep.inputId.package) {
          cleanModules.add(cleanModule);
          break;
        }
      }
    }
    return buildStep.writeAsString(
        new AssetId(buildStep.inputId.package, 'lib/$metaModuleCleanExtension'),
        json.encode(new MetaModule(cleanModules.toList())));
  }
}
