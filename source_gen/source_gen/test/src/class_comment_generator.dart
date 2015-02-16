library source_gen.test.class_comment_generator;

import 'dart:async';

import 'package:analyzer/src/generated/element.dart';
import 'package:source_gen/source_gen.dart';

/// Generates a single-line comment for each class
class ClassCommentGenerator extends Generator {
  const ClassCommentGenerator();

  @override
  Future<String> generate(Element element) async {
    if (element is ClassElement) {
      if (element.displayName.contains('GoodError')) {
        throw new InvalidGenerationSourceError(
            "Don't use classes with the word 'Error' in the name",
            todo: "Rename ${element.displayName} to something else.");
      }

      if (element.displayName.contains('Error')) {
        throw new ArgumentError.value(element, 'element',
            "We don't support class names with the word 'Error'.\n" "Try renaming the class.");
      }

      return '// Code for $element';
    }
    return null;
  }

  String toString() => 'ClassCommentGenerator';
}
