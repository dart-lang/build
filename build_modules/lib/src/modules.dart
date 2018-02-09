// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:json_annotation/json_annotation.dart';

import 'kernel_builder.dart';
import 'module_builder.dart';
import 'summary_builder.dart';

part 'modules.g.dart';

/// A collection of Dart libraries in a strongly connected component and the
/// modules they depend on.
///
/// Modules can span pub package boundaries when there are import cycles across
/// packages.
@JsonSerializable()
class Module extends Object with _$ModuleSerializerMixin {
  /// The JS file for this module.
  AssetId jsId(String jsModuleExtension) =>
      primarySource.changeExtension(jsModuleExtension);

  // The sourcemap for the JS file for this module.
  AssetId jsSourceMapId(String jsSourceMapExtension) =>
      primarySource.changeExtension(jsSourceMapExtension);

  // The kernel summary for this module.
  AssetId get kernelSummaryId =>
      primarySource.changeExtension(kernelSummaryExtension);

  /// The linked summary for this module.
  AssetId get linkedSummaryId =>
      primarySource.changeExtension(linkedSummaryExtension);

  /// The unlinked summary for this module.
  AssetId get unlinkedSummaryId =>
      primarySource.changeExtension(unlinkedSummaryExtension);

  /// The library which will be used to reference any library in [sources].
  ///
  /// The assets which are built once per module, such as DDC compiled output or
  /// Analyzer summaries, will be named after the primary source and will
  /// encompass everything in [sources].
  @override
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
  @override
  @JsonKey(name: 's', nullable: false)
  final Set<AssetId> sources;

  /// The [primarySource]s of the [Module]s which contain any library imported
  /// from any of the [sources] in this module.
  @override
  @JsonKey(name: 'd', nullable: false)
  final Set<AssetId> directDependencies;

  Module(this.primarySource, Iterable<AssetId> sources,
      Iterable<AssetId> directDependencies)
      : this.sources = sources.toSet(),
        this.directDependencies = directDependencies.toSet();

  /// Find the module definition which contains [library].
  factory Module.forLibrary(LibraryElement library) {
    final cycle = library.libraryCycle;
    final cycleUris = cycle.map((l) => l.source.uri).toSet();
    final dependencyModules = new Set<Uri>();
    final seenDependencies = new Set<Uri>();
    for (var dependency in _cycleDependencies(cycle)) {
      var uri = dependency.source.uri;
      if (seenDependencies.contains(uri) || cycleUris.contains(uri)) continue;
      var cycle = dependency.libraryCycle;
      dependencyModules.add(_earliest(cycle));
      seenDependencies.addAll(cycle.map((l) => l.source.uri));
    }

    AssetId toAssetId(Uri uri) => new AssetId.resolve('$uri');

    return new Module(
        toAssetId(_earliest(cycle)),
        _cycleSources(cycle).map(toAssetId).toSet(),
        dependencyModules.map(toAssetId).toSet());
  }

  /// Generated factory constructor.
  factory Module.fromJson(Map<String, dynamic> json) => _$ModuleFromJson(json);

  /// Computes the [primarySource]s of all [Module]s that are transitively
  /// depended on by this module.
  Future<List<Module>> computeTransitiveDependencies(AssetReader reader) async {
    var transitiveDeps = <AssetId, Module>{};
    var modulesToCrawl = directDependencies.toSet();
    while (modulesToCrawl.isNotEmpty) {
      var next = modulesToCrawl.last;
      modulesToCrawl.remove(next);
      if (transitiveDeps.containsKey(next)) continue;
      var nextModuleId = next.changeExtension(moduleExtension);
      if (!await reader.canRead(nextModuleId)) {
        log.warning('Missing module $nextModuleId');
        continue;
      }
      var module = new Module.fromJson(
          JSON.decode(await reader.readAsString(nextModuleId))
              as Map<String, dynamic>);
      transitiveDeps[next] = module;
      modulesToCrawl.addAll(module.directDependencies);
    }
    return transitiveDeps.values.toList();
  }
}

/// Returns whether [library] owns the module for it's strongly connected import
/// cycle.
bool isPrimary(LibraryElement library) =>
    _earliest(library.libraryCycle) == library.source.uri;

Uri _earliest(Iterable<LibraryElement> libraries) {
  assert(libraries.isNotEmpty, 'Library cycle should not be empty');
  if (libraries.length == 1) return libraries.single.source.uri;
  return libraries.map((l) => l.source.uri).reduce(_earlier);
}

Uri _earlier(Uri left, Uri right) =>
    left.path.compareTo(right.path) < 0 ? left : right;

/// All the non-SDK [LibraryElement]s which are imported or exported from
/// any of [libraries].
///
/// There may be duplicates
Iterable<LibraryElement> _cycleDependencies(
        Iterable<LibraryElement> libraries) =>
    libraries.expand(_libraryDependencies);

/// All the non-SDK [LibraryElement]s which are imported or exported from
/// [library].
///
/// There may be duplicates.
Iterable<LibraryElement> _libraryDependencies(LibraryElement library) => [
      library.importedLibraries,
      library.exportedLibraries
    ].expand((l) => l).where((l) => !l.source.isInSystemLibrary);

/// All sources for a library cycle, including part files.
Iterable<Uri> _cycleSources(Iterable<LibraryElement> libraries) =>
    libraries.expand(_libraryUris);

/// All sources for a library, including part files.
Iterable<Uri> _libraryUris(LibraryElement library) =>
    library.parts.map((u) => u.source.uri).toList()..add(library.source.uri);
