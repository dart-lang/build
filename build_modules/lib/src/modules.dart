// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:graphs/graphs.dart';
import 'package:json_annotation/json_annotation.dart';

import 'errors.dart';
import 'module_builder.dart';
import 'platform.dart';
import 'summary_builder.dart';

part 'modules.g.dart';

/// A collection of Dart libraries in a strongly connected component and the
/// modules they depend on.
///
/// Modules can span pub package boundaries when there are import cycles across
/// packages.
@JsonSerializable()
@_AssetIdConverter()
@_DartPlatformConverter()
class Module {
  /// The JS file for this module.
  AssetId jsId(String jsModuleExtension) =>
      primarySource.changeExtension(jsModuleExtension);

  // The sourcemap for the JS file for this module.
  AssetId jsSourceMapId(String jsSourceMapExtension) =>
      primarySource.changeExtension(jsSourceMapExtension);

  /// The linked summary for this module.
  AssetId get linkedSummaryId =>
      primarySource.changeExtension(linkedSummaryExtension(platform));

  /// The unlinked summary for this module.
  AssetId get unlinkedSummaryId =>
      primarySource.changeExtension(unlinkedSummaryExtension(platform));

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
  @JsonKey(name: 's', nullable: false)
  final Set<AssetId> sources;

  /// The [primarySource]s of the [Module]s which contain any library imported
  /// from any of the [sources] in this module.
  @JsonKey(name: 'd', nullable: false)
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
      : sources = sources.toSet(),
        directDependencies = directDependencies.toSet(),
        isMissing = isMissing ?? false;

  /// Generated factory constructor.
  factory Module.fromJson(Map<String, dynamic> json) => _$ModuleFromJson(json);

  Map<String, dynamic> toJson() => _$ModuleToJson(this);

  /// Returns all [Module]s in the transitive dependencies of this module in
  /// reverse dependency order.
  ///
  /// Throws a [MissingModulesException] if there are any missing modules. This
  /// typically means that somebody is trying to import a non-existing file.
  Future<List<Module>> computeTransitiveDependencies(AssetReader reader) async {
    var transitiveDeps = <AssetId, Module>{};
    var modulesToCrawl = directDependencies.toSet();
    var missingModuleSources = Set<AssetId>();
    while (modulesToCrawl.isNotEmpty) {
      var next = modulesToCrawl.last;
      modulesToCrawl.remove(next);
      if (transitiveDeps.containsKey(next)) continue;
      var nextModuleId = next.changeExtension(moduleExtension(platform));
      if (!await reader.canRead(nextModuleId)) {
        missingModuleSources.add(next);
        continue;
      }
      var module = Module.fromJson(
          json.decode(await reader.readAsString(nextModuleId))
              as Map<String, dynamic>);
      if (module.isMissing) {
        missingModuleSources.add(module.primarySource);
        continue;
      }
      transitiveDeps[next] = module;
      modulesToCrawl.addAll(module.directDependencies);
    }
    if (missingModuleSources.isNotEmpty) {
      throw await MissingModulesException.create(missingModuleSources,
          transitiveDeps.values.toList()..add(this), reader);
    }
    var orderedModules = stronglyConnectedComponents<AssetId, Module>(
        transitiveDeps.values,
        (m) => m.primarySource,
        (m) => m.directDependencies.map((s) => transitiveDeps[s]));
    return orderedModules.map((c) => c.single).toList();
  }

  /// Add all of [other]'s source and dependencies to this module and keep this
  /// module's primary source.
  void merge(Module other) {
    sources.addAll(other.sources);
    directDependencies.addAll(other.directDependencies);
    directDependencies.removeAll(sources);
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
  DartPlatform fromJson(String json) => DartPlatform(json);

  @override
  String toJson(DartPlatform object) => object.name;
}
