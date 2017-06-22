// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';

/// A high-level wrapper API with common functionality for [LibraryElement].
class LibraryReader {
  final LibraryElement _element;

  Namespace _namespaceCache;

  LibraryReader(this._element);

  Namespace get _namespace => _namespaceCache ??=
      new NamespaceBuilder().createExportNamespaceForLibrary(_element);

  /// Returns a top-level [ClassElement] publicly visible in by [name].
  ///
  /// Unlike [LibraryElement.getType], this also correctly traverses identifiers
  /// that are accessible via one or more `export` directives.
  ClassElement findType(String name) =>
      _element.getType(name) ?? _namespace.get(name) as ClassElement;
}
