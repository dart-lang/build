// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('!browser')
library source_gen.test.annotation_test;

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import 'package:analyzer/src/generated/constant.dart';
//import 'package:analyzer/src/generated/element.dart' show ElementAnnotationImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/generators/json_serializable.dart';
import 'package:source_gen/src/annotation.dart';
import 'package:source_gen/src/utils.dart';
import 'package:test/test.dart';

import 'src/io.dart';
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
        var instance = _getInstantiatedAnnotation(libElement, 'WithTypedField');
        expect(instance is defs.PublicAnnotationClass, isTrue);
        expect(instance.anInt, 0);
      });

      test('annotated with untyped field', () {
        var instance =
            _getInstantiatedAnnotation(libElement, 'WithUntypedField');
        expect(instance is defs.PublicAnnotationClass, isTrue);
        expect(instance.anInt, 0);
      });

      test('annotated with local typed field', () {
        var instance =
            _getInstantiatedAnnotation(libElement, 'WithLocalTypedField');
        expect(instance is defs.PublicAnnotationClass, isTrue);
        expect(instance.anInt, 0);
      });

      test('annotated with local untyped field', () {
        var instance =
            _getInstantiatedAnnotation(libElement, 'WithLocalUntypedField');
        expect(instance is defs.PublicAnnotationClass, isTrue);
        expect(instance.anInt, 0);
      });
    });

    test('annotated with class', () {
      var instance = _getInstantiatedAnnotation(libElement, 'CtorNoParams');
      expect(instance is defs.PublicAnnotationClass, isTrue);
      expect(instance.anInt, 0);
      expect(instance.aBool, isFalse);
    });

    test('annotated with class using a non-default ctor', () {
      var instance =
          _getInstantiatedAnnotation(libElement, 'NonDefaultCtorNoParams');
      expect(instance is defs.PublicAnnotationClass, isTrue);
      expect(instance.anInt, 1);
      expect(instance.aBool, isFalse);
    });

    test('using a non-default ctor with potional args', () {
      var instance = _getInstantiatedAnnotation(
              libElement, 'NonDefaultCtorWithPositionalParams')
          as defs.PublicAnnotationClass;
      expect(instance.anInt, 42);
      expect(instance.aString, 'custom value');
      expect(instance.aBool, isFalse);
      expect(instance.aList, [2, 3, 4]);
    });

    test('using a non-default ctor with potional and named args', () {
      var instance = _getInstantiatedAnnotation(
          libElement, 'NonDefaultCtorWithPositionalAndNamedParams');
      expect(instance.anInt, 43);
      expect(instance.aString, 'another value');
      expect(instance.aBool, isTrue);
      expect(instance.aList, [5, 6, 7]);
      expect(instance.child1, isNull);
      expect(instance.child2, isNull);
    });

    test('with nested objects', () {
      var instance =
          _getInstantiatedAnnotation(libElement, 'WithNestedObjects');
      expect(instance.child1, const defs.PublicAnnotationClass());
      expect(
          instance.child2, const defs.PublicAnnotationClass.withAnIntAsOne());
    });

    test('with constant map literal', () {
      var instance =
          _getInstantiatedAnnotation(libElement, 'WithConstMapLiteral');
      expect(instance, defs.objectAnnotation);
    });

    test('with a field using non-default ctor', () {
      var instance = _getInstantiatedAnnotation(
          libElement, 'WithAFieldFromNonDefaultCtor');
      expect(instance.anInt, defs.untypedAnnotationWithNonDefaultCtor.anInt);
      expect(
          instance.aString, defs.untypedAnnotationWithNonDefaultCtor.aString);
      expect(instance.aBool, defs.untypedAnnotationWithNonDefaultCtor.aBool);
    });
  });

  group('matchAnnotation', () {
    group('with field annotations', () {
      test('annotated with typed field', () {
        var annotation = _getClassAnnotation(libElement, 'WithTypedField');
        var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
        expect(matched, isTrue);
      });

      test('annotated with untyped field', () {
        var annotation = _getClassAnnotation(libElement, 'WithUntypedField');
        var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
        expect(matched, isTrue);
      });

      test('annotated with local typed field', () {
        var annotation = _getClassAnnotation(libElement, 'WithLocalTypedField');
        var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
        expect(matched, isTrue);
      });

      test('annotated with local untyped field', () {
        var annotation =
            _getClassAnnotation(libElement, 'WithLocalUntypedField');
        var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
        expect(matched, isTrue);
      });
    });

    group('with class annotations', () {
      test('annotated with class', () {
        var annotation = _getClassAnnotation(libElement, 'CtorNoParams');
        var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
        expect(matched, isTrue);
      });

      test('not annotated with specified class', () {
        var annotation =
            _getClassAnnotation(libElement, 'OtherClassCtorNoParams');
        var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
        expect(matched, isFalse, reason: 'not annotated with that type');
      });

      test('annotated with class in a part', () {
        var annotation =
            _getClassAnnotation(libElement, 'CtorNoParamsFromPartInPart');
        var matched =
            matchAnnotation(defs.PublicAnnotationClassInPart, annotation);
        expect(matched, isTrue);
      });

      test('class in a part annotated with class', () {
        var annotation = _getClassAnnotation(libElement, 'CtorNoParamsInPart');
        var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
        expect(matched, isTrue);
      });

      test('class in a part annotated with class in a part', () {
        var annotation =
            _getClassAnnotation(libElement, 'CtorNoParamsFromPartInPart');
        var matched =
            matchAnnotation(defs.PublicAnnotationClassInPart, annotation);
        expect(matched, isTrue);
      });

      group('class annotated with type defined via package uri', () {
        test('When running on a normal file system', () {
          var annotation = _getClassAnnotation(libElement, 'AnnotatedWithJson');
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

dynamic _getInstantiatedAnnotation(LibraryElement lib, String className) =>
    instantiateAnnotation(_getClassAnnotation(lib, className));

ElementAnnotation _getClassAnnotation(LibraryElement lib, String className) =>
    _getAnnotatedClass(lib, className).metadata.single;

ClassElement _getAnnotatedClass(LibraryElement lib, String className) =>
    lib.units
        .expand((cu) => cu.types)
        .singleWhere((cd) => cd.name == className);

/// Returns a mock [MockElementAnnotation] whose
/// `evaluationResult.value.type.element.library.source` is `libraryUri` and
/// whose `evaluationResult.value.type.name` is `typeName`.
ElementAnnotation _mockElementAnnotation(String typeName, Uri libraryUri) {
  var annotation = new MockElementAnnotation();
  var value = new MockDartObject();
  var type = new MockParameterizedType();
  var element = new MockElement();
  var library = new MockLibraryElement();
  var source = new MockSource();
  when(annotation.constantValue).thenReturn(value);
  when(value.type).thenReturn(type);
  when(type.name).thenReturn(typeName);
  when(type.element).thenReturn(element);
  when(element.library).thenReturn(library);
  when(library.source).thenReturn(source);
  when(source.uri).thenReturn(libraryUri);
  return annotation;
}

class MockElementAnnotation extends Mock implements ElementAnnotation {}

class MockDartObject extends Mock implements DartObject {}

class MockParameterizedType extends Mock implements ParameterizedType {}

class MockElement extends Mock implements Element {}

class MockLibraryElement extends Mock implements LibraryElement {}

class MockSource extends Mock implements Source {}
