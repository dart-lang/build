library source_gen.test.json_generator_test;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/string_source.dart';

import 'package:source_gen/src/utils.dart';
import 'package:source_gen/json_serial/json_generator.dart';

import 'package:scheduled_test/scheduled_test.dart';

import 'test_utils.dart';

void main() {
  group('non-classes', () {
    test('const field', () {
      var element = _getClassForCodeString('theAnswer');

      expect(() => _generator.generate(element), throws);
      // TODO: validate the properties on the thrown error
    });

    test('method', () {
      var element = _getClassForCodeString('annotatedMethod');

      expect(() => _generator.generate(element), throws);
      // TODO: validate the properties on the thrown error
    });
  });

  test('class with final fields', () {
    var element = _getClassForCodeString('FinalFields');
    expect(() => _generator.generate(element), throws);
  });

  test('unannotated classes no-op', () {
    var element = _getClassForCodeString('NoAnnotation');
    var output = _generator.generate(element);

    expect(output, isNull);
  });

  group('valid inputs', () {
    test('class with no fields', () {
      var element = _getClassForCodeString('Person');
      var output = _generator.generate(element);

      expect(output, isNotNull);

      // TODO: test the actual output
    });
  });
}

const _generator = const JsonGenerator();

Element _getClassForCodeString(String name) =>
    _getElementsForCodeString().singleWhere((e) => e.name == name);

Iterable<Element> _getElementsForCodeString() {
  if (_compUnit == null) {
    _compUnit = _getCompilationUnitForString(getPackagePath());
  }

  return getElementsFromCompilationUnit(_compUnit);
}

CompilationUnit _getCompilationUnitForString(String projectPath) {
  Source source = new StringSource(_testSource, 'test content');

  var context = getAnalysisContextForProjectPath(projectPath);

  LibraryElement libElement = context.computeLibraryElement(source);
  return context.resolveCompilationUnit(source, libElement);
}

CompilationUnit _compUnit;

const _testSource = r'''
import 'package:source_gen/json_serial/json_annotation.dart';

@JsonSerializable()
const theAnswer = 42;

@JsonSerializable()
void annotatedMethod() => null;

@JsonSerializable()
class Person {
}

class NoAnnotation {
}

@JsonSerializable()
class FinalFields {
  final int a;
  int get b => 4;

  FinalFields(this.a);
}
''';
