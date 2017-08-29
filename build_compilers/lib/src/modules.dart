// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

class Module {
  /// The libraries in the strongly connected cycle.
  ///
  /// In most cases without cyclic imports this will contain a single asset.
  final Set<AssetId> cycle;

  /// The libraries which would have a `.sum` or `.js` output necessary to
  /// compile this module.
  ///
  /// Every import from any of the assets in [cycle] will be covered by the
  /// modules rooted within this set.
  final Set<AssetId> dependencies;
  Module(this.cycle, this.dependencies);
}

Module defineModule(AssetId from, LibraryElement library) {
  final cycleUris = library.libraryCycle.map((l) => '${l.source.uri}').toSet();
  final dependencyModules = new Set<String>();
  final seenDependencies = new Set<String>();
  for (var dependency in _cycleDependencies(library)) {
    var uri = '${dependency.source.uri}';
    if (seenDependencies.contains(uri) || cycleUris.contains(uri)) continue;
    var cycle = dependency.libraryCycle;
    dependencyModules.add(_earliest(cycle));
    seenDependencies.addAll(cycle.map((l) => '${l.source.uri}'));
  }

  AssetId toAssetId(String uri) => new AssetId.resolve(uri, from: from);

  return new Module(cycleUris.map(toAssetId).toSet(),
      dependencyModules.map(toAssetId).toSet());
}

/// Returns whether [library] owns the module for it's strongly connected import
/// cycle.
bool isPrimary(LibraryElement library) =>
    _earliest(library.libraryCycle) == '${library.source.uri}';

String _earliest(List<LibraryElement> libraries) {
  if (libraries.length < 2) return '${libraries.first.source.uri}';
  return libraries.map((l) => '${l.source.uri}').reduce(_earlier);
}

T _earlier<T extends Comparable<T>>(T left, T right) =>
    left.compareTo(right) < 0 ? left : right;

/// All the non-SDK [LibraryElement]s which are imported or exported from
/// anywhere in the library cycle containing [library].
///
/// There may be duplicates
Iterable<LibraryElement> _cycleDependencies(LibraryElement library) =>
    library.libraryCycle.expand(_libraryDependencies);

/// All the non-SDK [LibraryElement]s which are imported or exported from
/// [library].
///
/// There may be duplicates.
Iterable<LibraryElement> _libraryDependencies(LibraryElement library) => [
      library.importedLibraries,
      library.exportedLibraries
    ].expand((l) => l).where((l) => !l.isInSdk);
