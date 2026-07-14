import 'package:build/build.dart';
import 'package:build_runner/src/build/build_result.dart';
import 'package:build_runner/src/build_plan/builder_definition.dart';
import 'package:build_runner/src/build_plan/builder_factories.dart';
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
    final text = await buildStep.canRead(readId) ? await buildStep.readAsString(readId) : 'missing';
    buildStep.partWriter
      ..addImport('package:a/b.dart', as: '${buildStep.partWriter.importPrefix}b')
      ..write('// builder saw: $text\n$_content');
  }
}

void main() {
  group('Part Builders incremental build', () {
    test('updates generated part file correctly', () async {
      final builderFactories = BuilderFactories({
        'a:builder1': [(_) => PartWritingBuilder('content1', 'lib/b.txt', '.b1.dart')],
        'a:builder2': [(_) => PartWritingBuilder('content2', 'lib/c.txt', '.b2.dart')],
      });
      final builderDefinitions = [
        BuilderDefinition('a:builder1', hideOutput: false, autoApply: AutoApply.allPackages),
        BuilderDefinition('a:builder2', hideOutput: false, autoApply: AutoApply.allPackages),
      ];

      // Initial build.
      // Expected generated part combines imports and content from both.
      final expectedGeneratedPart = '''
part of '../a.dart';

// @PartBuilder:imports:0
import 'package:a/b.dart' as i0_b;
// @PartBuilder:imports:1
import 'package:a/b.dart' as i1_b;

// @PartBuilder:contribution:0
// builder saw: initial_b
content1

// @PartBuilder:contribution:1
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
        outputs: {r'$$a|lib/_generated_parts/a.dart': expectedGeneratedPart},
      );

      // Now we do an incremental build where we ONLY change b.txt.
      // builder1 will run again, builder2 will be cached.
      final expectedGeneratedPart2 = '''
part of '../a.dart';

// @PartBuilder:imports:0
import 'package:a/b.dart' as i0_b;
// @PartBuilder:imports:1
import 'package:a/b.dart' as i1_b;

// @PartBuilder:contribution:0
// builder saw: modified_b
content1

// @PartBuilder:contribution:1
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
        outputs: {r'$$a|lib/_generated_parts/a.dart': expectedGeneratedPart2},
        resumeFrom: result1,
      );
    });
  });
}
