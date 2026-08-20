import 'package:build/build.dart';
import 'package:build_runner/src/build_plan/builder_definition.dart';
import 'package:build_runner/src/build_plan/builder_factories.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';

import '../common/common.dart';

class PartWritingBuilder implements Builder {
  final String _content;
  final String _readFile;
  final String _extension;

  PartWritingBuilder(this._content, this._readFile, this._extension);

  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': [_extension],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final readId = AssetId('a', _readFile);
    final text = await buildStep.canRead(readId)
        ? await buildStep.readAsString(readId)
        : 'missing';
    final writer = await buildStep.librarySourceSink;
    writer
      ?..addImport('package:a/b.dart', as: '${writer.importPrefix}b')
      ..add('// builder saw: $text\n$_content');
  }
}

class PartReadingAndWritingBuilder implements Builder {
  final String _content;
  final String _readFile;
  final String _extension;

  PartReadingAndWritingBuilder(this._content, this._readFile, this._extension);

  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': [_extension],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final readId = AssetId('a', _readFile);
    final text = await buildStep.canRead(readId)
        ? await buildStep.readAsString(readId)
        : 'missing';
    final brId = AssetId('a', 'lib/_br_/a.dart');
    final brText = await buildStep.canRead(brId)
        ? await buildStep.readAsString(brId)
        : 'missing';
    final sawLaterContribution = brText.contains('content2');
    final writer = await buildStep.librarySourceSink;
    writer
      ?..addImport('package:a/b.dart', as: '${writer.importPrefix}b')
      ..add(
        '// builder saw: $text\n// saw later contribution: $sawLaterContribution\n$_content',
      );
  }
}

class OptionalPartWritingBuilder implements Builder {
  final String _content;
  final String _readFile;
  final String _extension;

  OptionalPartWritingBuilder(this._content, this._readFile, this._extension);

  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': [_extension],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final readId = AssetId('a', _readFile);
    final text = await buildStep.canRead(readId)
        ? await buildStep.readAsString(readId)
        : 'missing';
    if (text == 'skip') return;
    final writer = await buildStep.librarySourceSink;
    writer
      ?..addImport('package:a/b.dart', as: '${writer.importPrefix}b')
      ..add('// builder saw: $text\n$_content');
  }
}

class PartResolvingAndWritingBuilder implements Builder {
  final String _readFile;
  final String _extension;

  PartResolvingAndWritingBuilder(this._readFile, this._extension);

  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': [_extension],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final readId = AssetId('a', _readFile);
    final text = await buildStep.canRead(readId)
        ? await buildStep.readAsString(readId)
        : 'missing';
    final lib = await buildStep.inputLibrary;
    final sawClass2 = lib.getClass('Class2') != null;
    final writer = await buildStep.librarySourceSink;
    writer?.add(
      '// builder saw: $text\nclass Class1 {\n  // sawClass2: $sawClass2\n}\n',
    );
  }
}

class PartClassWritingBuilder implements Builder {
  final String _content;
  final String _readFile;
  final String _extension;

  PartClassWritingBuilder(this._content, this._readFile, this._extension);

  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': [_extension],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final readId = AssetId('a', _readFile);
    final text = await buildStep.canRead(readId)
        ? await buildStep.readAsString(readId)
        : 'missing';
    final writer = await buildStep.librarySourceSink;
    writer?.add('// builder saw: $text\n$_content');
  }
}

String _formatGolden(String raw) {
  String formatted;
  try {
    formatted = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format(raw);
  } catch (_) {
    formatted = raw;
  }
  if (formatted.startsWith('// @dart=')) {
    final languageVersion = formatted.substring(0, formatted.indexOf('\n'));
    return formatted.replaceFirst(
      languageVersion,
      '$languageVersion\n// dart format off',
    );
  }
  return '// dart format off\n$formatted';
}

class ThrowingPrefixBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': ['.g.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final writer = await buildStep.librarySourceSink;
    expect(
      () => writer?.addImport('package:a/b.dart', as: 'wrong_prefix'),
      throwsA(isA<ArgumentError>()),
    );
    writer?.add('foo');
  }
}

class EmptyPartWritingBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': ['.empty.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final writer = await buildStep.librarySourceSink;
    writer?.addImport('package:a/b.dart', as: '${writer.importPrefix}b');
  }
}

