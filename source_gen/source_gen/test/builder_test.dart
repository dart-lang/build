// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/builder.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/builder.dart';
import 'package:test/test.dart';

import 'src/comment_generator.dart';
import 'src/unformatted_code_generator.dart';

void main() {
  tearDown(() {
    // Increment this after each test so the next test has it's own package
    _pkgCacheCount++;
  });
  test('Simple Generator test', () async {
    await _generateTest(const CommentGenerator(), _testGenPartContent);
  });

  test('Bad generated source', () async {
    final srcs = _createPackageStub();
    final builder = PartBuilder(
      [_StubGenerator('Bad', () => 'not valid code!')],
      '.foo.dart',
    );

    await testBuilder(
      builder,
      srcs,
      generateFor: {'$_pkgName|lib/test_lib.dart'},
      outputs: {
        '$_pkgName|lib/test_lib.foo.dart':
            decodedMatches(contains('not valid code!')),
      },
    );
  });

  test('Generate standalone output file', () async {
    final srcs = _createPackageStub();
    final builder = LibraryBuilder(const CommentGenerator());
    await testBuilder(
      builder,
      srcs,
      generateFor: {'$_pkgName|lib/test_lib.dart'},
      outputs: {
        '$_pkgName|lib/test_lib.g.dart': _testGenStandaloneContent,
      },
    );
  });

  test('Generate standalone output file with custom header', () async {
    final srcs = _createPackageStub();
    final builder =
        LibraryBuilder(const CommentGenerator(), header: _customHeader);
    await testBuilder(
      builder,
      srcs,
      generateFor: {'$_pkgName|lib/test_lib.dart'},
      outputs: {
        '$_pkgName|lib/test_lib.g.dart': decodedMatches(
          startsWith('$_customHeader\n$dartFormatWidth\n\n// ***'),
        ),
      },
    );
  });

  test('LibraryBuilder omits header if provided an empty String', () async {
    final srcs = _createPackageStub();
    final builder = LibraryBuilder(const CommentGenerator(), header: '');
    await testBuilder(
      builder,
      srcs,
      generateFor: {'$_pkgName|lib/test_lib.dart'},
      outputs: {
        '$_pkgName|lib/test_lib.g.dart':
            decodedMatches(startsWith('$dartFormatWidth\n\n// ***')),
      },
    );
  });

  test('Omits generated comments if writeDescriptions is explicitly false',
      () async {
    final srcs = _createPackageStub();

    // Explicitly empty header
    final builderEmptyHeader = LibraryBuilder(
      const CommentGenerator(),
      header: '',
      writeDescriptions: false,
    );

    const expected = '''
$dartFormatWidth
// Code for "class Person"
// Code for "class Customer"
''';

    await testBuilder(
      builderEmptyHeader,
      srcs,
      generateFor: {'$_pkgName|lib/test_lib.dart'},
      outputs: {
        '$_pkgName|lib/test_lib.g.dart': decodedMatches(startsWith(expected)),
      },
    );
  });

  test('When writeDescriptions is true, generated comments are present',
      () async {
    final srcs = _createPackageStub();

    // Null value for writeDescriptions resolves to true
    final builder = LibraryBuilder(
      const CommentGenerator(),
      // We omit header to inspect the generator descriptions
      header: '',
    );

    const expected = '''
// **************************************************************************
// CommentGenerator
// **************************************************************************
''';

    await testBuilder(
      builder,
      srcs,
      generateFor: {'$_pkgName|lib/test_lib.dart'},
      outputs: {
        '$_pkgName|lib/test_lib.g.dart': decodedMatches(contains(expected)),
      },
    );
  });

  test('Expect no error when multiple generators used on nonstandalone builder',
      () async {
    expect(
      () => PartBuilder(
        [const CommentGenerator(), _StubGenerator('Null', () => null)],
        '.foo.dart',
      ),
      returnsNormally,
    );
  });

  test('Does not fail when there is no output', () async {
    final sources = _createPackageStub(testLibContent: 'class A {}');
    final builder =
        PartBuilder([const CommentGenerator(forClasses: false)], '.foo.dart');
    await testBuilder(builder, sources, outputs: {});
  });

  test('Use new part syntax when no library directive exists', () async {
    final sources = _createPackageStub(
      testLibContent: _testLibContentNoLibrary,
      testLibPartContent: _testLibPartContentNoLibrary,
    );
    final builder = PartBuilder([const CommentGenerator()], '.foo.dart');
    await testBuilder(
      builder,
      sources,
      outputs: {'$_pkgName|lib/test_lib.foo.dart': _testGenNoLibrary},
    );
  });

  test(
    'Simple Generator test for library',
    () => _generateTest(
      const CommentGenerator(forClasses: false, forLibrary: true),
      _testGenPartContentForLibrary,
    ),
  );

  test(
    'Simple Generator test for classes and library',
    () => _generateTest(
      const CommentGenerator(forLibrary: true),
      _testGenPartContentForClassesAndLibrary,
    ),
  );

  test('null result produces no generated parts', () async {
    final srcs = _createPackageStub();
    final builder = _unformattedLiteral();
    await testBuilder(builder, srcs, outputs: {});
  });

  test('handle generator errors well', () async {
    final srcs = _createPackageStub(testLibContent: _testLibContentWithError);
    final builder = PartBuilder([const CommentGenerator()], '.foo.dart');

    await expectLater(
      () => testBuilder(
        builder,
        srcs,
        generateFor: {'$_pkgName|lib/test_lib.dart'},
      ),
      throwsA(
        isA<InvalidGenerationSourceError>().having(
          (source) => source.message,
          'message',
          "Don't use classes with the word 'Error' in the name",
        ),
      ),
    );
  });

  test(
      'throws when input library has syntax errors and allowSyntaxErrors '
      'flag is not set', () async {
    final srcs = _createPackageStub(testLibContent: _testLibContentSyntaxError);
    final builder = LibraryBuilder(const CommentGenerator());

    await expectLater(
      () => testBuilder(
        builder,
        srcs,
        generateFor: {'$_pkgName|lib/test_lib.dart'},
      ),
      throwsA(isA<SyntaxErrorInAssetException>()),
    );
  });

  test(
      'does not throw when input library has syntax errors and '
      'allowSyntaxErrors flag is set', () async {
    final srcs = _createPackageStub(testLibContent: _testLibContentSyntaxError);
    final builder =
        LibraryBuilder(const CommentGenerator(), allowSyntaxErrors: true);
    await testBuilder(
      builder,
      srcs,
      generateFor: {'$_pkgName|lib/test_lib.dart'},
    );
  });

  test('warns when a non-standalone builder does not see "part"', () async {
    final srcs = _createPackageStub(testLibContent: _testLibContentNoPart);
    final builder = PartBuilder([const CommentGenerator()], '.foo.dart');
    final logs = <String>[];
    await testBuilder(
      builder,
      srcs,
      onLog: (log) {
        logs.add(log.message);
      },
    );
    expect(logs, [
      'test_lib.foo.dart must be included as a part directive in the input '
          'library with:\n    part \'test_lib.foo.dart\';'
    ]);
  });

  test('generator with an empty result creates no outputs', () async {
    final srcs = _createPackageStub(testLibContent: _testLibContentNoPart);
    final builder = _unformattedLiteral('');
    await testBuilder(
      builder,
      srcs,
      outputs: {},
    );
  });

  test('generator with whitespace-only result has no outputs', () async {
    final srcs = _createPackageStub(testLibContent: _testLibContentNoPart);
    final builder = _unformattedLiteral('\n  \n');
    await testBuilder(
      builder,
      srcs,
      outputs: {},
    );
  });

  test('generator result with wrapping whitespace is trimmed', () async {
    final srcs = _createPackageStub(testLibContent: _testLibContent);
    final builder = _unformattedLiteral('\n// hello\n');
    await testBuilder(
      builder,
      srcs,
      outputs: {
        '$_pkgName|lib/test_lib.foo.dart': _whitespaceTrimmed,
      },
    );
  });

  test('defaults to formatting generated code with the DartFormatter',
      () async {
    await testBuilder(
      PartBuilder([const UnformattedCodeGenerator()], '.foo.dart'),
      {'$_pkgName|lib/a.dart': 'library a; part "a.foo.dart";'},
      generateFor: {'$_pkgName|lib/a.dart'},
      outputs: {
        '$_pkgName|lib/a.foo.dart':
            decodedMatches(contains(UnformattedCodeGenerator.formattedCode)),
      },
    );
  });

  group('PartBuilder', () {
    test('uses a custom header when provided', () async {
      await testBuilder(
        PartBuilder(
          [const UnformattedCodeGenerator()],
          '.foo.dart',
          header: _customHeader,
        ),
        {'$_pkgName|lib/a.dart': 'library a; part "a.foo.dart";'},
        generateFor: {'$_pkgName|lib/a.dart'},
        outputs: {
          '$_pkgName|lib/a.foo.dart': decodedMatches(
            startsWith('$_customHeader\n\n$dartFormatWidth\npart of'),
          ),
        },
      );
    });

    test('includes no header when `header` is empty', () async {
      await testBuilder(
        PartBuilder(
          [const UnformattedCodeGenerator()],
          '.foo.dart',
          header: '',
        ),
        {'$_pkgName|lib/a.dart': 'library a; part "a.foo.dart";'},
        generateFor: {'$_pkgName|lib/a.dart'},
        outputs: {
          '$_pkgName|lib/a.foo.dart':
              decodedMatches(startsWith('$dartFormatWidth\npart of')),
        },
      );
    });

    test('includes matching language version in all parts', () async {
      await testBuilder(
        PartBuilder(
          [const UnformattedCodeGenerator()],
          '.foo.dart',
          header: '',
        ),
        {
          '$_pkgName|lib/a.dart': '''
$dartFormatWidth
// @dart=2.12
part "a.foo.dart";''',
        },
        generateFor: {'$_pkgName|lib/a.dart'},
        outputs: {
          '$_pkgName|lib/a.foo.dart': decodedMatches(
            startsWith('$dartFormatWidth\n// @dart=2.12\n'),
          ),
        },
      );
    });

    test('warns about missing part', () async {
      final srcs = _createPackageStub(testLibContent: _testLibContentNoPart);
      final builder = PartBuilder([const CommentGenerator()], '.foo.dart');
      final logs = <String>[];
      await testBuilder(
        builder,
        srcs,
        onLog: (log) {
          logs.add(log.message);
        },
      );
      expect(logs, [
        'test_lib.foo.dart must be included as a part directive in the input '
            'library with:\n    part \'test_lib.foo.dart\';'
      ]);
    });

    group('with build_extensions', () {
      test('warns about missing part', () async {
        final srcs = _createPackageStub(testLibContent: _testLibContentNoPart);
        final builder = PartBuilder(
          [const CommentGenerator()],
          '.foo.dart',
          options: const BuilderOptions({
            'build_extensions': {
              '^lib/{{}}.dart': 'lib/generated/{{}}.foo.dart',
            },
          }),
        );
        final logs = <String>[];
        await testBuilder(
          builder,
          srcs,
          onLog: (log) {
            logs.add(log.message);
          },
        );
        expect(logs, [
          'generated/test_lib.foo.dart must be included as a '
              'part directive in the input library with:\n'
              '    part \'generated/test_lib.foo.dart\';'
        ]);
      });

      test('generates relative `path of` for output in different directory',
          () async {
        await testBuilder(
          PartBuilder(
            [const UnformattedCodeGenerator()],
            '.foo.dart',
            header: '',
            options: const BuilderOptions({
              'build_extensions': {
                '^lib/{{}}.dart': 'lib/generated/{{}}.foo.dart',
              },
            }),
          ),
          {'$_pkgName|lib/a.dart': 'part "generated/a.foo.dart";'},
          generateFor: {'$_pkgName|lib/a.dart'},
          outputs: {
            '$_pkgName|lib/generated/a.foo.dart': decodedMatches(
              startsWith("$dartFormatWidth\npart of '../a.dart';"),
            ),
          },
        );
      });

      test(
          'throws if `options` and `additionalOutputExtensions` are both given',
          () async {
        await expectLater(
          () => testBuilder(
            PartBuilder(
              [const UnformattedCodeGenerator()],
              '.foo.dart',
              additionalOutputExtensions: ['.bar.dart'],
              options: const BuilderOptions({
                'build_extensions': {
                  '^lib/{{}}.dart': 'lib/generated/{{}}.foo.dart',
                },
              }),
            ),
            {'$_pkgName|lib/a.dart': 'part "generated/a.foo.dart";'},
          ),
          throwsArgumentError,
        );
      });
    });
  });

  group('LibraryBuilder', () {
    group('with build_extensions', () {
      test('outputs to the correct location', () async {
        await testBuilder(
          LibraryBuilder(
            const CommentGenerator(),
            options: const BuilderOptions({
              'build_extensions': {
                '^lib/{{}}.dart': 'lib/generated/{{}}.g.dart',
              },
            }),
          ),
          _createPackageStub(),
          generateFor: {'$_pkgName|lib/test_lib.dart'},
          outputs: {
            '$_pkgName|lib/generated/test_lib.g.dart':
                _testGenStandaloneContent,
          },
        );
      });

      test(
          'throws if `options` and `additionalOutputExtensions` are both given',
          () async {
        await expectLater(
          () => testBuilder(
            LibraryBuilder(
              const CommentGenerator(),
              additionalOutputExtensions: ['.foo.dart'],
              options: const BuilderOptions({
                'build_extensions': {
                  '^lib/{{}}.dart': 'lib/generated/{{}}.foo.dart',
                },
              }),
            ),
            {'$_pkgName|lib/a.dart': 'part "generated/a.foo.dart";'},
          ),
          throwsArgumentError,
        );
      });
    });
  });

  group('SharedPartBuilder', () {
    test('outputs <partId>.g.part files', () async {
      await testBuilder(
        SharedPartBuilder(
          [const UnformattedCodeGenerator()],
          'foo',
        ),
        {'$_pkgName|lib/a.dart': 'library a; part "a.g.dart";'},
        generateFor: {'$_pkgName|lib/a.dart'},
        outputs: {
          '$_pkgName|lib/a.foo.g.part': decodedMatches(
            contains(UnformattedCodeGenerator.formattedCode),
          ),
        },
      );
    });

    test('does not output files which contain `part of`', () async {
      await testBuilder(
        SharedPartBuilder(
          [const UnformattedCodeGenerator()],
          'foo',
        ),
        {'$_pkgName|lib/a.dart': 'library a; part "a.g.dart";'},
        generateFor: {'$_pkgName|lib/a.dart'},
        outputs: {
          '$_pkgName|lib/a.foo.g.part':
              decodedMatches(isNot(contains('part of'))),
        },
      );
    });

    group('constructor', () {
      for (var entry in {
        'starts with `.`': '.foo',
        'ends with `.`': 'foo.',
        'is empty': '',
        'contains whitespace': 'coo bob',
        'contains symbols': '%oops',
        'contains . in the middle': 'cool.thing',
      }.entries) {
        test('throws if the partId ${entry.key}', () async {
          expect(
            () => SharedPartBuilder(
              [const UnformattedCodeGenerator()],
              entry.value,
            ),
            throwsArgumentError,
          );
        });
      }
    });
  });

  group('CombiningBuilder', () {
    test('includes a generated code header', () async {
      await testBuilder(
        const CombiningBuilder(),
        {
          '$_pkgName|lib/a.dart': 'library a; part "a.g.dart";',
          '$_pkgName|lib/a.foo.g.part': 'some generated content',
        },
        generateFor: {'$_pkgName|lib/a.dart'},
        outputs: {
          '$_pkgName|lib/a.g.dart': decodedMatches(
            startsWith('// GENERATED CODE - DO NOT MODIFY BY HAND'),
          ),
        },
      );
    });

    test('includes matching language version in all parts', () async {
      await testBuilder(
        const CombiningBuilder(),
        {
          '$_pkgName|lib/a.dart': '''
$dartFormatWidth
// @dart=2.12
library a;
part "a.g.dart";
''',
          '$_pkgName|lib/a.foo.g.part': 'some generated content',
        },
        generateFor: {'$_pkgName|lib/a.dart'},
        outputs: {
          '$_pkgName|lib/a.g.dart': decodedMatches(
            '''
// GENERATED CODE - DO NOT MODIFY BY HAND
$dartFormatWidth
// @dart=2.12

part of 'a.dart';

some generated content
''',
          ),
        },
      );
    });

    test('outputs `.g.dart` files', () async {
      await testBuilder(
        const CombiningBuilder(),
        {
          '$_pkgName|lib/a.dart': 'library a; part "a.g.dart";',
          '$_pkgName|lib/a.foo.g.part': 'some generated content',
        },
        generateFor: {'$_pkgName|lib/a.dart'},
        outputs: {
          '$_pkgName|lib/a.g.dart':
              decodedMatches(endsWith('some generated content\n')),
        },
      );
    });

    test('outputs contain `part of`', () async {
      await testBuilder(
        const CombiningBuilder(),
        {
          '$_pkgName|lib/a.dart': 'library a; part "a.g.dart";',
          '$_pkgName|lib/a.foo.g.part': 'some generated content',
        },
        generateFor: {'$_pkgName|lib/a.dart'},
        outputs: {
          '$_pkgName|lib/a.g.dart': decodedMatches(contains('part of')),
        },
      );
    });

    test('joins part files', () async {
      await testBuilder(
        const CombiningBuilder(),
        {
          '$_pkgName|lib/a.dart': 'library a; part "a.g.dart";',
          '$_pkgName|lib/a.foo.g.part': 'foo generated content',
          '$_pkgName|lib/a.bar.g.part': 'bar generated content',
        },
        generateFor: {'$_pkgName|lib/a.dart'},
        outputs: {
          '$_pkgName|lib/a.g.dart': decodedMatches(
            endsWith('\n\nbar generated content\n\nfoo generated content\n'),
          ),
        },
      );
    });

    test('joins only associated part files', () async {
      await testBuilder(
        const CombiningBuilder(),
        {
          '$_pkgName|lib/a.dart': 'library a; part "a.g.dart";',
          '$_pkgName|lib/a.foo.g.part': 'foo generated content',
          '$_pkgName|lib/a.bar.g.part': 'bar generated content',
          '$_pkgName|lib/a.bar.other.g.part': 'bar.other generated content',
        },
        generateFor: {'$_pkgName|lib/a.dart'},
        outputs: {
          '$_pkgName|lib/a.g.dart': decodedMatches(
            endsWith('bar generated content\n\nfoo generated content\n'),
          ),
        },
      );
    });

    test('outputs nothing if no part files are found', () async {
      await testBuilder(
        const CombiningBuilder(),
        {
          '$_pkgName|lib/a.dart': 'library a; part "a.g.dart";',
        },
        generateFor: {'$_pkgName|lib/a.dart'},
        outputs: {},
      );
    });

    test('trims part content and skips empty and whitespace-only parts',
        () async {
      await testBuilder(
        const CombiningBuilder(),
        {
          '$_pkgName|lib/a.dart': 'library a; part "a.g.dart";',
          '$_pkgName|lib/a.foo.g.part': '\n\nfoo generated content\n',
          '$_pkgName|lib/a.only_whitespace.g.part': '\n\n\t  \n \n',
          '$_pkgName|lib/a.bar.g.part': '\nbar generated content',
        },
        generateFor: {'$_pkgName|lib/a.dart'},
        outputs: {
          '$_pkgName|lib/a.g.dart': decodedMatches(
            endsWith('\n\nbar generated content\n\nfoo generated content\n'),
          ),
        },
      );
    });

    test('includes part header if enabled', () async {
      await testBuilder(
        const CombiningBuilder(includePartName: true),
        {
          '$_pkgName|lib/a.dart': 'library a; part "a.g.dart";',
          '$_pkgName|lib/a.foo.g.part': '\n\nfoo generated content\n',
          '$_pkgName|lib/a.only_whitespace.g.part': '\n\n\t  \n \n',
          '$_pkgName|lib/a.bar.g.part': '\nbar generated content',
        },
        generateFor: {'$_pkgName|lib/a.dart'},
        outputs: {
          '$_pkgName|lib/a.g.dart': decodedMatches(
            endsWith(
              '\n\n'
              '// Part: a.bar.g.part\n'
              'bar generated content\n\n'
              '// Part: a.foo.g.part\n'
              'foo generated content\n\n'
              '// Part: a.only_whitespace.g.part\n\n',
            ),
          ),
        },
      );
    });

    test('includes ignore for file if enabled', () async {
      await testBuilder(
        const CombiningBuilder(
          ignoreForFile: {
            'lines_longer_than_80_chars',
            'prefer_expression_function_bodies',
          },
        ),
        {
          '$_pkgName|lib/a.dart': 'library a; part "a.g.dart";',
          '$_pkgName|lib/a.foo.g.part': '\n\nfoo generated content\n',
          '$_pkgName|lib/a.only_whitespace.g.part': '\n\n\t  \n \n',
          '$_pkgName|lib/a.bar.g.part': '\nbar generated content',
        },
        generateFor: {'$_pkgName|lib/a.dart'},
        outputs: {
          '$_pkgName|lib/a.g.dart': decodedMatches(
            endsWith(
              r'''
// ignore_for_file: lines_longer_than_80_chars, prefer_expression_function_bodies

part of 'a.dart';

bar generated content

foo generated content
''',
            ),
          ),
        },
      );
    });

    test('includes preamble if enabled', () async {
      await testBuilder(
        const CombiningBuilder(
          preamble: '''
// foo

// bar''',
        ),
        {
          '$_pkgName|lib/a.dart': 'library a; part "a.g.dart";',
          '$_pkgName|lib/a.foo.g.part': '\n\nfoo generated content\n',
          '$_pkgName|lib/a.only_whitespace.g.part': '\n\n\t  \n \n',
          '$_pkgName|lib/a.bar.g.part': '\nbar generated content',
        },
        generateFor: {'$_pkgName|lib/a.dart'},
        outputs: {
          '$_pkgName|lib/a.g.dart': decodedMatches(
            endsWith(
              r'''
// foo

// bar

part of 'a.dart';

bar generated content

foo generated content
''',
            ),
          ),
        },
      );
    });

    test('warns about missing part statement', () async {
      final logs = <String>[];
      await testBuilder(
        combiningBuilder(),
        {
          '$_pkgName|lib/a.dart': '',
          '$_pkgName|lib/a.foo.g.part': '// generated',
        },
        generateFor: {'$_pkgName|lib/a.dart'},
        onLog: (msg) => logs.add(msg.message),
        outputs: {},
      );

      expect(
        logs,
        contains(
          'a.g.dart must be included as a part directive in the input '
          'library with:\n    part \'a.g.dart\';',
        ),
      );
    });

    group('with custom extensions', () {
      test('generates relative `path of` for output in different directory',
          () async {
        await testBuilder(
          combiningBuilder(
            const BuilderOptions({
              'build_extensions': {
                '^lib/{{}}.dart': 'lib/generated/{{}}.g.dart',
              },
            }),
          ),
          {
            '$_pkgName|lib/a.dart': 'part "generated/a.g.dart";',
            '$_pkgName|lib/a.foo.g.part': '\n\nfoo generated content\n',
            '$_pkgName|lib/a.only_whitespace.g.part': '\n\n\t  \n \n',
            '$_pkgName|lib/a.bar.g.part': '\nbar generated content',
          },
          generateFor: {'$_pkgName|lib/a.dart'},
          outputs: {
            '$_pkgName|lib/generated/a.g.dart': decodedMatches(
              endsWith(
                r'''
part of '../a.dart';

bar generated content

foo generated content
''',
              ),
            ),
          },
        );
      });

      test('warns about missing part statement', () async {
        final logs = <String>[];
        await testBuilder(
          combiningBuilder(
            const BuilderOptions({
              'build_extensions': {
                '^lib/{{}}.dart': 'lib/generated/{{}}.g.dart',
              },
            }),
          ),
          {
            '$_pkgName|lib/a.dart': '',
            '$_pkgName|lib/a.foo.g.part': '// generated',
          },
          generateFor: {'$_pkgName|lib/a.dart'},
          onLog: (msg) => logs.add(msg.message),
          outputs: {},
        );

        expect(
          logs,
          contains(
            'generated/a.g.dart must be included as a part directive in the '
            'input library with:\n    part \'generated/a.g.dart\';',
          ),
        );
      });
    });

    test('supports the path with the glob quotes', () async {
      await testBuilder(
        const CombiningBuilder(),
        {
          '$_pkgName|lib/[a]/(b)/{c}/*d/-e/f.dart':
              'library f; part "f.g.dart";',
          '$_pkgName|lib/[a]/(b)/{c}/*d/-e/f.foo.g.part':
              'some generated content',
        },
        generateFor: {'$_pkgName|lib/[a]/(b)/{c}/*d/-e/f.dart'},
        outputs: {
          '$_pkgName|lib/[a]/(b)/{c}/*d/-e/f.g.dart': decodedMatches(
            startsWith('// GENERATED CODE - DO NOT MODIFY BY HAND'),
          ),
        },
      );
    });
  });

  test('can skip formatting with a trivial lambda', () async {
    await testBuilder(
      PartBuilder(
        [const UnformattedCodeGenerator()],
        '.foo.dart',
        formatOutput: (s, _) => s,
      ),
      {'$_pkgName|lib/a.dart': 'library a; part "a.foo.dart";'},
      generateFor: {'$_pkgName|lib/a.dart'},
      outputs: {
        '$_pkgName|lib/a.foo.dart': decodedMatches(
          contains(UnformattedCodeGenerator.unformattedCode),
        ),
      },
    );
  });

  test('can pass a custom formatter with formatOutput', () async {
    const customOutput = 'final String hello = "hello";';
    await testBuilder(
      PartBuilder(
        [const UnformattedCodeGenerator()],
        '.foo.dart',
        formatOutput: (_, __) => customOutput,
      ),
      {'$_pkgName|lib/a.dart': 'library a; part "a.foo.dart";'},
      generateFor: {'$_pkgName|lib/a.dart'},
      outputs: {
        '$_pkgName|lib/a.foo.dart': decodedMatches(contains(customOutput)),
      },
    );
  });

  test('Should have a readable toString() message for builders', () {
    final builder = LibraryBuilder(_StubGenerator('Null', () => null));
    expect(builder.toString(), 'Generating .g.dart: Null');

    final builders = PartBuilder(
      [
        _StubGenerator('Null', () => null),
        _StubGenerator('Null', () => null),
      ],
      '.foo.dart',
    );
    expect(builders.toString(), 'Generating .foo.dart: Null, Null');
  });

  test('Searches in part files for annotations', () async {
    final srcs = _createPackageStub(
      testLibContent: '''
    part 'test_lib.foo.dart';
    part 'test_lib.g.dart';
    ''',
      testLibPartContent: '''
    part of 'test_lib.dart';
    @deprecated
    int x;
    ''',
    );
    final builder =
        PartBuilder([DeprecatedGeneratorForAnnotation()], '.g.dart');

    await testBuilder(
      builder,
      srcs,
      generateFor: {'$_pkgName|lib/test_lib.dart'},
      outputs: {
        '$_pkgName|lib/test_lib.g.dart':
            decodedMatches(contains('// "int x" is deprecated!')),
      },
      onLog: (log) {
        if (log.message.contains(_outdatedAnalyzerMessage)) {
          // This may happen with pre-release SDKs. Not an error.
          return;
        }
        fail('Unexpected log message: ${log.message}');
      },
    );
  });
}

