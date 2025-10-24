// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';

import 'asset_id.dart';
import 'build_step.dart';

/// Standard interface for resolving Dart source code as part of a build.
abstract class Resolver {
  /// Returns whether [assetId] represents a Dart library file.
  ///
  /// This will be `false` in the case where the file is not Dart source code,
  /// or is a `part of` file (not a standalone Dart library).
  Future<bool> isLibrary(AssetId assetId);

  /// All libraries resolved by this resolver.
  ///
  /// This includes the following libraries:
  ///  - The primary input of this resolver (in other words, the
  ///   [BuildStep.inputId] of a build step).
  ///  - Libraries resolved with a direct [libraryFor] call.
  ///  - Every public `dart:` library part of the SDK.
  ///  - All libraries recursively accessible from the mentioned sources, for
  ///    instance because due to imports or exports.
  Stream<LibraryElement> get libraries;

  /// Returns the parsed [AstNode] for [fragment].
  ///
  /// This should always be preferred over using the [AnalysisSession]
  /// directly, because it avoids [InconsistentAnalysisException] issues.
  ///
  /// If [resolve] is `true` then you will get a resolved ast node, otherwise
  /// it will only be a parsed ast node.
  ///
  /// Returns `null` if the ast node can not be found. This can happen if an
  /// element is coming from a summary, or is unavailable for some other
  /// reason.
  Future<AstNode?> astNodeFor(Fragment fragment, {bool resolve = false});

  /// Returns a parsed AST structor representing the file defined in [assetId].
  ///
  /// * If the [assetId] has syntax errors, and [allowSyntaxErrors] is set to
  ///   `false` (the default), throws a [SyntaxErrorInAssetException].
  ///
  /// This is a much cheaper api compared to [libraryFor], because it will only
  /// parse a single file and does not give you a resolved element model.
  Future<CompilationUnit> compilationUnitFor(
    AssetId assetId, {
    bool allowSyntaxErrors = false,
  });

  /// Returns a resolved library representing the file defined in [assetId].
  ///
  /// * Throws [NonLibraryAssetException] if [assetId] is not a Dart library.
  /// * If the [assetId] has syntax errors, and [allowSyntaxErrors] is set to
  ///   `false` (the default), throws a [SyntaxErrorInAssetException].
  Future<LibraryElement> libraryFor(
    AssetId assetId, {
    bool allowSyntaxErrors = false,
  });

  /// Returns the first resolved library identified by [libraryName].
  ///
  /// A library is resolved if it's recursively accessible from the entry point
  /// or subsequent calls to [libraryFor]. In other words, this searches for
  /// libraries in [libraries].
  /// If no library can be found, returns `null`.
  ///
  /// **NOTE**: In general, its recommended to use [libraryFor] with an absolute
  /// asset id instead of a named identifier that has the possibility of not
  /// being unique.
  Future<LibraryElement?> findLibraryByName(String libraryName);

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
  String toString() =>
      'Asset [$assetId] is not a Dart library. '
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

  /// A list analysis error results for files related to the [assetId].
  ///
  /// In addition to the asset itself, the resolver also considers syntax errors
  /// in part files.
  final List<AnalysisResultWithDiagnostics> filesWithErrors;

  SyntaxErrorInAssetException(this.assetId, this.filesWithErrors)
    : assert(filesWithErrors.isNotEmpty);

  /// The errors reported by the parser when trying to resolve the [assetId].
  ///
  /// This only contains syntax errors since most semantic errors are expected
  /// during a build (e.g. due to missing part files that haven't been generated
  /// yet).
  Iterable<Diagnostic> get syntaxErrors {
    return filesWithErrors
        .expand((result) => result.diagnostics)
        .where(_isSyntaxError);
  }

  /// A map from [syntaxErrors] to per-file results
  Map<Diagnostic, AnalysisResultWithDiagnostics> get errorToResult {
    return {
      for (final file in filesWithErrors)
        for (final error in file.diagnostics)
          if (_isSyntaxError(error)) error: file,
    };
  }

  bool _isSyntaxError(Diagnostic diagnostic) {
    return diagnostic.diagnosticCode.type == DiagnosticType.SYNTACTIC_ERROR;
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    // Avoid generating too much output for syntax errors. The user likely has
    // an editor that shows them anyway.
    final entries = errorToResult.entries.toList();
    var first = true;
    for (final errorAndResult in entries.take(_maxErrorsInToString)) {
      if (!first) {
        buffer.write('\n');
      }
      first = false;
      final error = errorAndResult.key;

      final lineInfo = errorAndResult.value.lineInfo;
      final position = lineInfo.getLocation(error.offset);

      // The file name will be added by `BuildLog`, so write just the line
      // number and column, for example: "3:4: Expected a semicolon here."
      buffer.write(
        '${position.lineNumber}:${position.columnNumber}: '
        '${error.message}',
      );
    }

    final additionalErrors = entries.length - _maxErrorsInToString;
    if (additionalErrors > 0) {
      buffer.write('\nAnd $additionalErrors more.');
    }

    return buffer.toString();
  }
}
