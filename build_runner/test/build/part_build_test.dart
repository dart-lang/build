import 'package:build/build.dart';
import 'package:build_runner/src/build_plan/builder_definition.dart';
import 'package:build_runner/src/build_plan/builder_factories.dart';
import 'package:build_runner/src/constants.dart';
import 'package:glob/glob.dart';
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
    final brId = AssetId('a', 'lib/_br_/a.part.dart');
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

class PartVerifyingInvisibilityBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': ['.check.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final brId = AssetId('a', 'lib/_br_/a.part.dart');
    expect(await buildStep.canRead(brId), isFalse);
    expect(
      buildStep.readAsString(brId),
      throwsA(isA<AssetNotFoundException>()),
    );
    expect(buildStep.readAsBytes(brId), throwsA(isA<AssetNotFoundException>()));
    expect(buildStep.digest(brId), throwsA(isA<AssetNotFoundException>()));
    final found = await buildStep.findAssets(Glob('lib/_br_/*')).toList();
    expect(found, isEmpty);
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
          outputsToArtifactTree: false,
          autoApply: AutoApply.allPackages,
          addsToLibrary: true,
        ),
        BuilderDefinition(
          'a:builder2',
          outputsToArtifactTree: false,
          autoApply: AutoApply.allPackages,
          addsToLibrary: true,
        ),
      ];

      // Initial build.
      // Expected generated part combines imports and content from both.
      final expectedGeneratedPart = r'''
// dart format off
part of '../a.dart';

// === a:builder1/0 imports.
import 'package:a/b.dart' as $0b;

// === a:builder2/1 imports.
import 'package:a/b.dart' as $1b;

// === a:builder1/0 contribution.
// builder saw: initial_b
content1

// === a:builder2/1 contribution.
// builder saw: initial_c
content2

''';

      final result1 = await testPhases(
        builderFactories,
        builderDefinitions,
        {
          'a|lib/a.dart': '',
          'a|lib/b.txt': 'initial_b',
          'a|lib/c.txt': 'initial_c',
        },
        outputs: {'a|lib/_br_/a.part.dart': expectedGeneratedPart},
      );

      // Now we do an incremental build where we ONLY change b.txt.
      // builder1 will run again, builder2 will be cached.
      final expectedGeneratedPart2 = r'''
// dart format off
part of '../a.dart';

// === a:builder1/0 imports.
import 'package:a/b.dart' as $0b;

// === a:builder2/1 imports.
import 'package:a/b.dart' as $1b;

// === a:builder1/0 contribution.
// builder saw: modified_b
content1

// === a:builder2/1 contribution.
// builder saw: initial_c
content2

''';

      await testPhases(
        builderFactories,
        builderDefinitions,
        {
          'a|lib/a.dart': '',
          'a|lib/b.txt': 'modified_b',
          'a|lib/c.txt': 'initial_c',
        },
        outputs: {'a|lib/_br_/a.part.dart': expectedGeneratedPart2},
        resumeFrom: result1,
      );
    });

    test('does not write the part again when nothing changes', () async {
      final builderFactories = BuilderFactories({
        'a:builder1': [
          (_) => PartWritingBuilder('content1', 'lib/b.txt', '.b1.dart'),
        ],
      });
      final builderDefinitions = [
        BuilderDefinition(
          'a:builder1',
          outputsToArtifactTree: false,
          autoApply: AutoApply.allPackages,
          addsToLibrary: true,
        ),
      ];

      final expectedGeneratedPart = r'''
// dart format off
part of '../a.dart';

// === a:builder1/0 imports.
import 'package:a/b.dart' as $0b;

// === a:builder1/0 contribution.
// builder saw: initial_b
content1

''';

      final sources = {'a|lib/a.dart': '', 'a|lib/b.txt': 'initial_b'};

      final result1 = await testPhases(
        builderFactories,
        builderDefinitions,
        sources,
        outputs: {'a|lib/_br_/a.part.dart': expectedGeneratedPart},
      );

      // The step is skipped and its contribution is copied from the previous
      // build, so the part is unchanged and is not written again.
      await testPhases(
        builderFactories,
        builderDefinitions,
        sources,
        outputs: {},
        resumeFrom: result1,
      );
    });

    test(
      'phase by phase mixed reuse and new contributions across 3 phases',
      () async {
        final builderFactories = BuilderFactories({
          'a:builder1': [
            (_) => PartWritingBuilder('content1', 'lib/b.txt', '.b1.dart'),
          ],
          'a:builder2': [
            (_) => PartWritingBuilder('content2', 'lib/c.txt', '.b2.dart'),
          ],
          'a:builder3': [
            (_) => PartWritingBuilder('content3', 'lib/d.txt', '.b3.dart'),
          ],
        });
        final builderDefinitions = [
          BuilderDefinition(
            'a:builder1',
            outputsToArtifactTree: false,
            autoApply: AutoApply.allPackages,
            addsToLibrary: true,
          ),
          BuilderDefinition(
            'a:builder2',
            outputsToArtifactTree: false,
            autoApply: AutoApply.allPackages,
            addsToLibrary: true,
          ),
          BuilderDefinition(
            'a:builder3',
            outputsToArtifactTree: false,
            autoApply: AutoApply.allPackages,
            addsToLibrary: true,
          ),
        ];

        // Initial build with 3 phases.
        final initialExpected = r'''
// dart format off
part of '../a.dart';

// === a:builder1/0 imports.
import 'package:a/b.dart' as $0b;

// === a:builder2/1 imports.
import 'package:a/b.dart' as $1b;

// === a:builder3/2 imports.
import 'package:a/b.dart' as $2b;

// === a:builder1/0 contribution.
// builder saw: b0
content1

// === a:builder2/1 contribution.
// builder saw: c0
content2

// === a:builder3/2 contribution.
// builder saw: d0
content3

''';

        final result1 = await testPhases(
          builderFactories,
          builderDefinitions,
          {
            'a|lib/a.dart': '',
            'a|lib/b.txt': 'b0',
            'a|lib/c.txt': 'c0',
            'a|lib/d.txt': 'd0',
          },
          outputs: {'a|lib/_br_/a.part.dart': initialExpected},
        );

        // Incremental build where only phase 1 changes.
        // Phase 0 and phase 2 are reused from the previous build.
        final mixedExpected1 = r'''
// dart format off
part of '../a.dart';

// === a:builder1/0 imports.
import 'package:a/b.dart' as $0b;

// === a:builder2/1 imports.
import 'package:a/b.dart' as $1b;

// === a:builder3/2 imports.
import 'package:a/b.dart' as $2b;

// === a:builder1/0 contribution.
// builder saw: b0
content1

// === a:builder2/1 contribution.
// builder saw: c1_modified
content2

// === a:builder3/2 contribution.
// builder saw: d0
content3

''';

        final result2 = await testPhases(
          builderFactories,
          builderDefinitions,
          {
            'a|lib/a.dart': '',
            'a|lib/b.txt': 'b0',
            'a|lib/c.txt': 'c1_modified',
            'a|lib/d.txt': 'd0',
          },
          outputs: {'a|lib/_br_/a.part.dart': mixedExpected1},
          resumeFrom: result1,
        );

        // Incremental build where phase 0 and phase 2 change.
        // Phase 1 is reused from the previous build.
        final mixedExpected2 = r'''
// dart format off
part of '../a.dart';

// === a:builder1/0 imports.
import 'package:a/b.dart' as $0b;

// === a:builder2/1 imports.
import 'package:a/b.dart' as $1b;

// === a:builder3/2 imports.
import 'package:a/b.dart' as $2b;

// === a:builder1/0 contribution.
// builder saw: b2_modified
content1

// === a:builder2/1 contribution.
// builder saw: c1_modified
content2

// === a:builder3/2 contribution.
// builder saw: d2_modified
content3

''';

        await testPhases(
          builderFactories,
          builderDefinitions,
          {
            'a|lib/a.dart': '',
            'a|lib/b.txt': 'b2_modified',
            'a|lib/c.txt': 'c1_modified',
            'a|lib/d.txt': 'd2_modified',
          },
          outputs: {'a|lib/_br_/a.part.dart': mixedExpected2},
          resumeFrom: result2,
        );
      },
    );

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
            outputsToArtifactTree: false,
            autoApply: AutoApply.allPackages,
            addsToLibrary: true,
          ),
        ];

        final expectedGeneratedPart = r'''
// @dart=2.14
// dart format off
part of '../a.dart';

// === a:builder1/0 imports.
import 'package:a/b.dart' as $0b;

// === a:builder1/0 contribution.
// builder saw: b
content

''';

        await testPhases(
          builderFactories,
          builderDefinitions,
          {'a|lib/a.dart': '// @dart=2.14\n', 'a|lib/b.txt': 'b'},
          outputs: {'a|lib/_br_/a.part.dart': expectedGeneratedPart},
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
          outputsToArtifactTree: false,
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
          outputsToArtifactTree: false,
          autoApply: AutoApply.allPackages,
          addsToLibrary: true,
        ),
        BuilderDefinition(
          'a:builder2',
          outputsToArtifactTree: false,
          autoApply: AutoApply.allPackages,
          addsToLibrary: true,
        ),
      ];

      final expectedGeneratedPart1 = r'''
// dart format off
part of '../a.dart';

// === a:builder1/0 imports.
import 'package:a/b.dart' as $0b;

// === a:builder2/1 imports.
import 'package:a/b.dart' as $1b;

// === a:builder1/0 contribution.
// builder saw: initial_b
// saw later contribution: false
content1

// === a:builder2/1 contribution.
// builder saw: initial_c
content2

''';

      final result1 = await testPhases(
        builderFactories,
        builderDefinitions,
        {
          'a|lib/a.dart': '',
          'a|lib/b.txt': 'initial_b',
          'a|lib/c.txt': 'initial_c',
        },
        outputs: {'a|lib/_br_/a.part.dart': expectedGeneratedPart1},
      );

      final expectedGeneratedPart2 = r'''
// dart format off
part of '../a.dart';

// === a:builder1/0 imports.
import 'package:a/b.dart' as $0b;

// === a:builder2/1 imports.
import 'package:a/b.dart' as $1b;

// === a:builder1/0 contribution.
// builder saw: modified_b
// saw later contribution: false
content1

// === a:builder2/1 contribution.
// builder saw: initial_c
content2

''';

      await testPhases(
        builderFactories,
        builderDefinitions,
        {
          'a|lib/a.dart': '',
          'a|lib/b.txt': 'modified_b',
          'a|lib/c.txt': 'initial_c',
        },
        outputs: {'a|lib/_br_/a.part.dart': expectedGeneratedPart2},
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
          outputsToArtifactTree: false,
          autoApply: AutoApply.allPackages,
          addsToLibrary: true,
        ),
        BuilderDefinition(
          'a:builder2',
          outputsToArtifactTree: false,
          autoApply: AutoApply.allPackages,
          addsToLibrary: true,
        ),
      ];

      final expectedGeneratedPart1 = r'''
// dart format off
part of '../a.dart';

// === a:builder1/0 imports.
import 'package:a/b.dart' as $0b;

// === a:builder2/1 imports.
import 'package:a/b.dart' as $1b;

// === a:builder1/0 contribution.
// builder saw: initial_b
content1

// === a:builder2/1 contribution.
// builder saw: initial_c
content2

''';

      final result1 = await testPhases(
        builderFactories,
        builderDefinitions,
        {
          'a|lib/a.dart': '',
          'a|lib/b.txt': 'initial_b',
          'a|lib/c.txt': 'initial_c',
        },
        outputs: {'a|lib/_br_/a.part.dart': expectedGeneratedPart1},
      );

      final expectedGeneratedPart2 = r'''
// dart format off
part of '../a.dart';

// === a:builder1/0 imports.
import 'package:a/b.dart' as $0b;

// === a:builder1/0 contribution.
// builder saw: initial_b
content1

''';

      await testPhases(
        builderFactories,
        builderDefinitions,
        {'a|lib/a.dart': '', 'a|lib/b.txt': 'initial_b', 'a|lib/c.txt': 'skip'},
        outputs: {'a|lib/_br_/a.part.dart': expectedGeneratedPart2},
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
            outputsToArtifactTree: false,
            autoApply: AutoApply.allPackages,
            addsToLibrary: true,
          ),
          BuilderDefinition(
            'a:builder2',
            outputsToArtifactTree: false,
            autoApply: AutoApply.allPackages,
            addsToLibrary: true,
          ),
        ];

        final expectedGeneratedPart1 = '''
// dart format off
part of '../a.dart';

// === a:builder1/0 contribution.
// builder saw: initial_b
class Class1 {
  // sawClass2: false
}

// === a:builder2/1 contribution.
// builder saw: initial_c
class Class2 {}

''';

        final result1 = await testPhases(
          builderFactories,
          builderDefinitions,
          {
            'a|lib/a.dart': 'part \'_br_/a.part.dart\';\n',
            'a|lib/b.txt': 'initial_b',
            'a|lib/c.txt': 'initial_c',
          },
          outputs: {'a|lib/_br_/a.part.dart': expectedGeneratedPart1},
        );

        final expectedGeneratedPart2 = '''
// dart format off
part of '../a.dart';

// === a:builder1/0 contribution.
// builder saw: modified_b
class Class1 {
  // sawClass2: false
}

// === a:builder2/1 contribution.
// builder saw: initial_c
class Class2 {}

''';

        await testPhases(
          builderFactories,
          builderDefinitions,
          {
            'a|lib/a.dart': 'part \'_br_/a.part.dart\';\n',
            'a|lib/b.txt': 'modified_b',
            'a|lib/c.txt': 'initial_c',
          },
          outputs: {'a|lib/_br_/a.part.dart': expectedGeneratedPart2},
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
            outputsToArtifactTree: false,
            autoApply: AutoApply.allPackages,
            addsToLibrary: true,
          ),
        ];

        await testPhases(builderFactories, builderDefinitions, {
          'a|lib/a.dart': '',
        }, outputs: {});
      },
    );

    test('_br_ assets are invisible to asset reader calls', () async {
      final builderFactories = BuilderFactories({
        'a:builder1': [
          (_) => PartWritingBuilder('content', 'lib/b.txt', '.b.dart'),
        ],
        'a:builder2': [(_) => PartVerifyingInvisibilityBuilder()],
      });
      final builderDefinitions = [
        BuilderDefinition(
          'a:builder1',
          outputsToArtifactTree: false,
          autoApply: AutoApply.allPackages,
          addsToLibrary: true,
        ),
        BuilderDefinition(
          'a:builder2',
          outputsToArtifactTree: false,
          autoApply: AutoApply.allPackages,
          addsToLibrary: false,
        ),
      ];

      final expectedGeneratedPart = r'''
// dart format off
part of '../a.dart';

// === a:builder1/0 imports.
import 'package:a/b.dart' as $0b;

// === a:builder1/0 contribution.
// builder saw: b
content

''';

      await testPhases(
        builderFactories,
        builderDefinitions,
        {'a|lib/a.dart': '', 'a|lib/b.txt': 'b'},
        outputs: {'a|lib/_br_/a.part.dart': expectedGeneratedPart},
      );
    });

    test(
      'rebuilding with existing shared parts after discarding the asset graph',
      () async {
        final builderFactories = BuilderFactories({
          'a:builder1': [
            (_) => PartWritingBuilder('content', 'lib/b.txt', '.b.dart'),
          ],
        });
        final builderDefinitions = [
          BuilderDefinition(
            'a:builder1',
            outputsToArtifactTree: false,
            autoApply: AutoApply.allPackages,
            addsToLibrary: true,
          ),
        ];

        final expectedGeneratedPart = r'''
// dart format off
part of '../a.dart';

// === a:builder1/0 imports.
import 'package:a/b.dart' as $0b;

// === a:builder1/0 contribution.
// builder saw: b
content

''';

        final result = await testPhases(
          builderFactories,
          builderDefinitions,
          {'a|lib/a.dart': '', 'a|lib/b.txt': 'b'},
          outputs: {'a|lib/_br_/a.part.dart': expectedGeneratedPart},
        );

        // Discard the asset graph.
        result.readerWriter.testing.delete(AssetId('a', assetGraphJsonPath));

        // Rebuild with existing shared part on disk.
        await testPhases(
          builderFactories,
          builderDefinitions,
          {},
          outputs: {'a|lib/_br_/a.part.dart': expectedGeneratedPart},
          resumeFrom: result,
        );
      },
    );

    test(
      'removing a shared part contributor through a configuration change',
      () async {
        final builderFactories1 = BuilderFactories({
          'a:builder1': [
            (_) => PartWritingBuilder('content1', 'lib/b.txt', '.b.dart'),
          ],
          'a:builder2': [
            (_) => PartWritingBuilder('content2', 'lib/c.txt', '.c.dart'),
          ],
        });
        final builderDefinitions1 = [
          BuilderDefinition(
            'a:builder1',
            outputsToArtifactTree: false,
            autoApply: AutoApply.allPackages,
            addsToLibrary: true,
          ),
          BuilderDefinition(
            'a:builder2',
            outputsToArtifactTree: false,
            autoApply: AutoApply.allPackages,
            addsToLibrary: true,
          ),
        ];

        final expectedGeneratedPart1 = r'''
// dart format off
part of '../a.dart';

// === a:builder1/0 imports.
import 'package:a/b.dart' as $0b;

// === a:builder2/1 imports.
import 'package:a/b.dart' as $1b;

// === a:builder1/0 contribution.
// builder saw: b
content1

// === a:builder2/1 contribution.
// builder saw: c
content2

''';

        final result = await testPhases(
          builderFactories1,
          builderDefinitions1,
          {'a|lib/a.dart': '', 'a|lib/b.txt': 'b', 'a|lib/c.txt': 'c'},
          outputs: {'a|lib/_br_/a.part.dart': expectedGeneratedPart1},
        );

        // Remove builder2 through a configuration change.
        final builderFactories2 = BuilderFactories({
          'a:builder1': [
            (_) => PartWritingBuilder('content1', 'lib/b.txt', '.b.dart'),
          ],
        });
        final builderDefinitions2 = [
          BuilderDefinition(
            'a:builder1',
            outputsToArtifactTree: false,
            autoApply: AutoApply.allPackages,
            addsToLibrary: true,
          ),
        ];

        final expectedGeneratedPart2 = r'''
// dart format off
part of '../a.dart';

// === a:builder1/0 imports.
import 'package:a/b.dart' as $0b;

// === a:builder1/0 contribution.
// builder saw: b
content1

''';

        await testPhases(
          builderFactories2,
          builderDefinitions2,
          {},
          outputs: {'a|lib/_br_/a.part.dart': expectedGeneratedPart2},
          resumeFrom: result,
        );
      },
    );

    test('removing all shared part contributors through a configuration change '
        'deletes the shared part', () async {
      final builderFactories1 = BuilderFactories({
        'a:builder1': [
          (_) => PartWritingBuilder('content', 'lib/b.txt', '.b.dart'),
        ],
      });
      final builderDefinitions1 = [
        BuilderDefinition(
          'a:builder1',
          outputsToArtifactTree: false,
          autoApply: AutoApply.allPackages,
          addsToLibrary: true,
        ),
      ];

      final expectedGeneratedPart = r'''
// dart format off
part of '../a.dart';

// === a:builder1/0 imports.
import 'package:a/b.dart' as $0b;

// === a:builder1/0 contribution.
// builder saw: b
content

''';

      final result = await testPhases(
        builderFactories1,
        builderDefinitions1,
        {'a|lib/a.dart': '', 'a|lib/b.txt': 'b'},
        outputs: {'a|lib/_br_/a.part.dart': expectedGeneratedPart},
      );

      final partId = AssetId('a', 'lib/_br_/a.part.dart');
      expect(result.readerWriter.testing.exists(partId), isTrue);

      // Remove builder1 through a configuration change.
      final builderFactories2 = BuilderFactories({});
      final builderDefinitions2 = <AbstractBuilderDefinition>[];

      await testPhases(
        builderFactories2,
        builderDefinitions2,
        {},
        outputs: {},
        resumeFrom: result,
      );

      expect(result.readerWriter.testing.exists(partId), isFalse);
    });
  });
}