const _outdatedAnalyzerMessage =
    '`analyzer` version may not fully support your current SDK version.';

Future<void> _generateTest(CommentGenerator gen, String expectedContent) async {
  final srcs = _createPackageStub();
  final builder = PartBuilder([gen], '.foo.dart');

  await testBuilder(
    builder,
    srcs,
    generateFor: {'$_pkgName|lib/test_lib.dart'},
    outputs: {
      '$_pkgName|lib/test_lib.foo.dart': decodedMatches(expectedContent),
    },
    onLog: (log) {
      if (log.message.contains(_outdatedAnalyzerMessage) ||
          log.message.startsWith('Generating SDK summary')) {
        // This may happen with pre-release SDKs. Not an error.
        return;
      }
      fail('Unexpected log message: ${log.message}');
    },
  );
}

Map<String, String> _createPackageStub({
  String? testLibContent,
  String? testLibPartContent,
}) =>
    {
      '$_pkgName|lib/test_lib.dart': testLibContent ?? _testLibContent,
      '$_pkgName|lib/test_lib.foo.dart':
          testLibPartContent ?? _testLibPartContent,
    };

PartBuilder _unformattedLiteral([String? content]) => PartBuilder(
      [_StubGenerator('Literal', () => content)],
      '.foo.dart',
      formatOutput: (s, _) => s,
    );

