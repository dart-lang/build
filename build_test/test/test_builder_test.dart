// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';

Future<void> main() async {
  // Default logging uses `printOnFailure` which crashes outside tests; check
  // that it falls back to something else outside tests.
  await testBuilder(TestBuilder(), {'a|lib/a.dart': ''}, rootPackage: 'a');

  test('can glob files in the root package', () async {
    final assets = {
      'a|lib/a.globPlaceholder': '',
      'a|lib/a.txt': '',
      'a|lib/b.txt': '',
      'a|lib/c.txt': '',
      'a|lib/d.txt': '',
    };
    final expectedOutputs = {
      'a|lib/a.matchingFiles':
          'a|lib/a.txt\na|lib/b.txt\na|lib/c.txt\na|lib/d.txt',
    };
    await testBuilder(
      GlobbingBuilder(Glob('**.txt')),
      assets,
      rootPackage: 'a',
      outputs: expectedOutputs,
    );
  });

  test('can glob files in non-root and root packages', () async {
    final assets = {
      'a|lib/a.globPlaceholder': '',
      'a|lib/a.txt': '',
      'a|lib/b.txt': '',
      'b|lib/b.globPlaceholder': '',
      'b|lib/a.txt': '',
      'b|lib/b.txt': '',
      'b|lib/c.txt': '',
      'b|lib/d.txt': '',
    };
    final expectedOutputs = {
      'a|lib/a.matchingFiles': decodedMatches(
        allOf(contains('a|lib/a.txt'), contains('a|lib/b.txt')),
      ),
      'b|lib/b.matchingFiles': decodedMatches(
        'b|lib/a.txt\n'
        'b|lib/b.txt\n'
        'b|lib/c.txt\n'
        'b|lib/d.txt',
      ),
    };
    await testBuilder(
      GlobbingBuilder(Glob('**.txt')),
      assets,
      rootPackage: 'a',
      outputs: expectedOutputs,
    );
  });

  group('can output special placeholder outpout files', () {
    const placeholders = ['lib', 'web', 'test'];

    for (final dir in placeholders) {
      test('using the special "$dir" sset', () async {
        final assets = {
          'a|data/1.txt': '1',
          'a|data/2.txt': '2',
          'a|data/3.txt': '3',
        };

        final outputs = {'a|$dir/concat.txt': '1\n2\n3\n'};

        await testBuilder(
          _ConcatBuilder(dir),
          assets,
          rootPackage: 'a',
          outputs: outputs,
        );
      });
    }
  });

  test('can capture reportUnusedAssets calls', () async {
    final unusedInput = AssetId('a', 'lib/unused.txt');
    final recorded = <AssetId, Iterable<AssetId>>{};
    await testBuilder(
      TestBuilder(
        build: (BuildStep buildStep, _) async {
          if (!await buildStep.canRead(buildStep.inputId)) return;
          buildStep.reportUnusedAssets([unusedInput]);
        },
      ),
      {'a|lib/a.txt': 'a'},
      reportUnusedAssetsForInput: (input, unused) => recorded[input] = unused,
    );
    expect(
      recorded,
      equals({
        AssetId('a', 'lib/a.txt'): [unusedInput],
      }),
    );
  });

  test('can read own outputs', () {
    return testBuilder(
      TestBuilder(
        buildExtensions: {
          '.txt': ['.temp'],
        },
        build: (step, _) async {
          final input = step.inputId;
          final content = await step.readAsString(input);

          final tempOut = input.changeExtension('.temp');
          await step.writeAsString(tempOut, content.toUpperCase());

          final readOutput = await step.readAsString(tempOut);
          expect(readOutput, content.toUpperCase());
        },
      ),
      {'a|foo.txt': 'foo'},
    );
  });

  test("can't read outputs from other steps", () {
    return testBuilder(
      TestBuilder(
        buildExtensions: {
          '.txt': ['.temp'],
        },
        build: (step, _) async {
          final input = step.inputId;
          await step.writeAsString(input.changeExtension('.temp'), 'out');

          final outputFromOther =
              input.path.contains('foo')
                  ? AssetId('a', 'bar.temp')
                  : AssetId('a', 'foo.temp');

          expect(await step.canRead(outputFromOther), isFalse);
        },
      ),
      {'a|foo.txt': 'foo', 'a|bar.txt': 'foo'},
    );
  });

  test(
    'can resolve with specified language versions from a PackageConfig',
    () async {
      final packageConfig = PackageConfig([
        Package(
          'a',
          Uri.file('/a/'),
          packageUriRoot: Uri.file('/a/lib/'),
          languageVersion: LanguageVersion(2, 3),
        ),
      ]);

      await testBuilder(
        TestBuilder(
          buildExtensions: {
            '.dart': ['.fake'],
          },
          build: (step, _) async {
            expect(
              step.inputLibrary,
              throwsA(
                isA<SyntaxErrorInAssetException>().having(
                  (e) => e.syntaxErrors.first.message,
                  'message',
                  contains(
                    'This requires the \'extension-methods\' language '
                    'feature to be enabled.',
                  ),
                ),
              ),
            );
          },
        ),
        {'a|error.dart': '''extension _Foo on int {}'''},
        packageConfig: packageConfig,
      );
    },
  );

  test('inputs are tracked by primary input and builder label', () async {
    final result = await testBuilders(
      [
        _TestBuilder(
          buildExtensions: {
            '.dart': ['.o1'],
          },
          build: (step) async {
            await step.readAsString(step.inputId);
          },
        ),
        _TestBuilder(
          buildExtensions: {
            '.dart': ['.o2'],
          },
          build: (step) async {
            await step.canRead(step.inputId.changeExtension('.other'));
          },
          builderLabel: 'TestBuilderReadsOther',
        ),
      ],
      {'a|foo.dart': '', 'a|bar.dart': ''},
    );

    final testing = result.readerWriter.testing;

    expect(testing.inputsTracked, {
      AssetId('a', 'foo.dart'),
      AssetId('a', 'bar.dart'),
      AssetId('a', 'foo.other'),
      AssetId('a', 'bar.other'),
    });

    expect(testing.inputsTrackedFor(primaryInput: AssetId('a', 'foo.dart')), {
      AssetId('a', 'foo.dart'),
      AssetId('a', 'foo.other'),
    });
    expect(testing.inputsTrackedFor(primaryInput: AssetId('a', 'bar.dart')), {
      AssetId('a', 'bar.dart'),
      AssetId('a', 'bar.other'),
    });

    expect(
      testing.inputsTrackedFor(
        primaryInput: AssetId('a', 'bar.dart'),
        builderLabel: 'TestBuilder',
      ),
      {AssetId('a', 'bar.dart')},
    );

    expect(testing.inputsTrackedFor(builderLabel: 'TestBuilderReadsOther'), {
      AssetId('a', 'foo.other'),
      AssetId('a', 'bar.other'),
    });

    expect(
      testing.inputsTrackedFor(
        primaryInput: AssetId('a', 'bar.dart'),
        builderLabel: 'TestBuilderReadsOther',
      ),
      {AssetId('a', 'bar.other')},
    );
  });

  test('resolve entrypoints are tracked by primary input and '
      'builder label', () async {
    final result = await testBuilders(
      [
        _TestBuilder(
          buildExtensions: {
            '.dart': ['.o1'],
          },
          build: (step) async {
            await step.resolver.libraryFor(step.inputId);
          },
        ),
        _TestBuilder(
          buildExtensions: {
            '.dart': ['.o2'],
          },
          build: (step) async {
            await step.resolver.libraryFor(
              step.inputId.changeExtension('.other'),
            );
          },
          builderLabel: 'TestBuilderReadsOther',
        ),
      ],
      {
        'a|foo.dart': '',
        'a|bar.dart': '',
        'a|foo.other': '',
        'a|bar.other': '',
      },
    );

    final testing = result.readerWriter.testing;

    expect(testing.resolverEntrypointsTracked, {
      AssetId('a', 'foo.dart'),
      AssetId('a', 'bar.dart'),
      AssetId('a', 'foo.other'),
      AssetId('a', 'bar.other'),
    });

    expect(
      testing.resolverEntrypointsTrackedFor(
        primaryInput: AssetId('a', 'foo.dart'),
      ),
      {AssetId('a', 'foo.dart'), AssetId('a', 'foo.other')},
    );
    expect(
      testing.resolverEntrypointsTrackedFor(
        primaryInput: AssetId('a', 'bar.dart'),
      ),
      {AssetId('a', 'bar.dart'), AssetId('a', 'bar.other')},
    );

    expect(
      testing.resolverEntrypointsTrackedFor(
        primaryInput: AssetId('a', 'bar.dart'),
        builderLabel: 'TestBuilder',
      ),
      {AssetId('a', 'bar.dart')},
    );

    expect(
      testing.resolverEntrypointsTrackedFor(
        builderLabel: 'TestBuilderReadsOther',
      ),
      {AssetId('a', 'foo.other'), AssetId('a', 'bar.other')},
    );

    expect(
      testing.resolverEntrypointsTrackedFor(
        primaryInput: AssetId('a', 'bar.dart'),
        builderLabel: 'TestBuilderReadsOther',
      ),
      {AssetId('a', 'bar.other')},
    );
  });

  test('pre-existing output is replaced by new generated output', () {
    return testBuilder(
      TestBuilder(
        buildExtensions: {
          '.in': ['.out'],
        },
      ),
      {'a|foo.in': 'new input', 'a|foo.out': 'pre-existing output'},
      outputs: {'a|foo.out': 'new input'},
    );
  });

  test('input paths are not parsed as globs', () {
    return testBuilder(
      TestBuilder(
        buildExtensions: {
          '.in': ['.out'],
        },
      ),
      {'a|[.in': 'input'},
      outputs: {'a|[.out': 'input'},
    );
  });

  test('resolve isolate source', () async {
    final readerWriter = TestReaderWriter(rootPackage: 'a');
    await readerWriter.testing.loadIsolateSources();
    final logs = <String>[];
    await testBuilders(
      [
        TestBuilder(
          build: (buildStep, _) async {
            await buildStep.resolver.libraryFor(
              AssetId('glob', 'lib/glob.dart'),
            );
            await buildStep.writeAsString(
              buildStep.inputId.changeExtension('.g.dart'),
              '',
            );
          },
          buildExtensions: {
            '.dart': ['.g.dart'],
          },
        ),
      ],
      {
        'test_package|lib/a.dart': '''
import 'package:glob/glob.dart';
''',
      },
      readerWriter: readerWriter,
      onLog: (record) {
        if (record.level == Level.SEVERE) {
          logs.add(record.toString());
        }
      },
      outputs: {'test_package|lib/a.g.dart': ''},
    );
    expect(logs, isEmpty);
  });

  test('info messages are not logged, warnings are', () async {
    final logs = <String>[];
    await testBuilders(
      [
        TestBuilder(
          build: (buildStep, _) async {
            log.info('not logged by default');
            log.warning('is logged by default');
          },
          buildExtensions: {
            '.dart': ['.g.dart'],
          },
        ),
      ],
      {'test_package|lib/a.dart': ''},
      onLog: (record) {
        logs.add(record.toString());
      },
    );
    expect(logs.join('\n'), isNot(contains('not logged by default')));
    expect(logs.join('\n'), contains('is logged by default'));
  });

  test('info messages are logged if `verbose`', () async {
    final logs = <String>[];
    await testBuilders(
      [
        TestBuilder(
          build: (buildStep, _) async {
            log.info('is now logged');
          },
          buildExtensions: {
            '.dart': ['.g.dart'],
          },
        ),
      ],
      {'test_package|lib/a.dart': ''},
      onLog: (record) {
        logs.add(record.toString());
      },
      verbose: true,
    );
    expect(logs.join('\n'), contains('is now logged'));
  });

  test('severe messages are logged and returned as errors', () async {
    final logs = <String>[];
    final result = await testBuilders(
      [
        TestBuilder(
          build: (buildStep, _) async {
            log.severe('some error');
          },
          buildExtensions: {
            '.dart': ['.g.dart'],
          },
        ),
      ],
      {'test_package|lib/a.dart': ''},
      onLog: (record) {
        if (record.level == Level.SEVERE) logs.add(record.toString());
      },
    );
    expect(logs.join('\n'), contains('some error'));
    expect(result.errors.join('\n'), contains('some error'));
  });

  test('exceptions are logged and returned as errors', () async {
    final logs = <String>[];
    final result = await testBuilders(
      [
        TestBuilder(
          build: (buildStep, _) async {
            throw Exception('some exception');
          },
          buildExtensions: {
            '.dart': ['.g.dart'],
          },
        ),
      ],
      {'test_package|lib/a.dart': ''},
      onLog: (record) {
        if (record.level == Level.SEVERE) logs.add(record.toString());
      },
    );
    expect(logs.join('\n'), contains('Exception: some exception'));
    expect(result.errors.join('\n'), contains('Exception: some exception'));
  });

  test('restricts inputs to `generateFor`', () {
    return testBuilder(
      TestBuilder(),
      {'a|a.txt': '', 'a|b.txt': ''},
      generateFor: {'a|a.txt'},
      outputs: {'a|a.txt.copy': ''},
    );
  });

  test('output is under `.dart_tool` by default', () async {
    final result = await testBuilder(
      TestBuilder(),
      {'a|a.txt': ''},
      outputs: {'a|a.txt.copy': ''},
    );
    expect(
      result.readerWriter.testing.assets,
      contains(AssetId('a', '.dart_tool/build/generated/a/a.txt.copy')),
    );
  });

  test('output is flattened with `flattenOutput`', () async {
    final result = await testBuilder(
      TestBuilder(),
      {'a|a.txt': ''},
      outputs: {'a|a.txt.copy': ''},
      flattenOutput: true,
    );
    expect(
      result.readerWriter.testing.assets,
      contains(AssetId('a', 'a.txt.copy')),
    );
  });
}

/// Concatenates the contents of multiple text files into a single output.
class _ConcatBuilder implements Builder {
  final String _input;

  _ConcatBuilder(this._input)
    : buildExtensions = {
        '\$$_input\$': ['concat.txt'],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final results = StringBuffer();
    await for (final asset in buildStep.findAssets(Glob('data/*.txt'))) {
      results.writeln(await buildStep.readAsString(asset));
    }
    final output = AssetId(buildStep.inputId.package, '$_input/concat.txt');
    await buildStep.writeAsString(output, results.toString());
  }

  @override
  Map<String, List<String>> buildExtensions;
}

// Like [TestBuilder], but no default behavior and buildLabel can be overridden.
class _TestBuilder implements Builder {
  @override
  final Map<String, List<String>> buildExtensions;
  final Future<void> Function(BuildStep) _build;
  final String builderLabel;

  _TestBuilder({
    required this.buildExtensions,
    required Future<void> Function(BuildStep) build,
    String? builderLabel,
  }) : _build = build,
       builderLabel = builderLabel ?? 'TestBuilder';

  @override
  Future<void> build(BuildStep buildStep) => _build(buildStep);

  @override
  String toString() => builderLabel;
}