void main() {
  group('Part Builders incremental build', () {
    test('updates generated part file correctly', () async {
      final builderFactories = BuilderFactories({
        'a:builder1': [
          (_) => PartWritingBuilder('content1', 'lib/b.txt', '.b1.dart'),
        ],
        'a:builder2': [
          (_) => PartWritingBuilder('content2', 'lib/c.txt', '.b2.dart'),
        ],
      });
      final builderDefinitions = [
        BuilderDefinition(
          'a:builder1',
          hideOutput: false,
          autoApply: AutoApply.allPackages,
          addsToLibrary: true,
        ),
        BuilderDefinition(
          'a:builder2',
          hideOutput: false,
          autoApply: AutoApply.allPackages,
          addsToLibrary: true,
        ),
      ];

      // Initial build.
      // Expected generated part combines imports and content from both.
      final expectedGeneratedPart = _formatGolden('''
part of '../a.dart';

// @PartBuilder:imports:0
import 'package:a/b.dart' as \$ab;
// @PartBuilder:imports:1
import 'package:a/b.dart' as \$bb;

// @PartBuilder:contribution:0
// builder saw: initial_b
content1

// @PartBuilder:contribution:1
// builder saw: initial_c
content2

''');

      final result1 = await testPhases(
        builderFactories,
        builderDefinitions,
        {
          'a|lib/a.dart': '',
          'a|lib/b.txt': 'initial_b',
          'a|lib/c.txt': 'initial_c',
        },
        outputs: {'a|lib/_br_/a.dart': expectedGeneratedPart},
      );

      // Now we do an incremental build where we ONLY change b.txt.
      // builder1 will run again, builder2 will be cached.
      final expectedGeneratedPart2 = _formatGolden('''
part of '../a.dart';

// @PartBuilder:imports:0
import 'package:a/b.dart' as \$ab;
// @PartBuilder:imports:1
import 'package:a/b.dart' as \$bb;

// @PartBuilder:contribution:0
// builder saw: modified_b
content1

// @PartBuilder:contribution:1
// builder saw: initial_c
content2

''');

      await testPhases(
        builderFactories,
        builderDefinitions,
        {
          'a|lib/a.dart': '',
          'a|lib/b.txt': 'modified_b',
          'a|lib/c.txt': 'initial_c',
        },
        outputs: {'a|lib/_br_/a.dart': expectedGeneratedPart2},
        resumeFrom: result1,
      );
    });

    test(
      'preserves language version comments from the primary input',
      () async {
        final builderFactories = BuilderFactories({
          'a:builder1': [
            (_) => PartWritingBuilder('content', 'lib/b.txt', '.b.dart'),
          ],
        });
        final builderDefinitions = [
          BuilderDefinition(
            'a:builder1',
            hideOutput: false,
            autoApply: AutoApply.allPackages,
            addsToLibrary: true,
          ),
        ];

        final expectedGeneratedPart = _formatGolden('''
// @dart=2.14
part of '../a.dart';

// @PartBuilder:imports:0
import 'package:a/b.dart' as \$ab;

// @PartBuilder:contribution:0
// builder saw: b
content

''');

        await testPhases(
          builderFactories,
          builderDefinitions,
          {'a|lib/a.dart': '// @dart=2.14\n', 'a|lib/b.txt': 'b'},
          outputs: {'a|lib/_br_/a.dart': expectedGeneratedPart},
        );
      },
    );

    test('throws if addImport uses incorrect prefix', () async {
      final builderFactories = BuilderFactories({
        '.dart': [(_) => ThrowingPrefixBuilder()],
      });
      final builderDefinitions = [
        BuilderDefinition(
          'a:builder1',
          hideOutput: false,
          autoApply: AutoApply.allPackages,
          addsToLibrary: true,
        ),
      ];

      await testPhases(builderFactories, builderDefinitions, {
        'a|lib/a.dart': '// @dart=2.14\n',
      });
    });

    test('earlier phase builder does not see later phase part '
        'contribution in incremental build', () async {
      final builderFactories = BuilderFactories({
        'a:builder1': [
          (_) =>
              PartReadingAndWritingBuilder('content1', 'lib/b.txt', '.b1.dart'),
        ],
        'a:builder2': [
          (_) => PartWritingBuilder('content2', 'lib/c.txt', '.b2.dart'),
        ],
      });
      final builderDefinitions = [
        BuilderDefinition(
          'a:builder1',
          hideOutput: false,
          autoApply: AutoApply.allPackages,
          addsToLibrary: true,
        ),
        BuilderDefinition(
          'a:builder2',
          hideOutput: false,
          autoApply: AutoApply.allPackages,
          addsToLibrary: true,
        ),
      ];

      final expectedGeneratedPart1 = _formatGolden('''
part of '../a.dart';

// @PartBuilder:imports:0
import 'package:a/b.dart' as \$ab;
// @PartBuilder:imports:1
import 'package:a/b.dart' as \$bb;

// @PartBuilder:contribution:0
// builder saw: initial_b
// saw later contribution: false
content1

// @PartBuilder:contribution:1
// builder saw: initial_c
content2

''');

      final result1 = await testPhases(
        builderFactories,
        builderDefinitions,
        {
          'a|lib/a.dart': '',
          'a|lib/b.txt': 'initial_b',
          'a|lib/c.txt': 'initial_c',
        },
        outputs: {'a|lib/_br_/a.dart': expectedGeneratedPart1},
      );

      final expectedGeneratedPart2 = _formatGolden('''
part of '../a.dart';

// @PartBuilder:imports:0
import 'package:a/b.dart' as \$ab;
// @PartBuilder:imports:1
import 'package:a/b.dart' as \$bb;

// @PartBuilder:contribution:0
// builder saw: modified_b
// saw later contribution: false
content1

// @PartBuilder:contribution:1
// builder saw: initial_c
content2

''');

      await testPhases(
        builderFactories,
        builderDefinitions,
        {
          'a|lib/a.dart': '',
          'a|lib/b.txt': 'modified_b',
          'a|lib/c.txt': 'initial_c',
        },
        outputs: {'a|lib/_br_/a.dart': expectedGeneratedPart2},
        resumeFrom: result1,
      );
    });

    test('removes part contribution when builder stops writing one '
        'in incremental build', () async {
      final builderFactories = BuilderFactories({
        'a:builder1': [
          (_) => PartWritingBuilder('content1', 'lib/b.txt', '.b1.dart'),
        ],
        'a:builder2': [
          (_) =>
              OptionalPartWritingBuilder('content2', 'lib/c.txt', '.b2.dart'),
        ],
      });
      final builderDefinitions = [
        BuilderDefinition(
          'a:builder1',
          hideOutput: false,
          autoApply: AutoApply.allPackages,
          addsToLibrary: true,
        ),
        BuilderDefinition(
          'a:builder2',
          hideOutput: false,
          autoApply: AutoApply.allPackages,
          addsToLibrary: true,
        ),
      ];

      final expectedGeneratedPart1 = _formatGolden('''
part of '../a.dart';

// @PartBuilder:imports:0
import 'package:a/b.dart' as \$ab;
// @PartBuilder:imports:1
import 'package:a/b.dart' as \$bb;

// @PartBuilder:contribution:0
// builder saw: initial_b
content1

// @PartBuilder:contribution:1
// builder saw: initial_c
content2

''');

      final result1 = await testPhases(
        builderFactories,
        builderDefinitions,
        {
          'a|lib/a.dart': '',
          'a|lib/b.txt': 'initial_b',
          'a|lib/c.txt': 'initial_c',
        },
        outputs: {'a|lib/_br_/a.dart': expectedGeneratedPart1},
      );

      final expectedGeneratedPart2 = _formatGolden('''
part of '../a.dart';

// @PartBuilder:imports:0
import 'package:a/b.dart' as \$ab;

// @PartBuilder:contribution:0
// builder saw: initial_b
content1

''');

      await testPhases(
        builderFactories,
        builderDefinitions,
        {'a|lib/a.dart': '', 'a|lib/b.txt': 'initial_b', 'a|lib/c.txt': 'skip'},
        outputs: {'a|lib/_br_/a.dart': expectedGeneratedPart2},
        resumeFrom: result1,
      );
    });

    test(
      'earlier phase builder resolving library does not see later phase part '
      'contribution in incremental build',
      () async {
        final builderFactories = BuilderFactories({
          'a:builder1': [
            (_) => PartResolvingAndWritingBuilder('lib/b.txt', '.b1.dart'),
          ],
          'a:builder2': [
            (_) => PartClassWritingBuilder(
              'class Class2 {}',
              'lib/c.txt',
              '.b2.dart',
            ),
          ],
        });
        final builderDefinitions = [
          BuilderDefinition(
            'a:builder1',
            hideOutput: false,
            autoApply: AutoApply.allPackages,
            addsToLibrary: true,
          ),
          BuilderDefinition(
            'a:builder2',
            hideOutput: false,
            autoApply: AutoApply.allPackages,
            addsToLibrary: true,
          ),
        ];

        final expectedGeneratedPart1 = _formatGolden('''
part of '../a.dart';

// @PartBuilder:contribution:0
// builder saw: initial_b
class Class1 {
  // sawClass2: false
}


// @PartBuilder:contribution:1
// builder saw: initial_c
class Class2 {}

''');

        final result1 = await testPhases(
          builderFactories,
          builderDefinitions,
          {
            'a|lib/a.dart': 'part \'_br_/a.dart\';\n',
            'a|lib/b.txt': 'initial_b',
            'a|lib/c.txt': 'initial_c',
          },
          outputs: {'a|lib/_br_/a.dart': expectedGeneratedPart1},
        );

        final expectedGeneratedPart2 = _formatGolden('''
part of '../a.dart';

// @PartBuilder:contribution:0
// builder saw: modified_b
class Class1 {
  // sawClass2: false
}


// @PartBuilder:contribution:1
// builder saw: initial_c
class Class2 {}

''');

        await testPhases(
          builderFactories,
          builderDefinitions,
          {
            'a|lib/a.dart': 'part \'_br_/a.dart\';\n',
            'a|lib/b.txt': 'modified_b',
            'a|lib/c.txt': 'initial_c',
          },
          outputs: {'a|lib/_br_/a.dart': expectedGeneratedPart2},
          resumeFrom: result1,
        );
      },
    );

    test(
      'does not generate part when sink is accessed but no content is added',
      () async {
        final builderFactories = BuilderFactories({
          'a:builder1': [(_) => EmptyPartWritingBuilder()],
        });
        final builderDefinitions = [
          BuilderDefinition(
            'a:builder1',
            hideOutput: false,
            autoApply: AutoApply.allPackages,
            addsToLibrary: true,
          ),
        ];

        await testPhases(builderFactories, builderDefinitions, {
          'a|lib/a.dart': '',
        }, outputs: {});
      },
    );
  });
}
