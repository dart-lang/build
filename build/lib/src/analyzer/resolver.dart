// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

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
  /// * If the [assetId] has syntax errors, and [allowSyntaxErrors] is set to
  ///   `false` (the default), throws a [SyntaxErrorInAssetException].
  Future<LibraryElement> libraryFor(AssetId assetId,
      {bool allowSyntaxErrors = false});

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

/// Exception thrown by a resolver when attempting to resolve a Dart library
/// with syntax errors.
///
/// Builders are not expected to catch this exception unless they have special
/// behavior for inputs with syntax errors. This exception has a descriptive
/// [toString] implementation that the build system will show to users.
class SyntaxErrorInAssetException implements Exception {
  static const _maxErrorsInToString = 3;

  /// The syntactically invalid [AssetId] that couldn't be resolved.
  final AssetId assetId;

  /// The errors reported by the parser when trying to resolve the [assetId].
  ///
  /// This only contains syntax errors since most semantic errors are expected
  /// during a builder (e.g. due to missing part files that are yet to be
  /// generated).
  final List<AnalysisError> syntaxErrors;

  SyntaxErrorInAssetException(this.assetId, this.syntaxErrors)
      : assert(syntaxErrors.isNotEmpty);

  @override
  String toString() {
    final buffer = StringBuffer()
      ..writeln('This builder requires Dart inputs without syntax errors.')
      ..writeln('However, ${assetId.uri} contains the following errors:');

    // Avoid generating too much output for syntax errors.
    final additionalErrors = syntaxErrors.length - _maxErrorsInToString;
    for (final error in syntaxErrors.take(_maxErrorsInToString)) {
      buffer.writeln(error.toString());
    }

    if (additionalErrors > 0) {
      buffer.writeln('And $additionalErrors more...');
    }

    buffer.writeln('\nTry fixing the errors and re-running the build.');

    return buffer.toString();
  }
}
