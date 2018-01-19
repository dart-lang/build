// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import 'constants/reader.dart';
import 'type_checker.dart';
import 'utils.dart';

/// Result of finding an [annotation] on [element] through [LibraryReader].
class AnnotatedElement {
  final ConstantReader annotation;
  final Element element;

  const AnnotatedElement(this.annotation, this.element);
}

/// A high-level wrapper API with common functionality for [LibraryElement].
class LibraryReader {
  final LibraryElement element;

  Namespace _namespaceCache;

  LibraryReader(this.element);

  Namespace get _namespace => _namespaceCache ??=
      new NamespaceBuilder().createExportNamespaceForLibrary(element);

  /// Returns a top-level [ClassElement] publicly visible in by [name].
  ///
  /// Unlike [LibraryElement.getType], this also correctly traverses identifiers
  /// that are accessible via one or more `export` directives.
  ClassElement findType(String name) =>
      element.getType(name) ?? _namespace.get(name) as ClassElement;

  /// All of the declarations in this library.
  Iterable<Element> get allElements sync* {
    for (var cu in element.units) {
      for (var compUnitMember in cu.unit.declarations) {
        yield* _getElements(compUnitMember);
      }
    }
  }

  /// All of the declarations in this library annotated with [checker].
  Iterable<AnnotatedElement> annotatedWith(TypeChecker checker,
      {bool throwOnUnresolved}) sync* {
    for (final element in allElements) {
      final annotation = checker.firstAnnotationOf(element,
          throwOnUnresolved: throwOnUnresolved);
      if (annotation != null) {
        yield new AnnotatedElement(new ConstantReader(annotation), element);
      }
    }
  }

  /// All of the declarations in this library annotated with exactly [checker].
  Iterable<AnnotatedElement> annotatedWithExact(TypeChecker checker,
      {bool throwOnUnresolved}) sync* {
    for (final element in allElements) {
      final annotation = checker.firstAnnotationOfExact(element,
          throwOnUnresolved: throwOnUnresolved);
      if (annotation != null) {
        yield new AnnotatedElement(new ConstantReader(annotation), element);
      }
    }
  }

  /// Returns a [Uri] from the current library to the target [asset].
  ///
  /// This is a typed convenience function for using [pathToUrl], and the same
  /// API restrictions hold around supported schemes and relative paths.
  Uri pathToAsset(AssetId asset) => pathToUrl(asset.uri);

  /// Returns a [Uri] from the current library to the target [element].
  ///
  /// This is a typed convenience function for using [pathToUrl], and the same
  /// API restrictions hold around supported schemes and relative paths.
  Uri pathToElement(Element element) => pathToUrl(element.source.uri);

  /// Returns a [Uri] from the current library to the one provided.
  ///
  /// If possible, a `package:` or `dart:` URL scheme will be used to reference
  /// the library, falling back to relative paths if required (such as in the
  /// `test` directory).
  ///
  /// The support [Uri.scheme]s are (others throw [ArgumentError]):
  /// * `dart`
  /// * `package`
  /// * `asset`
  ///
  /// May throw [ArgumentError] if it is not possible to resolve a path.
  Uri pathToUrl(dynamic toUrlOrString) {
    if (toUrlOrString == null) {
      throw new ArgumentError.notNull('toUrlOrString');
    }
    final to = toUrlOrString is Uri
        ? toUrlOrString
        : Uri.parse(toUrlOrString as String);
    if (to.scheme == 'dart') {
      // Convert dart:core/map.dart to dart:core.
      return normalizeDartUrl(to);
    }
    if (to.scheme == 'package') {
      // Identity (no-op).
      return to;
    }
    if (to.scheme == 'asset') {
      // This is the same thing as a package: URL.
      //
      // i.e.
      //   asset:foo/lib/foo.dart ===
      //   package:foo/foo.dart
      if (to.pathSegments.length > 1 && to.pathSegments[1] == 'lib') {
        return assetToPackageUrl(to);
      }
      var from = element.source.uri;
      if (from == null) {
        throw new StateError('Current library has no source URL');
      }
      // Normalize (convert to an asset: URL).
      from = normalizeUrl(from);
      if (_isRelative(from, to)) {
        if (from == to) {
          // Edge-case: p.relative('a.dart', 'a.dart') == '.', but that is not
          // a valid import URL in Dart source code.
          return new Uri(path: to.pathSegments.last);
        }
        final relative = Uri.parse(p.relative(
          to.toString(),
          from: from.toString(),
        ));
        // We now have a URL like "../b.dart", but we just want "b.dart".
        return relative.replace(
          pathSegments: relative.pathSegments.skip(1),
        );
      }
      throw new ArgumentError.value(to, 'to', 'Not relative to $from');
    }
    throw new ArgumentError.value(to, 'to', 'Cannot use scheme "${to.scheme}"');
  }

  /// Returns whether both [from] and [to] are in the same package and folder.
  ///
  /// For example these are considered relative:
  /// * `asset:foo/test/foo.dart` and `asset:foo/test/bar.dart`.
  ///
  /// But these are not:
  /// * `asset:foo/test/foo.dart` and `asset:foo/bin/bar.dart`.
  /// * `asset:foo/test/foo.dart` and `asset:bar/test/foo.dart`.
  static bool _isRelative(Uri from, Uri to) {
    final fromSegments = from.pathSegments;
    final toSegments = to.pathSegments;
    return fromSegments.length >= 2 &&
        toSegments.length >= 2 &&
        fromSegments[0] == toSegments[0] &&
        fromSegments[1] == toSegments[1];
  }

  /// All of the `class` elements in this library.
  Iterable<ClassElement> get classElements =>
      element.definingCompilationUnit.types;

  static Iterable<Element> _getElements(CompilationUnitMember member) {
    if (member is TopLevelVariableDeclaration) {
      return member.variables.variables
          .map(resolutionMap.elementDeclaredByVariableDeclaration);
    }
    var element = resolutionMap.elementDeclaredByDeclaration(member);
    if (element == null) {
      throw new StateError(
          'Could not find any elements for the provided unit.');
    }
    return [element];
  }

  /// Returns the identifier prefix of [element] if it is referenced by one.
  ///
  /// For example in the following file:
  /// ```
  /// import 'bar.dart' as bar;
  ///
  /// bar.Bar b;
  /// ```
  ///
  /// ... we'd assume that `b`'s type has a prefix of `bar`.
  ///
  /// If there is no prefix, one could not be computed, `null` is returned.
  ///
  /// If there is an attempt to read a prefix of a file _other_ than the current
  /// library being read this will throw [StateError], as it is not always
  /// possible to read details of the source file from other inputs.
  String _prefixForType(Element element) {
    final astNode = element.computeNode();
    if (astNode is VariableDeclaration) {
      final parentNode = astNode.parent as VariableDeclarationList;
      return _prefixForTypeAnnotation(parentNode.type);
    }
    return null;
  }

  static String _prefixForTypeAnnotation(TypeAnnotation astNode) {
    if (astNode is NamedType) {
      return _prefixForIdentifier(astNode.name);
    }
    return null;
  }

  static String _prefixForIdentifier(Identifier id) {
    return id is PrefixedIdentifier ? id.prefix.name : null;
  }
}

// Testing-only access to LibraryReader._prefixFor.
//
// This is used to iterate on the tests without launching the feature.
// Additionally it looks ike `computeNode()` will be deprecated, so we might
// have to rewrite the entire body of the function in the near future; at least
// the tests can help for correctness.
String testingPrefixForType(LibraryReader r, Element e) => r._prefixForType(e);
