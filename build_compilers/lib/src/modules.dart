// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

/// A collection of Dart libraries in a strongly connected component and the
/// modules they depend on.
///
/// Modules can span pub package boundaries when there are import cycles across
/// packages.
class Module {
  /// The library which will be used to reference any library in [sources].
  ///
  /// The assets which are built once per module, such as DDC compiled output or
  /// Analyzer summaries, will be build for the primary source and not for any
  /// other asset in [sources].
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
  final Set<AssetId> sources;

  /// The [primarySource]s of the [Module]s which contain any library imported
  /// from any of the [sources] in this module.
  final Set<AssetId> directDependencies;

  Module(this.primarySource, this.sources, this.directDependencies);
}

Module defineModule(AssetId from, LibraryElement library) {
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

  AssetId toAssetId(Uri uri) => new AssetId.resolve('${uri}', from: from);

  return new Module(
      toAssetId(_earliest(cycle)),
      cycleUris.map(toAssetId).toSet(),
      dependencyModules.map(toAssetId).toSet());
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
    ].expand((l) => l).where((l) => !l.isInSdk);
