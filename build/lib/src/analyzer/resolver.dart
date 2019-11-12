// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:analyzer/dart/element/element.dart';

import '../asset/id.dart';
import '../builder/build_step.dart';

/// Standard interface for resolving Dart source code as part of a build.
abstract class Resolver {
  /// Returns whether [assetId] represents an Dart library file.
  ///
  /// This will be `false` in the case where the file is not Dart source code,
  /// or is a `part of` file (not a standalone Dart library).
  Future<bool> isLibrary(AssetId assetId);

  /// All libraries recursively accessible from the entry point or subsequent
  /// calls to [libraryFor] and [isLibrary].
  ///
  /// **NOTE**: This includes all Dart SDK libraries as well.
  Stream<LibraryElement> get libraries;

  /// Returns a resolved library representing the file defined in [assetId].
  ///
  /// * Throws [NonLibraryAssetException] if [assetId] is not a Dart library.
  Future<LibraryElement> libraryFor(AssetId assetId);

  /// Returns the first resolved library identified by [libraryName].
  ///
  /// A library is resolved if it's recursively accessible from the entry point
  /// or subsequent calls to [libraryFor] and [isLibrary]. If no library can be
  /// found, returns `null`.
  ///
  /// **NOTE**: In general, its recommended to use [libraryFor] with an absolute
  /// asset id instead of a named identifier that has the possibility of not
  /// being unique.
  Future<LibraryElement> findLibraryByName(String libraryName);

  /// Returns the [AssetId] of the Dart library or part declaring [element].
  ///
  /// If [element] is defined in the SDK or in a summary throws
  /// `UnresolvableAssetException`, although a non-throwing return here does not
  /// guarantee that the asset is readable.
  ///
  /// The returned asset is not necessarily the asset that should be imported to
  /// use the element, it may be a part file instead of the library.
  Future<AssetId> assetIdForElement(Element element);
}

/// A resolver that should be manually released at the end of a build step.
abstract class ReleasableResolver implements Resolver {
  /// Release this resolver so it can be updated by following build steps.
  void release();
}

/// A factory that returns a resolver for a given [BuildStep].
abstract class Resolvers {
  const Resolvers();

  Future<ReleasableResolver> get(BuildStep buildStep);

  /// Reset the state of any caches within [Resolver] instances produced by
  /// this [Resolvers].
  ///
  /// In between calls to [reset] no Assets should change, so every call to
  /// `BuildStep.readAsString` for a given AssetId should return identical
  /// contents. Any time an Asset's contents may change [reset] must be called.
  void reset() {}
}

/// Thrown when attempting to read a non-Dart library in a [Resolver].
class NonLibraryAssetException implements Exception {
  final AssetId assetId;

  const NonLibraryAssetException(this.assetId);

  @override
  String toString() => 'Asset [$assetId] is not a Dart library. '
      'It may be a part file or a file without Dart source code.';
}
