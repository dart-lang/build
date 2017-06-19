// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_gen.generator;

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

/// A simple API surface for emitting Dart source code from existing code.
///
/// Clients should _extend_ this class and _override_ [generate]:
/// ```dart
/// class MyGenerator extends Generator {
///   Future<String> generate(Element element, BuildStep buildStep) async {
///     // Return a string representing the code to emit.
///   }
/// }
/// ```
abstract class Generator {
  const Generator();

  /// Override to return source code for a given [element].
  ///
  /// May return `null` to signify "nothing to generate".
  Future<String> generate(Element element, BuildStep buildStep) => null;

  @override
  String toString() => this.runtimeType.toString();
}

/// May be thrown by generators during [Generator.generate].
class InvalidGenerationSourceError extends Error {
  /// What failure occurred.
  final String message;

  /// What could have been changed in the source code to resolve this error.
  ///
  /// May be an empty string if unknown.
  final String todo;

  InvalidGenerationSourceError(this.message, {String todo})
      : this.todo = todo == null ? '' : todo;

  @override
  String toString() => message;
}
