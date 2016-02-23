// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'dart:async';

import 'package:analyzer/src/generated/element.dart';
import 'package:build/build.dart';
import 'package:test/test.dart';

import 'package:source_gen/builder.dart';
import 'package:source_gen/source_gen.dart';

import 'src/comment_generator.dart';
import 'src/test_phases.dart';

void main() {
  test('Simple Generator test', _simpleTest);

  test('Bad generated source', () async {
    var srcs = _createPackageStub(pkgName);
    var phaseGroup = new PhaseGroup.singleAction(
        new GeneratorBuilder([const _BadOutputGenerator()],
            omitGenerateTimestamp: true),
        new InputSet(pkgName, ['lib/test_lib.dart']));

    await testPhases(phaseGroup, pkgName, srcs,
        {'$pkgName|lib/test_lib.g.dart': contains('not valid code!'),});
  });

  test(
      'Simple Generator test for library',
      () => _generateTest(
          const CommentGenerator(forClasses: false, forLibrary: true),
          _testGenPartContentForLibrary));

  test(
      'Simple Generator test for classes and library',
      () => _generateTest(
          const CommentGenerator(forClasses: true, forLibrary: true),
          _testGenPartContentForClassesAndLibrary));

  test('No-op generator produces no generated parts', () async {
    var srcs = _createPackageStub(pkgName);
    var phaseGroup = new PhaseGroup.singleAction(
        new GeneratorBuilder([const _NoOpGenerator()]),
        new InputSet(pkgName, ['lib/test_lib.dart']));

    await testPhases(phaseGroup, pkgName, srcs, {});
  });

  test('handle generator errors well', () async {
    var srcs =
        _createPackageStub(pkgName, testLibContent: _testLibContentWithError);
    var phaseGroup = new PhaseGroup.singleAction(
        new GeneratorBuilder([const CommentGenerator()],
            omitGenerateTimestamp: true),
        new InputSet(pkgName, ['lib/test_lib.dart']));
    await testPhases(phaseGroup, pkgName, srcs,
        {'$pkgName|lib/test_lib.g.dart': _testGenPartContentError,});
  });
}

Future _simpleTest() => _generateTest(
    const CommentGenerator(forClasses: true, forLibrary: false),
    _testGenPartContent);

Future _generateTest(CommentGenerator gen, String expectedContent) async {
  var srcs = await _createPackageStub(pkgName);
  var phaseGroup = new PhaseGroup.singleAction(
      new GeneratorBuilder([gen], omitGenerateTimestamp: true),
      new InputSet(pkgName, ['lib/test_lib.dart']));

  await testPhases(phaseGroup, pkgName, srcs,
      {'$pkgName|lib/test_lib.g.dart': expectedContent,});
}

/// Creates a package using [pkgName].
Map<String, String> _createPackageStub(String pkgName,
    {String testLibContent, String testLibPartContent}) {
  return {
    '$pkgName|lib/test_lib.dart': testLibContent ?? _testLibContent,
    '$pkgName|lib/test_lib_part.dart':
        testLibPartContent ?? _testLibPartContent,
  };
}

/// Doesn't generate output for any element
class _NoOpGenerator extends Generator {
  const _NoOpGenerator();
  Future<String> generate(Element element, _) => null;
}

class _BadOutputGenerator extends Generator {
  const _BadOutputGenerator();
  Future<String> generate(Element element, _) async {
    if (element is LibraryElement) {
      return 'not valid code!';
    }
    return null;
  }
}

const pkgName = 'pkg';

const _testLibContent = r'''
library test_lib;
part 'test_lib_part.dart';
final int foo = 42;
class Person { }
''';

const _testLibContentWithError = r'''
library test_lib;
part 'test_lib_part.dart';
class MyError { }
class MyGoodError { }
''';

const _testLibPartContent = r'''
part of test_lib;
final int bar = 42;
class Customer { }
''';

const _testGenPartContent = r'''// GENERATED CODE - DO NOT MODIFY BY HAND

part of test_lib;

// **************************************************************************
// Generator: CommentGenerator
// Target: class Person
// **************************************************************************

// Code for "class Person"

// **************************************************************************
// Generator: CommentGenerator
// Target: class Customer
// **************************************************************************

// Code for "class Customer"
''';

const _testGenPartContentForLibrary =
    r'''// GENERATED CODE - DO NOT MODIFY BY HAND

part of test_lib;

// **************************************************************************
// Generator: CommentGenerator
// Target: library test_lib
// **************************************************************************

// Code for "test_lib"
''';

const _testGenPartContentForClassesAndLibrary =
    r'''// GENERATED CODE - DO NOT MODIFY BY HAND

part of test_lib;

// **************************************************************************
// Generator: CommentGenerator
// Target: library test_lib
// **************************************************************************

// Code for "test_lib"

// **************************************************************************
// Generator: CommentGenerator
// Target: class Person
// **************************************************************************

// Code for "class Person"

// **************************************************************************
// Generator: CommentGenerator
// Target: class Customer
// **************************************************************************

// Code for "class Customer"
''';

const _testGenPartContentError = r'''// GENERATED CODE - DO NOT MODIFY BY HAND

part of test_lib;

// **************************************************************************
// Generator: CommentGenerator
// Target: class MyError
// **************************************************************************

// Error: Invalid argument (element): We don't support class names with the word 'Error'.
//        Try renaming the class.: Instance of 'ClassElementImpl'

// **************************************************************************
// Generator: CommentGenerator
// Target: class MyGoodError
// **************************************************************************

// Error: Don't use classes with the word 'Error' in the name
// TODO: Rename MyGoodError to something else.

// **************************************************************************
// Generator: CommentGenerator
// Target: class Customer
// **************************************************************************

// Code for "class Customer"
''';