class _StubGenerator implements Generator {
  final String _name;
  final FutureOr<String?> Function() _behavior;

  const _StubGenerator(this._name, this._behavior);

  @override
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) =>
      _behavior();

  @override
  String toString() => _name;
}

const _customHeader = '// Copyright 1979';

// Ensure every test gets its own unique package name
String get _pkgName => 'pkg$_pkgCacheCount';
int _pkgCacheCount = 1;

const _testLibContent = r'''
library test_lib;
part 'test_lib.foo.dart';
final int foo = 42;
class Person { }
''';

const _testLibContentNoLibrary = r'''
part 'test_lib.foo.dart';
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
part 'test_lib.foo.dart';
class MyError { }
class MyGoodError { }
''';

const _testLibPartContent = r'''
part of 'test_lib.dart';
final int bar = 42;
class Customer { }
''';

const _testLibPartContentNoLibrary = r'''
part of 'test_lib.dart';
final int bar = 42;
class Customer { }
''';

const _testLibContentSyntaxError = r'''
final int foo = 42
''';

const _testGenPartContent = r'''
// GENERATED CODE - DO NOT MODIFY BY HAND

// dart format width=80
part of 'test_lib.dart';

// **************************************************************************
// CommentGenerator
// **************************************************************************

// Code for "class Person"
// Code for "class Customer"
''';

