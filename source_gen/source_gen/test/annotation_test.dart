library source_gen.test.annotation_test;

import 'package:analyzer/src/generated/element.dart';
import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';

import 'package:source_gen/json_serial/json_annotation.dart';
import 'package:source_gen/src/utils.dart';

import 'test_files/annotations.dart' as defs;

import 'test_utils.dart';

void main() {
  group('match annotations', () {
    LibraryElement libElement;

    setUp(() {
      if (libElement == null) {
        libElement = _getTestLibElement();
      }
    });

    test('annotated with class', () {
      var annotatedClass = _getAnnotationForClass(libElement, 'CtorNoParams');
      var annotation = annotatedClass.metadata.single;
      var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
      expect(matched, isTrue);
    });

    test('annotated with class in a part', () {
      ClassElement annotatedClass =
          _getAnnotationForClass(libElement, 'CtorNoParamsInPart');
      var annotation = annotatedClass.metadata.single;
      var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
      expect(matched, isTrue);
    });

    test('class in a part annotated with class', () {
      var annotatedClass = _getAnnotationForClass(libElement, 'CtorNoParams');
      var annotation = annotatedClass.metadata.single;
      var matched =
          matchAnnotation(defs.PublicAnnotationClassInPart, annotation);
      expect(matched, isFalse, reason: 'not annotated with that type');
    });

    test('class in a part annotated with class in a part', () {
      ClassElement annotatedClass =
          _getAnnotationForClass(libElement, 'CtorNoParamsInPart');
      var annotation = annotatedClass.metadata.single;
      var matched =
          matchAnnotation(defs.PublicAnnotationClassInPart, annotation);
      expect(matched, isFalse);
    });

    test('class annotated with type defined via package uri', () {
      ClassElement annotatedClass =
          _getAnnotationForClass(libElement, 'AnnotatedWithJson');
      var annotation = annotatedClass.metadata.single;
      var matched = matchAnnotation(JsonSerializable, annotation);
      expect(matched, isTrue);
    });
  });
}

LibraryElement _getTestLibElement() {
  var annotatedClassesFilePath =
      p.join(getPackagePath(), 'test/test_files/annotated_classes.dart');
  return getLibraryElementFromCompilationUnit(
      getPackagePath(), annotatedClassesFilePath);
}

ClassElement _getAnnotationForClass(LibraryElement lib, String className) =>
    lib.units
        .expand((cu) => cu.types)
        .singleWhere((cd) => cd.name == className);
