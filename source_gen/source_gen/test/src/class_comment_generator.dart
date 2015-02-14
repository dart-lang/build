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
      return '// Code for $element';
    }
    return null;
  }

  String toString() => 'ClassCommentGenerator';
}
