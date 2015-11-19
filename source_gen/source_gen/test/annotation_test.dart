// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('!browser')
library source_gen.test.annotation_test;

import 'dart:async';

import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:source_gen/generators/json_serializable.dart';
import 'package:source_gen/src/annotation.dart';
import 'package:source_gen/src/io.dart';
import 'package:source_gen/src/utils.dart';

import 'test_files/annotations.dart' as defs;

import 'test_utils.dart';

void main() {
  LibraryElement libElement;

  setUp(() async {
    if (libElement == null) {
      libElement = await _getTestLibElement();
    }
  });

  group('create', () {
    group('with field annotations', () {
      test('annotated with typed field', () {
        var annotatedClass =
            _getAnnotationForClass(libElement, 'WithTypedField');
        var annotation = annotatedClass.metadata.single;
        var instance = instantiateAnnotation(annotation);
        expect(instance is defs.PublicAnnotationClass, isTrue);
        expect(instance.anInt, 0);
      });

      test('annotated with untyped field', () {
        var annotatedClass =
            _getAnnotationForClass(libElement, 'WithUntypedField');
        var annotation = annotatedClass.metadata.single;
        var instance = instantiateAnnotation(annotation);
        expect(instance is defs.PublicAnnotationClass, isTrue);
        expect(instance.anInt, 0);
      });

      test('annotated with local typed field', () {
        var annotatedClass =
            _getAnnotationForClass(libElement, 'WithLocalTypedField');
        var annotation = annotatedClass.metadata.single;
        var instance = instantiateAnnotation(annotation);
        expect(instance is defs.PublicAnnotationClass, isTrue);
        expect(instance.anInt, 0);
      });

      test('annotated with local untyped field', () {
        var annotatedClass =
            _getAnnotationForClass(libElement, 'WithLocalUntypedField');
        var annotation = annotatedClass.metadata.single;
        var instance = instantiateAnnotation(annotation);
        expect(instance is defs.PublicAnnotationClass, isTrue);
        expect(instance.anInt, 0);
      });
    });

    test('annotated with class', () {
      var annotatedClass = _getAnnotationForClass(libElement, 'CtorNoParams');
      var annotation = annotatedClass.metadata.single;
      var instance = instantiateAnnotation(annotation);
      expect(instance is defs.PublicAnnotationClass, isTrue);
      expect(instance.anInt, 0);
      expect(instance.aBool, isFalse);
    });

    test('annotated with class using a non-default ctor', () {
      var annotatedClass =
          _getAnnotationForClass(libElement, 'NonDefaultCtorNoParams');
      var annotation = annotatedClass.metadata.single;
      var instance = instantiateAnnotation(annotation);
      expect(instance is defs.PublicAnnotationClass, isTrue);
      expect(instance.anInt, 1);
      expect(instance.aBool, isFalse);
    });

    test('using a non-default ctor with potional args', () {
      var annotatedClass = _getAnnotationForClass(
          libElement, 'NonDefaultCtorWithPositionalParams');
      var annotation = annotatedClass.metadata.single;
      var instance =
          instantiateAnnotation(annotation) as defs.PublicAnnotationClass;
      expect(instance.anInt, 42);
      expect(instance.aString, 'custom value');
      expect(instance.aBool, isFalse);
      expect(instance.aList, [2, 3, 4]);
    });

    test('using a non-default ctor with potional and named args', () {
      var annotatedClass = _getAnnotationForClass(
          libElement, 'NonDefaultCtorWithPositionalAndNamedParams');
      var annotation = annotatedClass.metadata.single;
      var instance =
          instantiateAnnotation(annotation) as defs.PublicAnnotationClass;
      expect(instance.anInt, 43);
      expect(instance.aString, 'another value');
      expect(instance.aBool, isTrue);
      expect(instance.aList, [5, 6, 7]);
      expect(instance.child1, isNull);
      expect(instance.child2, isNull);
    });

    test('with nested objects', () {
      var annotatedClass =
          _getAnnotationForClass(libElement, 'WithNestedObjects');
      var annotation = annotatedClass.metadata.single;
      var instance =
          instantiateAnnotation(annotation) as defs.PublicAnnotationClass;
      expect(instance.child1, const defs.PublicAnnotationClass());
      expect(
          instance.child2, const defs.PublicAnnotationClass.withAnIntAsOne());
    });

    test('with built-in Symbol', () {
      var annotatedClass = _getAnnotationForClass(libElement, 'WithSymbol');
      var annotation = annotatedClass.metadata.single;
      var instance = instantiateAnnotation(annotation);
      expect(instance, defs.objectAnnotation);
    });

    test('with a field using non-default ctor', () {
      var annotatedClass =
          _getAnnotationForClass(libElement, 'WithAFieldFromNonDefaultCtor');
      var annotation = annotatedClass.metadata.single;
      var instance =
          instantiateAnnotation(annotation) as defs.PublicAnnotationClass;
      expect(instance.anInt, defs.untypedAnnotationWithNonDefaultCtor.anInt);
      expect(
          instance.aString, defs.untypedAnnotationWithNonDefaultCtor.aString);
      expect(instance.aBool, defs.untypedAnnotationWithNonDefaultCtor.aBool);
    });
  });

  group('matchAnnotation', () {
    group('with field annotations', () {
      test('annotated with typed field', () {
        var annotatedClass =
            _getAnnotationForClass(libElement, 'WithTypedField');
        var annotation = annotatedClass.metadata.single;
        var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
        expect(matched, isTrue);
      });

      test('annotated with untyped field', () {
        var annotatedClass =
            _getAnnotationForClass(libElement, 'WithUntypedField');
        var annotation = annotatedClass.metadata.single;
        var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
        expect(matched, isTrue);
      });

      test('annotated with local typed field', () {
        var annotatedClass =
            _getAnnotationForClass(libElement, 'WithLocalTypedField');
        var annotation = annotatedClass.metadata.single;
        var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
        expect(matched, isTrue);
      });

      test('annotated with local untyped field', () {
        var annotatedClass =
            _getAnnotationForClass(libElement, 'WithLocalUntypedField');
        var annotation = annotatedClass.metadata.single;
        var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
        expect(matched, isTrue);
      });
    });

    group('with class annotations', () {
      test('annotated with class', () {
        var annotatedClass = _getAnnotationForClass(libElement, 'CtorNoParams');
        var annotation = annotatedClass.metadata.single;
        var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
        expect(matched, isTrue);
      });

      test('not annotated with specified class', () {
        var annotatedClass =
            _getAnnotationForClass(libElement, 'OtherClassCtorNoParams');
        var annotation = annotatedClass.metadata.single;
        var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
        expect(matched, isFalse, reason: 'not annotated with that type');
      });

      test('annotated with class in a part', () {
        ClassElement annotatedClass =
            _getAnnotationForClass(libElement, 'CtorNoParamsFromPartInPart');
        var annotation = annotatedClass.metadata.single;
        var matched =
            matchAnnotation(defs.PublicAnnotationClassInPart, annotation);
        expect(matched, isTrue);
      });

      test('class in a part annotated with class', () {
        var annotatedClass =
            _getAnnotationForClass(libElement, 'CtorNoParamsInPart');
        var annotation = annotatedClass.metadata.single;
        var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
        expect(matched, isTrue);
      });

      test('class in a part annotated with class in a part', () {
        ClassElement annotatedClass =
            _getAnnotationForClass(libElement, 'CtorNoParamsFromPartInPart');
        var annotation = annotatedClass.metadata.single;
        var matched =
            matchAnnotation(defs.PublicAnnotationClassInPart, annotation);
        expect(matched, isTrue);
      });

      group('class annotated with type defined via package uri', () {
        test('When running on a normal file system', () {
          ClassElement annotatedClass =
              _getAnnotationForClass(libElement, 'AnnotatedWithJson');
          var annotation = annotatedClass.metadata.single;
          var matched = matchAnnotation(JsonSerializable, annotation);
          expect(matched, isTrue);
        });

        test('When running in barback', () {
          var annotation = _mockElementAnnotation(
              'JsonSerializable',
              new Uri(
                  scheme: 'asset',
                  path: 'source_gen/lib/generators/json_serializable.dart'));

          var matched = matchAnnotation(JsonSerializable, annotation);
          expect(matched, isTrue);
        });
      });
    });
  });
}

