// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('!browser')
library source_gen.test.json_generator_test;

import 'dart:async';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';

import 'package:source_gen/src/io.dart';
import 'package:source_gen/src/utils.dart';
import 'package:source_gen/generators/json_serializable_generator.dart';

import 'test_utils.dart';

void main() {
  group('non-classes', () {
    test('const field', () async {
      var element = await _getClassForCodeString('theAnswer');

      expect(_generator.generate(element), throwsInvalidGenerationSourceError);
      // TODO: validate the properties on the thrown error
    });

    test('method', () async {
      var element = await _getClassForCodeString('annotatedMethod');

      expect(_generator.generate(element), throwsInvalidGenerationSourceError);
      // TODO: validate the properties on the thrown error
    });
  });

  test('class with final fields', () async {
    var element = await _getClassForCodeString('FinalFields');
    expect(_generator.generate(element), throwsInvalidGenerationSourceError);
  });

  test('unannotated classes no-op', () async {
    var element = await _getClassForCodeString('NoAnnotation');
    var output = _generator.generate(element);

    expect(output, isNull);
  });

  group('valid inputs', () {
    test('class with no fields', () async {
      var element = await _getClassForCodeString('Person');
      var output = await _generator.generate(element);

      expect(output, isNotNull);

      // TODO: test the actual output
      // print(output);
    });

    test('class with ctor params', () async {
      var element = await _getClassForCodeString('Order');
      var output = await _generator.generate(element);

      expect(output, isNotNull);

      // TODO: test the actual output
      // print(output);
    });

    test('class with child json-able object', () async {
      var element = await _getClassForCodeString('ParentObject');
      var output = await _generator.generate(element);

      expect(output, isNotNull);

      expect(output, contains('new ChildObject.fromJson'));
    });
  });
}

const _generator = const JsonSerializableGenerator();

Future<Element> _getClassForCodeString(String name) async {
  var elements = await _getElementsForCodeString();

  return elements.singleWhere((e) => e.name == name);
}

Future<List<Element>> _getElementsForCodeString() async {
  if (_compUnit == null) {
    _compUnit = await _getCompilationUnitForString(getPackagePath());
  }

  return getElementsFromLibraryElement(_compUnit.element.library);
}

Future<CompilationUnit> _getCompilationUnitForString(String projectPath) async {
  Source source = new StringSource(_testSource, 'test content');

  var foundFiles = await getDartFiles(projectPath,
      searchList: [p.join(getPackagePath(), 'test', 'test_files')]);

  var context = await getAnalysisContextForProjectPath(projectPath, foundFiles);

  LibraryElement libElement = context.computeLibraryElement(source);
  return context.resolveCompilationUnit(source, libElement);
}

CompilationUnit _compUnit;

const _testSource = r'''
import 'package:source_gen/generators/json_serializable.dart';

@JsonSerializable()
const theAnswer = 42;

@JsonSerializable()
void annotatedMethod() => null;

@JsonSerializable()
class Person {
  String firstName, lastName;
  int height;
  DateTime dateOfBirth;
  dynamic dynamicType;
  var varType;
}

@JsonSerializable()
class Order {
  final String firstName, lastName;
  int height;
  DateTime dateOfBirth;

  Order(this.height, String firstName, [this.lastName]);
}

class NoAnnotation {
}

@JsonSerializable()
class FinalFields {
  final int a;
  int get b => 4;

  FinalFields(this.a);
}

@JsonSerializable()
class ParentObject {
  int number;
  String str;
  ChildObject child;
}

@JsonSerializable()
class ChildObject {
  int number;
  String str;

  factory ChildObject.fromJson(json) => null;
}
''';
