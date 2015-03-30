// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_gen.generator_for_annotation;

import 'dart:async';

import 'package:analyzer/src/generated/element.dart';

import 'annotation.dart';
import 'generator.dart';

abstract class GeneratorForAnnotation<T> extends Generator {
  const GeneratorForAnnotation();

  @override
  Future<String> generate(Element element) {
    var matchingAnnotations =
        element.metadata.where((md) => matchAnnotation(T, md)).toList();

    if (matchingAnnotations.isEmpty) {
      return null;
    } else if (matchingAnnotations.length > 1) {
      throw 'cannot have more than one matching annotation';
    }

    var annotationInstance =
        instantiateAnnotation(matchingAnnotations.single) as T;

    return generateForAnnotatedElement(element, annotationInstance);
  }

  Future<String> generateForAnnotatedElement(Element element, T annotation);
}
