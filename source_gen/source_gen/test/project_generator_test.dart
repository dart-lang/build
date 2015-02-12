library source_gen.test.project_generator_test;

import 'dart:async';
import 'dart:io';

import 'package:analyzer/src/generated/element.dart';
import 'package:path/path.dart' as p;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:source_gen/src/generate.dart';
import 'package:source_gen/src/generator.dart';

import 'test_utils.dart';

void main() {
  test('Simple Generator test', _simpleTest);

  test('No-op generator produces no generated parts', () async {
    await _doSetup();

    var projectPath = await _createPackageStub('pkg');

    var relativeFilePath = p.join('lib', 'test_lib.dart');
    var output = await generate(
        projectPath, [const _NoOpGenerator()], [relativeFilePath]);

    expect(output, "Nothing to generate");

    await d
        .dir('pkg', [
      d.dir('lib', [
        d.file('test_lib.dart', _testLibContent),
        d.file('test_lib_part.dart', _testLibPartContent),
        d.nothing('test_lib.g.dart')
      ])
    ])
        .validate();
  });

  test('Track changes', () async {
    var projectPath = await _simpleTest();

    //
    // run generate again: no change
    //
    var relativeFilePath = p.join('lib', 'test_lib.dart');
    var output = await generate(
        projectPath, [const _TestGenerator()], [relativeFilePath]);

    expect(output, "No change: 'lib/test_lib.g.dart'");

    await d
        .dir('pkg', [
      d.dir('lib', [
        d.file('test_lib.dart', _testLibContent),
        d.file('test_lib_part.dart', _testLibPartContent),
        d.matcherFile('test_lib.g.dart', contains(_testGenPartContent))
      ])
    ])
        .validate();

    //
    // change classes to remove one class: updated
    //
    await new File(p.join(projectPath, relativeFilePath))
        .writeAsString(_testLibContentNoClass);

    output = await generate(
        projectPath, [const _TestGenerator()], [relativeFilePath]);

    expect(output, "Updated: 'lib/test_lib.g.dart'");

    await d
        .dir('pkg', [
      d.dir('lib', [
        d.file('test_lib.dart', _testLibContentNoClass),
        d.file('test_lib_part.dart', _testLibPartContent),
        d.matcherFile('test_lib.g.dart', contains(_testGenPartContentNoPerson))
      ])
    ])
        .validate();

    //
    // change classes add classes back: created
    //
    var partRelativeFilePath = p.join('lib', 'test_lib_part.dart');
    await new File(p.join(projectPath, partRelativeFilePath))
        .writeAsString(_testLibPartContentNoClass);

    output = await generate(
        projectPath, [const _TestGenerator()], [partRelativeFilePath]);

    expect(output, "Deleted: 'lib/test_lib.g.dart'");

    await d
        .dir('pkg', [
      d.dir('lib', [
        d.file('test_lib.dart', _testLibContentNoClass),
        d.file('test_lib_part.dart', _testLibPartContentNoClass),
        d.nothing('test_lib.g.dart')
      ])
    ])
        .validate();
  });
}

Future _doSetup() async {
  var dir = await createTempDir();
  d.defaultRoot = dir.path;
}

Future _simpleTest() async {
  await _doSetup();

  var projectPath = await _createPackageStub('pkg');

  var relativeFilePath = p.join('lib', 'test_lib.dart');
  var output =
      await generate(projectPath, [const _TestGenerator()], [relativeFilePath]);

  expect(output, "Created: 'lib/test_lib.g.dart'");

  await d
      .dir('pkg', [
    d.dir('lib', [
      d.file('test_lib.dart', _testLibContent),
      d.file('test_lib_part.dart', _testLibPartContent),
      d.matcherFile('test_lib.g.dart', contains(_testGenPartContent))
    ])
  ])
      .validate();

  return projectPath;
}

/// Creates a package using [pkgName] an the current [d.defaultRoot].
Future _createPackageStub(String pkgName) async {
  await d
      .dir(pkgName, [
    d.dir('lib', [
      d.file('test_lib.dart', _testLibContent),
      d.file('test_lib_part.dart', _testLibPartContent),
    ])
  ])
      .create();

  var pkgPath = p.join(d.defaultRoot, pkgName);
  var exists = await FileSystemEntity.isDirectory(pkgPath);

  assert(exists);

  return pkgPath;
}

/// Doesn't generate output for any element
class _NoOpGenerator extends Generator {
  const _NoOpGenerator();
  String generate(Element element) => null;
}

/// Generates a single-line comment for each element
class _TestGenerator extends Generator {
  const _TestGenerator();

  String generate(Element element) {
    if (element is ClassElement) {
      return '// Code for $element';
    }
    return null;
  }

  String toString() => 'TestGenerator';
}

const _testLibContent = r'''
library test_lib;

part 'test_lib_part.dart';

final int foo = 42;

class Person { }
''';

const _testLibContentNoClass = r'''
library test_lib;

part 'test_lib_part.dart';

final int foo = 42;
''';

const _testLibPartContent = r'''
part of test_lib;

final int bar = 42;

class Customer { }
''';

const _testLibPartContentNoClass = r'''
part of test_lib;

final int bar = 42;
''';

const _testGenPartContent = r'''part of test_lib;

// **************************************************************************
// Generator: TestGenerator
// Target: class Person
// **************************************************************************

// Code for Person

// **************************************************************************
// Generator: TestGenerator
// Target: class Customer
// **************************************************************************

// Code for Customer''';

const _testGenPartContentNoPerson = r'''part of test_lib;

// **************************************************************************
// Generator: TestGenerator
// Target: class Customer
// **************************************************************************

// Code for Customer''';
