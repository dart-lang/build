// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/resolver/scope.dart';

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

  /// All of the declarations in this library, including the [LibraryElement] as
  /// the first item.
  Iterable<Element> get allElements sync* {
    yield element;
    for (var cu in element.units) {
      for (var compUnitMember in cu.unit.declarations) {
        yield* _getElements(compUnitMember);
      }
    }
  }

  Iterable<Element> _getElements(CompilationUnitMember member) {
    if (member is TopLevelVariableDeclaration) {
      return member.variables.variables
          .map(resolutionMap.elementDeclaredByVariableDeclaration);
    }
    var element = resolutionMap.elementDeclaredByDeclaration(member);

    if (element == null) {
      print([member, member.runtimeType, member.element]);
      throw new Exception('Could not find any elements for the provided unit.');
    }

    return [element];
  }
}
