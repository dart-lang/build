// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_gen.generator_for_annotation;

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

import 'annotation.dart';
import 'generator.dart';

/// A generator that invokes [generateForAnnotatedElement] for every [T].
///
/// For example, this will allow code generated based on `@Deprecated`:
/// ```dart
/// class DeprecatedGenerator extends GeneratorForAnnotation<Deprecated> {
///   @override
///   Future<String> generateForAnnotatedElement(
///       Element element,
///       Deprecated annotation,
///       BuildStep buildStep) async {
///     // Return a string representing the code to emit.
///   }
/// }
/// ```
///
/// **NOTE**: This class operates under an assumption that annotation [T] can be
/// created using `dart:mirrors` and based on the visible parameters to the
/// annotation's class, and may not work for all cases.
abstract class GeneratorForAnnotation<T> extends Generator {
  const GeneratorForAnnotation();

  @override
  Future<String> generate(Element element, BuildStep buildStep) {
    var matchingAnnotations =
        element.metadata.where((md) => matchAnnotation(T, md)).toList();

    if (matchingAnnotations.isEmpty) {
      return null;
    }

    if (matchingAnnotations.length > 1) {
      throw new StateError('Cannot have more than one matching annotation');
    }

    var annotationInstance =
        instantiateAnnotation(matchingAnnotations.single) as T;

    assert(annotationInstance != null, 'Could not create an instance of $T');

    return generateForAnnotatedElement(element, annotationInstance, buildStep);
  }

  /// Override to return source code to generate for [element].
  ///
  /// This method is invoked based on finding an instance of [annotation] in the
  /// source code. An [annotation] instance is provided, if it can be determined
  /// how to create the class, otherwise may be `null`.
  Future<String> generateForAnnotatedElement(
      Element element, T annotation, BuildStep buildStep);
}
