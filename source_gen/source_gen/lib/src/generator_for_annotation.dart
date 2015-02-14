library source_gen.generator_for_annotation;

import 'dart:async';
import 'dart:mirrors';

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

    // now we need to create the instance!
    var classMirror = reflectClass(T);

    // TODO: actually construct the annotation from analyzer arguments
    // var matchingAnnotation = matchingAnnotations.single;
    var annotationInstance =
        classMirror.newInstance(const Symbol(''), []).reflectee as T;

    return generateForAnnotatedElement(element, annotationInstance);
  }

  Future<String> generateForAnnotatedElement(Element element, T annotation);
}
