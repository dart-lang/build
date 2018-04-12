// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:async';

import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import 'src/comment_generator.dart';
import 'src/unformatted_code_generator.dart';

void main() {
  test('Simple Generator test', () {
    _generateTest(const CommentGenerator(forClasses: true, forLibrary: false),
        _testGenPartContent);
  });

  test('Bad generated source', () async {
    var srcs = _createPackageStub();
    var builder = new PartBuilder([const _BadOutputGenerator()]);

    await testBuilder(builder, srcs,
        generateFor: new Set.from(['$_pkgName|lib/test_lib.dart']),
        outputs: {
          '$_pkgName|lib/test_lib.g.dart':
              decodedMatches(contains('not valid code!')),
        });
  });

  test('Generate standalone output file', () async {
    var srcs = _createPackageStub();
    var builder = new LibraryBuilder(const CommentGenerator());
    await testBuilder(builder, srcs,
        generateFor: new Set.from(['$_pkgName|lib/test_lib.dart']),
        outputs: {
          '$_pkgName|lib/test_lib.g.dart': _testGenStandaloneContent,
        });
  });

  test('Generate standalone output file with custom header', () async {
    var srcs = _createPackageStub();
    var builder =
        new LibraryBuilder(const CommentGenerator(), header: _customHeader);
    await testBuilder(builder, srcs,
        generateFor: new Set.from(['$_pkgName|lib/test_lib.dart']),
        outputs: {
          '$_pkgName|lib/test_lib.g.dart':
              decodedMatches(startsWith('$_customHeader\n\n// ***'))
        });
  });

  test('LibraryBuilder omits header if provided an empty String', () async {
    var srcs = _createPackageStub();
    var builder = new LibraryBuilder(const CommentGenerator(), header: '');
    await testBuilder(builder, srcs,
        generateFor: new Set.from(['$_pkgName|lib/test_lib.dart']),
        outputs: {
          '$_pkgName|lib/test_lib.g.dart': decodedMatches(startsWith('// ***'))
        });
  });

  test('Expect no error when multiple generators used on nonstandalone builder',
      () async {
    expect(
        () =>
            new PartBuilder([const CommentGenerator(), const _NoOpGenerator()]),
        returnsNormally);
  });

  test('Allow no "library"  by default', () async {
    var sources = _createPackageStub(testLibContent: 'class A {}');
    var builder = new PartBuilder([const CommentGenerator()]);

    await testBuilder(builder, sources,
        outputs: {'$_pkgName|lib/test_lib.g.dart': _testGenNoLibrary});
  });

  test('Does not fail when there is no output', () async {
    var sources = _createPackageStub(testLibContent: 'class A {}');
    var builder = new PartBuilder([const CommentGenerator(forClasses: false)]);
    await testBuilder(builder, sources, outputs: {});
  });

  test('Use new part syntax when no library directive exists', () async {
    var sources = _createPackageStub(testLibContent: 'class A {}');
    var builder = new PartBuilder([const CommentGenerator()]);
    await testBuilder(builder, sources,
        outputs: {'$_pkgName|lib/test_lib.g.dart': _testGenNoLibrary});
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
    var srcs = _createPackageStub();
    var builder = new PartBuilder([const _NoOpGenerator()]);
    await testBuilder(builder, srcs, outputs: {});
  });

  test('handle generator errors well', () async {
    var srcs = _createPackageStub(testLibContent: _testLibContentWithError);
    var builder = new PartBuilder([const CommentGenerator()]);
    await testBuilder(builder, srcs,
        generateFor: new Set.from(['$_pkgName|lib/test_lib.dart']),
        outputs: {
          '$_pkgName|lib/test_lib.g.dart': _testGenPartContentError,
        });
  });

  test('warns when a non-standalone builder does not see "part"', () async {
    var srcs = _createPackageStub(testLibContent: _testLibContentNoPart);
    var builder = new PartBuilder([const CommentGenerator()]);
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
    await testBuilder(new PartBuilder([const UnformattedCodeGenerator()]),
        {'$_pkgName|lib/a.dart': 'library a; part "a.part.dart";'},
        generateFor: new Set.from(['$_pkgName|lib/a.dart']),
        outputs: {
          '$_pkgName|lib/a.g.dart':
              decodedMatches(contains(UnformattedCodeGenerator.formattedCode)),
        });
  });

  test('PartBuilder uses a custom header when provided', () async {
    await testBuilder(
        new PartBuilder([const UnformattedCodeGenerator()],
            header: _customHeader),
        {'$_pkgName|lib/a.dart': 'library a; part "a.part.dart";'},
        generateFor: new Set.from(['$_pkgName|lib/a.dart']),
        outputs: {
          '$_pkgName|lib/a.g.dart':
              decodedMatches(startsWith('$_customHeader\npart of')),
        });
  });

  test('PartBuilder includes no header when `header` is empty', () async {
    await testBuilder(
        new PartBuilder([const UnformattedCodeGenerator()], header: ''),
        {'$_pkgName|lib/a.dart': 'library a; part "a.part.dart";'},
        generateFor: new Set.from(['$_pkgName|lib/a.dart']),
        outputs: {
          '$_pkgName|lib/a.g.dart': decodedMatches(startsWith('part of')),
        });
  });

  test('can skip formatting with a trivial lambda', () async {
    await testBuilder(
        new PartBuilder([const UnformattedCodeGenerator()],
            formatOutput: (s) => s),
        {'$_pkgName|lib/a.dart': 'library a; part "a.part.dart";'},
        generateFor: new Set.from(['$_pkgName|lib/a.dart']),
        outputs: {
          '$_pkgName|lib/a.g.dart': decodedMatches(
              contains(UnformattedCodeGenerator.unformattedCode)),
        });
  });

  test('can pass a custom formatter with formatOutput', () async {
    var customOutput = 'final String hello = "hello";';
    await testBuilder(
        new PartBuilder([const UnformattedCodeGenerator()],
            formatOutput: (_) => customOutput),
        {'$_pkgName|lib/a.dart': 'library a; part "a.part.dart";'},
        generateFor: new Set.from(['$_pkgName|lib/a.dart']),
        outputs: {
          '$_pkgName|lib/a.g.dart': decodedMatches(contains(customOutput)),
        });
  });

  test('Should have a readable toString() message for builders', () {
    final builder = new LibraryBuilder(const _NoOpGenerator());
    expect(builder.toString(), 'Generating .g.dart: NOOP');

    final builders = new PartBuilder([
      const _NoOpGenerator(),
      const _NoOpGenerator(),
    ]);
    expect(builders.toString(), 'Generating .g.dart: NOOP, NOOP');
  });
}

