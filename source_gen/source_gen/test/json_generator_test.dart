library source_gen.test.json_generator_test;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/string_source.dart';

import 'package:source_gen/src/utils.dart';
import 'package:source_gen/json_serial/json_generator.dart';

import 'package:unittest/unittest.dart';

import 'test_utils.dart';

void main() {
  group('non-classes', () {
    test('const field', () {
      var element = _getClassForCodeString(_classNoFieldsContent, 'theAnswer');

      expect(() => _generator.generate(element), throws);
      // TODO: validate the properties on the thrown error
    });

    test('method', () {
      var element =
          _getClassForCodeString(_classNoFieldsContent, 'annotatedMethod');

      expect(() => _generator.generate(element), throws);
      // TODO: validate the properties on the thrown error
    });
  });

  test('unannotated classes no-op', () {
    var element = _getClassForCodeString(_classNoFieldsContent, 'NoAnnotation');
    var output = _generator.generate(element);

    expect(output, isNull);
  });

  group('valid inputs', () {
    test('class with no fields', () {
      var element = _getClassForCodeString(_classNoFieldsContent, 'Person');
      var output = _generator.generate(element);

      expect(output, isNotNull);

      // TODO: test the actual output
    });
  });

  test('class cannot be abstract', () {});

  test('class must have a default ctor', () {});
}

const _generator = const JsonGenerator();

Element _getClassForCodeString(String source, String name) =>
    _getElementsForCodeString(source).singleWhere((e) => e.name == name);

Iterable<Element> _getElementsForCodeString(String source) {
  var cu =
      _getCompilationUnitForString(getPackagePath(), _classNoFieldsContent);

  return getElementsFromCompilationUnit(cu);
}

CompilationUnit _getCompilationUnitForString(
    String projectPath, String content) {
  Source source = new StringSource(content, 'test content');

  var context = getAnalysisContextForProjectPath(projectPath);

  LibraryElement libElement = context.computeLibraryElement(source);
  return context.resolveCompilationUnit(source, libElement);
}

const _classNoFieldsContent = r'''
import 'package:source_gen/json_serial/json_annotation.dart';

@JsonSerializable()
const theAnswer = 42;

@JsonSerializable()
void annotatedMethod() => null;

@JsonSerializable()
class Person {
  Person();
}

class NoAnnotation {
}
''';
