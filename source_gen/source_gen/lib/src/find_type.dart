// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';

final _namespaceCache = new Expando<Namespace>();

/// Returns a top-level [ClassElement] publicly visible in [library] by [name].
///
/// Unlike [LibraryElement.getType], this also correctly traverses identifiers
/// that are accessible via one or more `export` directives.
ClassElement findType(LibraryElement library, String name) =>
    library.getType(name) ??
    (_namespaceCache[library] ??=
            new NamespaceBuilder().createExportNamespaceForLibrary(library))
        .get(name) as ClassElement;
