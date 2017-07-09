// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import 'src/comment_generator.dart';
import 'src/unformatted_code_generator.dart';

void main() {
  test('Simple Generator test', _simpleTest);

  test('Bad generated source', () async {
    var srcs = _createPackageStub(pkgName);
    var builder = new GeneratorBuilder([const _BadOutputGenerator()]);

    await testBuilder(builder, srcs,
        generateFor: new Set.from(['$pkgName|lib/test_lib.dart']),
        outputs: {
          '$pkgName|lib/test_lib.g.dart': contains('not valid code!'),
        });
  });

  test('Generate standalone output file', () async {
    var srcs = _createPackageStub(pkgName);
    var builder =
        new GeneratorBuilder([const CommentGenerator()], isStandalone: true);
    await testBuilder(builder, srcs,
        generateFor: new Set.from(['$pkgName|lib/test_lib.dart']),
        outputs: {
          '$pkgName|lib/test_lib.g.dart': _testGenStandaloneContent,
        });
  });

  test('Generate explicitly non-standalone output file', () async {
    var srcs = _createPackageStub(pkgName);
    var builder =
        new GeneratorBuilder([const CommentGenerator()], isStandalone: false);
    await testBuilder(builder, srcs,
        generateFor: new Set.from(['$pkgName|lib/test_lib.dart']),
        outputs: {
          '$pkgName|lib/test_lib.g.dart': _testGenPartContent,
        });
  });

  test('Expect error when multiple generators used on a standalone builder',
      () async {
    expect(
        () => new GeneratorBuilder(
            [const CommentGenerator(), const _NoOpGenerator()],
            isStandalone: true),
        throwsA(new isInstanceOf<ArgumentError>()));
  });

  test('Expect no error when multiple generators used on nonstandalone builder',
      () async {
    expect(
        () => new GeneratorBuilder(
            [const CommentGenerator(), const _NoOpGenerator()]),
        returnsNormally);
  });

  test('Throws an exception when no library identifier is found', () async {
    var sources = _createPackageStub(pkgName, testLibContent: 'class A {}');
    var builder = new GeneratorBuilder([const CommentGenerator()]);
    expect(
        testBuilder(builder, sources,
            outputs: {'$pkgName|lib/test_lib.g.dart': ''}),
        throwsA(const isInstanceOf<InvalidGenerationSourceError>()));
  });

  test('Does not fail when there is no output', () async {
    var sources = _createPackageStub(pkgName, testLibContent: 'class A {}');
    var builder =
        new GeneratorBuilder([new CommentGenerator(forClasses: false)]);
    await testBuilder(builder, sources, outputs: {});
  });

  test('Allow no "library" when requireLibraryDirective=false', () async {
    var sources = _createPackageStub(pkgName, testLibContent: 'class A {}');
    var builder = new GeneratorBuilder([const CommentGenerator()],
        requireLibraryDirective: false);
    await testBuilder(builder, sources,
        outputs: {'$pkgName|lib/test_lib.g.dart': _testGenNoLibrary});
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
    var builder = new GeneratorBuilder([const _NoOpGenerator()]);
    await testBuilder(builder, srcs, outputs: {});
  });

  test('handle generator errors well', () async {
    var srcs =
        _createPackageStub(pkgName, testLibContent: _testLibContentWithError);
    var builder = new GeneratorBuilder([const CommentGenerator()]);
    await testBuilder(builder, srcs,
        generateFor: new Set.from(['$pkgName|lib/test_lib.dart']),
        outputs: {
          '$pkgName|lib/test_lib.g.dart': _testGenPartContentError,
        });
  });

  test('warns when a non-standalone builder does not see "part"', () async {
    var srcs =
        _createPackageStub(pkgName, testLibContent: _testLibContentNoPart);
    var builder = new GeneratorBuilder([const CommentGenerator()]);
    var logs = <String>[];
    await testBuilder(
      builder,
      srcs,
      onLog: (log) {
        logs.add(log.message);
      },
    );
    expect(logs, ['Missing "part \'test_lib.g.dart\';".']);
  });

  test('defaults to formatting generated code with the DartFormatter',
      () async {
    await testBuilder(new GeneratorBuilder([new UnformattedCodeGenerator()]),
        {'$pkgName|lib/a.dart': 'library a; part "a.part.dart";'},
        generateFor: new Set.from(['$pkgName|lib/a.dart']),
        outputs: {
          '$pkgName|lib/a.g.dart':
              contains(UnformattedCodeGenerator.formattedCode),
        });
  });

  test('can skip formatting with a trivial lambda', () async {
    await testBuilder(
        new GeneratorBuilder([new UnformattedCodeGenerator()],
            formatOutput: (s) => s),
        {'$pkgName|lib/a.dart': 'library a; part "a.part.dart";'},
        generateFor: new Set.from(['$pkgName|lib/a.dart']),
        outputs: {
          '$pkgName|lib/a.g.dart':
              contains(UnformattedCodeGenerator.unformattedCode),
        });
  });

  test('can pass a custom formatter with formatOutput', () async {
    var customOutput = 'final String hello = "hello";';
    await testBuilder(
        new GeneratorBuilder([new UnformattedCodeGenerator()],
            formatOutput: (_) => customOutput),
        {'$pkgName|lib/a.dart': 'library a; part "a.part.dart";'},
        generateFor: new Set.from(['$pkgName|lib/a.dart']),
        outputs: {
          '$pkgName|lib/a.g.dart': contains(customOutput),
        });
  });
}

Future _simpleTest() => _generateTest(
    const CommentGenerator(forClasses: true, forLibrary: false),
    _testGenPartContent);

Future _generateTest(CommentGenerator gen, String expectedContent) async {
  var srcs = _createPackageStub(pkgName);
  var builder = new GeneratorBuilder([gen]);

  await testBuilder(builder, srcs,
      generateFor: new Set.from(['$pkgName|lib/test_lib.dart']),
      outputs: {
        '$pkgName|lib/test_lib.g.dart': expectedContent,
      },
      onLog: (log) => fail('Unexpected log message: ${log.message}'));
}

/// Creates a package using [pkgName].
Map<String, String> _createPackageStub(String pkgName,
    {String testLibContent, String testLibPartContent}) {
  return {
    '$pkgName|lib/test_lib.dart': testLibContent ?? _testLibContent,
    '$pkgName|lib/test_lib.g.dart': testLibPartContent ?? _testLibPartContent,
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
part 'test_lib.g.dart';
final int foo = 42;
class Person { }
''';

const _testLibContentNoPart = r'''
library test_lib;
final int foo = 42;
class Person { }
''';

const _testLibContentWithError = r'''
library test_lib;
part 'test_lib.g.dart';
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

const _testGenStandaloneContent = r'''// GENERATED CODE - DO NOT MODIFY BY HAND

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

const _testGenNoLibrary = r'''// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_lib.dart';

// **************************************************************************
// Generator: CommentGenerator
// Target: class A
// **************************************************************************

// Code for "class A"
''';