const _testGenPartContentForLibrary = r'''
// GENERATED CODE - DO NOT MODIFY BY HAND

// dart format width=80
part of 'test_lib.dart';

// **************************************************************************
// CommentGenerator
// **************************************************************************

// Code for "test_lib"
''';

const _testGenStandaloneContent = r'''
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// CommentGenerator
// **************************************************************************

// Code for "class Person"
// Code for "class Customer"
''';

const _testGenPartContentForClassesAndLibrary = r'''
// GENERATED CODE - DO NOT MODIFY BY HAND

// dart format width=80
part of 'test_lib.dart';

// **************************************************************************
// CommentGenerator
// **************************************************************************

// Code for "test_lib"
// Code for "class Person"
// Code for "class Customer"
''';

const _testGenNoLibrary = r'''
// GENERATED CODE - DO NOT MODIFY BY HAND

// dart format width=80
part of 'test_lib.dart';

// **************************************************************************
// CommentGenerator
// **************************************************************************

// Code for "class Person"
// Code for "class Customer"
''';

const _whitespaceTrimmed = r'''
// GENERATED CODE - DO NOT MODIFY BY HAND

// dart format width=80
part of 'test_lib.dart';

// **************************************************************************
// Generator: Literal
// **************************************************************************

// hello
''';