Future<LibraryElement> _getTestLibElement() async {
  var testFilesRelativePath = p.join('test', 'test_files');

  var projectPath = getPackagePath();

  var foundFiles =
      await getDartFiles(projectPath, searchList: [testFilesRelativePath]);

  var context = await getAnalysisContextForProjectPath(projectPath, foundFiles);

  var annotatedClassesFilePath =
      p.join(projectPath, testFilesRelativePath, 'annotated_classes.dart');

  return getLibraryElementForSourceFile(context, annotatedClassesFilePath);
}

ClassElement _getAnnotationForClass(LibraryElement lib, String className) => lib
    .units.expand((cu) => cu.types).singleWhere((cd) => cd.name == className);

/// Returns a mock [ElementAnnotationImpl] whose
/// `evaluationResult.value.type.element.library.source` is `libraryUri` and
/// whose `evaluationResult.value.type.name` is `typeName`.
ElementAnnotationImpl _mockElementAnnotation(String typeName, Uri libraryUri) {
  var annotation = new MockElementAnnotationImpl();
  var result = new MockEvaluationResultImpl();
  var value = new MockDartObjectImpl();
  var type = new MockParameterizedType();
  var element = new MockElement();
  var library = new MockLibraryElement();
  var source = new MockSource();
  when(annotation.evaluationResult).thenReturn(result);
  when(result.value).thenReturn(value);
  when(value.type).thenReturn(type);
  when(type.name).thenReturn(typeName);
  when(type.element).thenReturn(element);
  when(element.library).thenReturn(library);
  when(library.source).thenReturn(source);
  when(source.uri).thenReturn(libraryUri);
  return annotation;
}

class MockElementAnnotationImpl extends Mock implements ElementAnnotationImpl {}

class MockEvaluationResultImpl extends Mock implements EvaluationResultImpl {}

class MockDartObjectImpl extends Mock implements DartObjectImpl {}

class MockParameterizedType extends Mock implements ParameterizedType {}

class MockElement extends Mock implements Element {}

class MockLibraryElement extends Mock implements LibraryElement {}

class MockSource extends Mock implements Source {}
