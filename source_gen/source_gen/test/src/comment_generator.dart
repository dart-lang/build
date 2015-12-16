library source_gen.test.comment_generator;

import 'dart:async';

import 'package:analyzer/src/generated/element.dart';
import 'package:source_gen/source_gen.dart';

/// Generates a single-line comment for each class
class CommentGenerator extends Generator {
  final bool forClasses, forLibrary;

  const CommentGenerator({this.forClasses: true, this.forLibrary: false});

  @override
  Future<String> generate(Element element) async {
    if (forClasses && element is ClassElement) {
      if (element.displayName.contains('GoodError')) {
        throw new InvalidGenerationSourceError(
            "Don't use classes with the word 'Error' in the name",
            todo: "Rename ${element.displayName} to something else.");
      }

      if (element.displayName.contains('Error')) {
        throw new ArgumentError.value(
            element,
            'element',
            "We don't support class names with the word 'Error'.\n"
            "Try renaming the class.");
      }

      return '// Code for "$element"';
    }

    if (forLibrary && element is LibraryElement) {
      return '// Code for "$element"';
    }
    return null;
  }

  String toString() => 'CommentGenerator';
}
