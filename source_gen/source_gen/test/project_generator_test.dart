library source_gen.test.project_generator_test;

import 'dart:async';
import 'dart:io';

import 'package:analyzer/src/generated/element.dart';
import 'package:path/path.dart' as p;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:source_gen/src/build_file_generator.dart';
import 'package:source_gen/src/generator.dart';

import 'test_utils.dart';

void main() {
  test('Simple Generator test', () async {
    var dir = await createTempDir();

    d.defaultRoot = dir.path;

    var projectPath = await _createPackageStub('pkg');

    var relativeFilePath = p.join('lib', 'test_lib.dart');
    var output =
        await generate(projectPath, relativeFilePath, [const _TestGenerator()]);

    expect(output, isNotNull);
    expect(output, isNotEmpty);

    await d
        .dir('pkg', [
      d.dir('lib', [
        d.file('test_lib.dart', _testLibContent),
        d.file('test_lib_part.dart', _testLibPartContent),
        d.matcherFile('test_lib.g.dart', contains(_testGenPartContent))
      ])
    ])
        .validate();
  });

  test('No-op generator produces no generated parts', () async {
    var dir = await createTempDir();

    d.defaultRoot = dir.path;

    var projectPath = await _createPackageStub('pkg');

    var relativeFilePath = p.join('lib', 'test_lib.dart');
    var output =
        await generate(projectPath, relativeFilePath, [const _NoOpGenerator()]);

    expect(output, isNotNull);
    expect(output, isNotEmpty);

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
}

/// Creates a package using [pkgName] an the current [d.defaultRoot].
Future<String> _createPackageStub(String pkgName) async {
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

const _testLibPartContent = r'''
part of test_lib;

final int bar = 42;

class Customer { }
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
