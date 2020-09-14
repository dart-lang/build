// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:graphs/graphs.dart';
import 'package:path/path.dart' as p;
import 'package:json_annotation/json_annotation.dart';

import 'common.dart';
import 'module_library.dart';
import 'modules.dart';
import 'platform.dart';

part 'meta_module.g.dart';

/// Returns the top level directory in [path].
///
/// Throws an [ArgumentError] if [path] is just a filename with no directory.
String _topLevelDir(String path) {
  var parts = p.url.split(p.url.normalize(path));
  String error;
  if (parts.length == 1) {
    error = 'The path `$path` does not contain a directory.';
  } else if (parts.first == '..') {
    error = 'The path `$path` reaches outside the root directory.';
  }
  if (error != null) {
    throw ArgumentError(
        'Cannot compute top level dir for path `$path`. $error');
  }
  return parts.first;
}

/// Creates a module containing [componentLibraries].
Module _moduleForComponent(
    List<ModuleLibrary> componentLibraries, DartPlatform platform) {
  // Name components based on first alphabetically sorted node, preferring
  // public srcs (not under lib/src).
  var sources = componentLibraries.map((n) => n.id).toSet();
  var nonSrcIds = sources.where((id) => !id.path.startsWith('lib/src/'));
  var primaryId =
      nonSrcIds.isNotEmpty ? nonSrcIds.reduce(_min) : sources.reduce(_min);
  // Expand to include all the part files of each node, these aren't
  // included as individual `_AssetNodes`s in `connectedComponents`.
  sources.addAll(componentLibraries.expand((n) => n.parts));
  var directDependencies = <AssetId>{}
    ..addAll(componentLibraries.expand((n) => n.depsForPlatform(platform)))
    ..removeAll(sources);
  var isSupported = componentLibraries
      .expand((l) => l.sdkDeps)
      .every(platform.supportsLibrary);
  return Module(primaryId, sources, directDependencies, platform, isSupported);
}

/// Gets the local (same top level dir of the same package) transitive deps of
/// [module] using [assetsToModules].
Set<AssetId> _localTransitiveDeps(
    Module module, Map<AssetId, Module> assetsToModules) {
  var localTransitiveDeps = <AssetId>{};
  var nextIds = module.directDependencies;
  var seenIds = <AssetId>{};
  while (nextIds.isNotEmpty) {
    var ids = nextIds;
    seenIds.addAll(ids);
    nextIds = <AssetId>{};
    for (var id in ids) {
      var module = assetsToModules[id];
      if (module == null) continue; // Skip non-local modules
      if (localTransitiveDeps.add(module.primarySource)) {
        nextIds.addAll(module.directDependencies.difference(seenIds));
      }
    }
  }
  return localTransitiveDeps;
}

/// Creates a map of modules to the entrypoint modules that transitively
/// depend on those modules.
Map<AssetId, Set<AssetId>> _findReverseEntrypointDeps(
    Iterable<Module> entrypointModules, Iterable<Module> modules) {
  var reverseDeps = <AssetId, Set<AssetId>>{};
  var assetsToModules = <AssetId, Module>{};
  for (var module in modules) {
    for (var assetId in module.sources) {
      assetsToModules[assetId] = module;
    }
  }
  for (var module in entrypointModules) {
    for (var moduleDep in _localTransitiveDeps(module, assetsToModules)) {
      reverseDeps
          .putIfAbsent(moduleDep, () => <AssetId>{})
          .add(module.primarySource);
    }
  }
  return reverseDeps;
}

/// Merges [modules] into a minimum set of [Module]s using the
/// following rules:
///
///   * If it is an entrypoint module do not merge it.
///   * If it is not depended on my any entrypoint do not merge it.
///   * If it is depended on by no entrypoint merge it into the entrypoint
///   modules
///   * Else merge it into with others that are depended on by the same set of
///   entrypoints
List<Module> _mergeModules(Iterable<Module> modules, Set<AssetId> entrypoints) {
  var entrypointModules =
      modules.where((m) => m.sources.any(entrypoints.contains)).toList();

  // Groups of modules that can be merged into an existing entrypoint module.
  var entrypointModuleGroups = {
    for (var m in entrypointModules) m.primarySource: [m],
  };

  // Maps modules to entrypoint modules that transitively depend on them.
  var modulesToEntryPoints =
      _findReverseEntrypointDeps(entrypointModules, modules);

  // Modules which are not depended on by any entrypoint
  var standaloneModules = <Module>[];

  // Modules which are merged with others.
  var mergedModules = <String, List<Module>>{};

  for (var module in modules) {
    // Skip entrypoint modules.
    if (entrypointModuleGroups.containsKey(module.primarySource)) continue;

    // The entry points that transitively import this module.
    var entrypointIds = modulesToEntryPoints[module.primarySource];

    // If no entrypoint imports the module, just leave it alone.
    if (entrypointIds == null || entrypointIds.isEmpty) {
      standaloneModules.add(module);
      continue;
    }

    // If there are multiple entry points for a given resource we must create
    // a new shared module. Use `$` to signal that it is a shared module.
    if (entrypointIds.length > 1) {
      var mId = (entrypointIds.toList()..sort()).map((m) => m.path).join('\$');
      mergedModules.putIfAbsent(mId, () => []).add(module);
    } else {
      entrypointModuleGroups[entrypointIds.single].add(module);
    }
  }

  return mergedModules.values
      .map(Module.merge)
      .map(_withConsistentPrimarySource)
      .followedBy(entrypointModuleGroups.values.map(Module.merge))
      .followedBy(standaloneModules)
      .toList();
}