Future _generateTest(CommentGenerator gen, String expectedContent) async {
  var srcs = _createPackageStub();
  var builder = new PartBuilder([gen]);

  await testBuilder(builder, srcs,
      generateFor: new Set.from(['$_pkgName|lib/test_lib.dart']),
      outputs: {
        '$_pkgName|lib/test_lib.g.dart': decodedMatches(expectedContent),
      },
      onLog: (log) => fail('Unexpected log message: ${log.message}'));
}

Map<String, String> _createPackageStub(
    {String testLibContent, String testLibPartContent}) {
  return {
    '$_pkgName|lib/test_lib.dart': testLibContent ?? _testLibContent,
    '$_pkgName|lib/test_lib.g.dart': testLibPartContent ?? _testLibPartContent,
  };
}

/// Doesn't generate output for any element
class _NoOpGenerator extends Generator {
  const _NoOpGenerator();

  @override
  Future<String> generate(LibraryReader library, _) => null;

  @override
  String toString() => 'NOOP';
}

class _BadOutputGenerator extends Generator {
  const _BadOutputGenerator();

  @override
  Future<String> generate(LibraryReader library, _) async => 'not valid code!';
}

final _customHeader = '// Copyright 1979';

const _pkgName = 'pkg';

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
// **************************************************************************

// Code for "class Person"
// Code for "class Customer"
''';

const _testGenPartContentForLibrary =
    r'''// GENERATED CODE - DO NOT MODIFY BY HAND

part of test_lib;

// **************************************************************************
// Generator: CommentGenerator
// **************************************************************************

// Code for "test_lib"
''';

const _testGenStandaloneContent = r'''// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: CommentGenerator
// **************************************************************************

// Code for "class Person"
// Code for "class Customer"
''';

const _testGenPartContentForClassesAndLibrary =
    r'''// GENERATED CODE - DO NOT MODIFY BY HAND

part of test_lib;

// **************************************************************************
// Generator: CommentGenerator
// **************************************************************************

// Code for "test_lib"
// Code for "class Person"
// Code for "class Customer"
''';

const _testGenPartContentError = r'''// GENERATED CODE - DO NOT MODIFY BY HAND

part of test_lib;

// **************************************************************************
// Generator: CommentGenerator
// **************************************************************************

// Error: Don't use classes with the word 'Error' in the name
//        package:pkg/test_lib.dart:4:7
//        class MyGoodError { }
//              ^^^^^^^^^^^
// TODO: Rename MyGoodError to something else.
''';

const _testGenNoLibrary = r'''// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_lib.dart';

// **************************************************************************
// Generator: CommentGenerator
// **************************************************************************

// Code for "class A"
''';
