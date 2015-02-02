library source_gen;

import 'dart:mirrors';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/element.dart';
import 'utils.dart';

abstract class Generator<T extends Element> {
  const Generator();

  CompilationUnitMember generate(Element element);
}

abstract class GeneratorForAnnotation<T> extends Generator {
  const GeneratorForAnnotation();

  CompilationUnitMember generate(Element element) {
    var matchingAnnotations =
        element.metadata.where((md) => matchAnnotation(T, md)).toList();

    if (matchingAnnotations.isEmpty) {
      print('no matches!');
      return null;
    } else if (matchingAnnotations.length > 1) {
      print('too many matches!');
      throw 'cannot have more than one matching annotation';
    }

    // now we need to create the instance!
    var classMirror = reflectClass(T);

    // TODO: actually construct the annotation from analyzer arguments
    // var matchingAnnotation = matchingAnnotations.single;
    var annotationInstance =
        classMirror.newInstance(new Symbol(''), []).reflectee as T;

    return generateForAnnotatedElement(element, annotationInstance);
  }

  CompilationUnitMember generateForAnnotatedElement(
      Element element, T annotation);
}

class InvalidGenerationSourceError {
  final String message;

  InvalidGenerationSourceError(this.message);
}