Module _withConsistentPrimarySource(Module m) => Module(m.sources.reduce(_min),
    m.sources, m.directDependencies, m.platform, m.isSupported);

T _min<T extends Comparable<T>>(T a, T b) => a.compareTo(b) < 0 ? a : b;

/// Compute modules for the  internal strongly connected components of
/// [libraries].
///
/// This should only be called with [libraries] all in the same package and top
/// level directory within the package.
///
/// A dependency is considered "internal" if it is within [libraries]. Any
/// "external" deps are ignored during this computation since we are only
/// considering the strongly connected components within [libraries], but they
/// will be maintained as a dependency of the module to be used at a later step.
///
/// Part files are also tracked but ignored during computation of strongly
/// connected components, as they must always be a part of the containing
/// library's module.
List<Module> _computeModules(
    Map<AssetId, ModuleLibrary> libraries, DartPlatform platform) {
  assert(() {
    var dir = _topLevelDir(libraries.values.first.id.path);
    return libraries.values.every((l) => _topLevelDir(l.id.path) == dir);
  }());

  final connectedComponents = stronglyConnectedComponents<ModuleLibrary>(
      libraries.values,
      (n) => n
          .depsForPlatform(platform)
          // Only "internal" dependencies
          .where(libraries.containsKey)
          .map((dep) => libraries[dep]),
      equals: (a, b) => a.id == b.id,
      hashCode: (l) => l.id.hashCode);

  final entryIds =
      libraries.values.where((l) => l.isEntryPoint).map((l) => l.id).toSet();
  return _mergeModules(
      connectedComponents.map((c) => _moduleForComponent(c, platform)),
      entryIds);
}

@JsonSerializable()
class MetaModule {
  @JsonKey(name: 'm', nullable: false)
  final List<Module> modules;

  MetaModule(List<Module> modules) : modules = List.unmodifiable(modules);

  /// Generated factory constructor.
  factory MetaModule.fromJson(Map<String, dynamic> json) =>
      _$MetaModuleFromJson(json);

  Map<String, dynamic> toJson() => _$MetaModuleToJson(this);

  static Future<MetaModule> forLibraries(
      AssetReader reader,
      List<AssetId> libraryIds,
      ModuleStrategy strategy,
      DartPlatform platform) async {
    var libraries = <ModuleLibrary>[];
    for (var id in libraryIds) {
      libraries.add(ModuleLibrary.deserialize(
          id.changeExtension('').changeExtension('.dart'),
          await reader.readAsString(id)));
    }
    switch (strategy) {
      case ModuleStrategy.fine:
        return _fineModulesForLibraries(reader, libraries, platform);
      case ModuleStrategy.coarse:
        return _coarseModulesForLibraries(reader, libraries, platform);
    }
    throw StateError('Unrecognized module strategy $strategy');
  }
}

MetaModule _coarseModulesForLibraries(
    AssetReader reader, List<ModuleLibrary> libraries, DartPlatform platform) {
  var librariesByDirectory = <String, Map<AssetId, ModuleLibrary>>{};
  for (var library in libraries) {
    final dir = _topLevelDir(library.id.path);
    if (!librariesByDirectory.containsKey(dir)) {
      librariesByDirectory[dir] = <AssetId, ModuleLibrary>{};
    }
    librariesByDirectory[dir][library.id] = library;
  }
  final modules = librariesByDirectory.values
      .expand((libs) => _computeModules(libs, platform))
      .toList();
  _sortModules(modules);
  return MetaModule(modules);
}

MetaModule _fineModulesForLibraries(
    AssetReader reader, List<ModuleLibrary> libraries, DartPlatform platform) {
  var modules = libraries
      .map((library) => Module(
          library.id,
          library.parts.followedBy([library.id]),
          library.depsForPlatform(platform),
          platform,
          library.sdkDeps.every(platform.supportsLibrary)))
      .toList();
  _sortModules(modules);
  return MetaModule(modules);
}

/// Sorts [modules] in place so we get deterministic output.
void _sortModules(List<Module> modules) {
  modules.sort((a, b) => a.primarySource.compareTo(b.primarySource));
}
