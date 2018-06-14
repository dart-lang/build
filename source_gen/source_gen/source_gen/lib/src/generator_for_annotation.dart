// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

import 'constants/reader.dart';
import 'generator.dart';
import 'library.dart';
import 'output_helpers.dart';
import 'type_checker.dart';

/// A [Generator] that invokes [generateForAnnotatedElement] for every [T].
///
/// For example, this will allow code generated for all elements which are
/// annotated with `@Deprecated`:
///
/// ```dart
/// class DeprecatedGenerator extends GeneratorForAnnotation<Deprecated> {
///   @override
///   Future<String> generateForAnnotatedElement(
///       Element element,
///       ConstantReader annotation,
///       BuildStep buildStep) async {
///     // Return a string representing the code to emit.
///   }
/// }
/// ```
abstract class GeneratorForAnnotation<T> extends Generator {
  const GeneratorForAnnotation();

  TypeChecker get typeChecker => new TypeChecker.fromRuntime(T);

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    var values =
        await new Stream.fromIterable(library.annotatedWith(typeChecker))
            .asyncExpand((e) {
      return normalizeGeneratorOutput(() =>
          generateForAnnotatedElement(e.element, e.annotation, buildStep));
    }).fold(new Set<String>(), (Set<String> uniqueValues, value) {
      value = value?.trim();

      if (value != null && value.isNotEmpty) {
        uniqueValues.add(value);
      }
      return uniqueValues;
    });

    return values.join('\n\n');
  }

  /// Override to return source code to generate for [element].
  ///
  /// This method is invoked based on finding elements annotated with an
  /// instance of [T]. The [annotation] is provided as a [ConstantReader].
  ///
  /// Supported return values include a single [String] or multiple [String]
  /// instances within an [Iterable] or [Stream].
  ///
  /// It is also valid to return a [Future] of any of the above.
  ///
  /// Implementations should return `null` when no content is generated.
  ///
  /// Empty or whitespace-only [String] instances are also ignored.
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep);
}
