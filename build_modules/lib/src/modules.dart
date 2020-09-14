// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:build/build.dart';
import 'package:collection/collection.dart' show UnmodifiableSetView;
import 'package:graphs/graphs.dart';
import 'package:json_annotation/json_annotation.dart';

import 'errors.dart';
import 'module_builder.dart';
import 'module_cache.dart';
import 'platform.dart';

part 'modules.g.dart';

/// A collection of Dart libraries in a strongly connected component of the
/// import graph.
///
/// Modules track their sources and the other modules they depend on.
/// modules they depend on.
/// Modules can span pub package boundaries when there are import cycles across
/// packages.
@JsonSerializable()
@_AssetIdConverter()
@_DartPlatformConverter()
class Module {
  /// Merge the sources and dependencies from [modules] into a single module.
  ///
  /// All modules must have the same [platform].
  /// [primarySource] will be the earliest value from the combined [sources] if
  /// they were sorted.
  /// [isMissing] will be true if any input module is missing.
  /// [isSupported] will be true if all input modules are supported.
  /// [directDependencies] will be merged for all modules, but if any module
  /// depended on a source from any other they will be filtered out.
  static Module merge(List<Module> modules) {
    assert(modules.isNotEmpty);
    if (modules.length == 1) return modules.single;
    assert(modules.every((m) => m.platform == modules.first.platform));

    final allSources = HashSet.of(modules.expand((m) => m.sources));
    final allDependencies =
        HashSet.of(modules.expand((m) => m.directDependencies))
          ..removeAll(allSources);
    final primarySource =
        allSources.reduce((a, b) => a.compareTo(b) < 0 ? a : b);
    final isMissing = modules.any((m) => m.isMissing);
    final isSupported = modules.every((m) => m.isSupported);
    return Module(primarySource, allSources, allDependencies,
        modules.first.platform, isSupported,
        isMissing: isMissing);
  }

  /// The library which will be used to reference any library in [sources].
  ///
  /// The assets which are built once per module, such as DDC compiled output or
  /// Analyzer summaries, will be named after the primary source and will
  /// encompass everything in [sources].
  @JsonKey(name: 'p', nullable: false)
  final AssetId primarySource;

  /// The libraries in the strongly connected import cycle with [primarySource].
  ///
  /// In most cases without cyclic imports this will contain only the primary
  /// source. For libraries with an import cycle all of the libraries in the
  /// cycle will be contained in `sources`. For example:
  ///
  /// ```dart
  /// library foo;
  ///
  /// import 'bar.dart';
  /// ```
  ///
  /// ```dart
  /// library bar;
  ///
  /// import 'foo.dart';
  /// ```
  ///
  /// Libraries `foo` and `bar` form an import cycle so they would be grouped in
  /// the same module. Every Dart library will only be contained in a single
  /// [Module].
  @JsonKey(name: 's', nullable: false, toJson: _toJsonAssetIds)
  final Set<AssetId> sources;

  /// The [primarySource]s of the [Module]s which contain any library imported
  /// from any of the [sources] in this module.
  @JsonKey(name: 'd', nullable: false, toJson: _toJsonAssetIds)
  final Set<AssetId> directDependencies;

  /// Missing modules are created if a module depends on another non-existent
  /// module.
  ///
  /// We want to report these errors lazily to allow for builds to succeed if it
  /// won't actually impact any apps negatively.
  @JsonKey(name: 'm', nullable: true, defaultValue: false)
  final bool isMissing;

  /// Whether or not this module is supported for [platform].
  ///
  /// Note that this only indicates support for the [sources] within this
  /// module, and not its transitive (or direct) dependencies.
  ///
  /// Compilers can use this to either silently skip compilation of this module
  /// or throw early errors or warnings.
  ///
  /// Modules are allowed to exist even if they aren't supported, which can help
  /// with discovering root causes of incompatibility.
  @JsonKey(name: 'is', nullable: false)
  final bool isSupported;

  @JsonKey(name: 'pf', nullable: false)
  final DartPlatform platform;

  Module(this.primarySource, Iterable<AssetId> sources,
      Iterable<AssetId> directDependencies, this.platform, this.isSupported,
      {bool isMissing})
      : sources = UnmodifiableSetView(HashSet.of(sources)),
        directDependencies =
            UnmodifiableSetView(HashSet.of(directDependencies)),
        isMissing = isMissing ?? false;

  /// Generated factory constructor.
  factory Module.fromJson(Map<String, dynamic> json) => _$ModuleFromJson(json);

  Map<String, dynamic> toJson() => _$ModuleToJson(this);

  /// Returns all [Module]s in the transitive dependencies of this module in
  /// reverse dependency order.
  ///
  /// Throws a [MissingModulesException] if there are any missing modules. This
  /// typically means that somebody is trying to import a non-existing file.
  ///
  /// If [throwIfUnsupported] is `true`, then an [UnsupportedModules]
  /// will be thrown if there are any modules that are not supported.
  Future<List<Module>> computeTransitiveDependencies(BuildStep buildStep,
      {bool throwIfUnsupported = false,
      @deprecated Set<String> skipPlatformCheckPackages = const {}}) async {
    throwIfUnsupported ??= false;
    skipPlatformCheckPackages ??= const {};
    final modules = await buildStep.fetchResource(moduleCache);
    var transitiveDeps = <AssetId, Module>{};
    var modulesToCrawl = {primarySource};
    var missingModuleSources = <AssetId>{};
    var unsupportedModules = <Module>{};

    while (modulesToCrawl.isNotEmpty) {
      var next = modulesToCrawl.last;
      modulesToCrawl.remove(next);
      if (transitiveDeps.containsKey(next)) continue;
      var nextModuleId = next.changeExtension(moduleExtension(platform));
      var module = await modules.find(nextModuleId, buildStep);
      if (module == null || module.isMissing) {
        missingModuleSources.add(next);
        continue;
      }
      if (throwIfUnsupported &&
          !module.isSupported &&
          !skipPlatformCheckPackages.contains(module.primarySource.package)) {
        unsupportedModules.add(module);
      }
      // Don't include the root module in the transitive deps.
      if (next != primarySource) transitiveDeps[next] = module;
      modulesToCrawl.addAll(module.directDependencies);
    }

    if (missingModuleSources.isNotEmpty) {
      throw await MissingModulesException.create(missingModuleSources,
          transitiveDeps.values.toList()..add(this), buildStep);
    }
    if (throwIfUnsupported && unsupportedModules.isNotEmpty) {
      throw UnsupportedModules(unsupportedModules);
    }
    var orderedModules = stronglyConnectedComponents<Module>(
        transitiveDeps.values,
        (m) => m.directDependencies.map((s) => transitiveDeps[s]),
        equals: (a, b) => a.primarySource == b.primarySource,
        hashCode: (m) => m.primarySource.hashCode);
    return orderedModules.map((c) => c.single).toList();
  }
}

class _AssetIdConverter implements JsonConverter<AssetId, List> {
  const _AssetIdConverter();

  @override
  AssetId fromJson(List json) => AssetId.deserialize(json);

  @override
  List toJson(AssetId object) => object.serialize() as List;
}

class _DartPlatformConverter implements JsonConverter<DartPlatform, String> {
  const _DartPlatformConverter();

  @override
  DartPlatform fromJson(String json) => DartPlatform.byName(json);

  @override
  String toJson(DartPlatform object) => object.name;
}

/// Ensure sets of asset IDs are sorted before writing them for a consistent
/// output.
List<List> _toJsonAssetIds(Set<AssetId> ids) =>
    (ids.toList()..sort()).map((i) => i.serialize() as List).toList();
