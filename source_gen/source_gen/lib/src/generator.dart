// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_gen.generator;

import 'dart:async';

import 'package:analyzer/src/generated/element.dart';

abstract class Generator {
  const Generator();

  /// The files to track when doing incremental generation.
  ///
  /// By default, incremental generation is only done on a library if a source
  /// file in that library is changes. [AssociatedFiles.sameLibrary]
  AssociatedFileSet get associatedFileSet => AssociatedFileSet.sameLibrary;

  Future<String> generate(Element element) => null;

  @override
  String toString() => this.runtimeType.toString();
}

class InvalidGenerationSourceError {
  final String message;
  final String todo;

  InvalidGenerationSourceError(this.message, {String todo})
      : this.todo = todo == null ? '' : todo;

  @override
  String toString() => message;
}

enum AssociatedFileSet {
  /// Only run incremental generation when a source file in the library changes.
  sameLibrary,
  /// Run incremental generation when a source file in the library changes or
  /// if a file in the same directory as a library source file changes.
  sameDirectory
}
