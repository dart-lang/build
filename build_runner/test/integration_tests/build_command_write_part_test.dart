// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  test('writePart writes part contribution to generated cache', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'write_part_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': '''
builders:
  write_part_builder:
    import: 'package:write_part_pkg/builder.dart'
    builder_factories: ['writePartBuilderFactory']
    build_extensions: {'.dart': []}
    auto_apply: 'root_package'
    build_to: 'cache'
''',
        'lib/builder.dart': '''
import 'package:build/build.dart';

Builder writePartBuilderFactory(BuilderOptions options) => WritePartBuilder();

class WritePartBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.dart': []};

  @override
  Future<void> build(BuildStep buildStep) async {
    buildStep.partWriter.write('// part content');
  }
}
''',
      },
    );

    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['write_part_pkg'],
      files: {'lib/a.dart': 'class A {}'},
    );

    final output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(
      tester.read(
        'root_pkg/.dart_tool/build/generated/root_pkg/lib/_generated_parts/a.dart',
      ),
      "part of '../a.dart';\n\n// part content",
    );
  });

  test(
    'two builders writing parts to same library end up concatenated',
    () async {
      final pubspecs = await Pubspecs.load();
      final tester = BuildRunnerTester(pubspecs);

      tester.writePackage(
        name: 'multi_part_pkg',
        dependencies: ['build', 'build_runner'],
        files: {
          'build.yaml': '''
builders:
  builder1:
    import: 'package:multi_part_pkg/builder.dart'
    builder_factories: ['factory1']
    build_extensions: {'.dart': []}
    auto_apply: 'root_package'
    build_to: 'cache'
  builder2:
    import: 'package:multi_part_pkg/builder.dart'
    builder_factories: ['factory2']
    build_extensions: {'.dart': []}
    auto_apply: 'root_package'
    build_to: 'cache'
''',
          'lib/builder.dart': '''
import 'package:build/build.dart';

Builder factory1(BuilderOptions options) => PartBuilder('// contribution 1');
Builder factory2(BuilderOptions options) => PartBuilder('// contribution 2');

class PartBuilder implements Builder {
  final String content;
  PartBuilder(this.content);

  @override
  Map<String, List<String>> get buildExtensions => {'.dart': []};

  @override
  Future<void> build(BuildStep buildStep) async {
    buildStep.partWriter.write(content);
  }
}
''',
        },
      );

      tester.writePackage(
        name: 'root_pkg',
        dependencies: ['build_runner'],
        pathDependencies: ['multi_part_pkg'],
        files: {'lib/a.dart': 'class A {}'},
      );

      final output = await tester.run(
        'root_pkg',
        'dart run build_runner build --force-jit',
      );
      expect(output, contains(BuildLog.successPattern));
      expect(
        tester.read(
          'root_pkg/.dart_tool/build/generated/root_pkg/lib/_generated_parts/a.dart',
        ),
        "part of '../a.dart';\n\n// contribution 2\n\n// contribution 1",
      );
    },
  );

  test(
    'resolving library in later phase sees generated part from earlier phase',
    () async {
      final pubspecs = await Pubspecs.load();
      final tester = BuildRunnerTester(pubspecs);

      tester.writePackage(
        name: 'phase_part_pkg',
        dependencies: ['build', 'build_runner'],
        files: {
          'build.yaml': '''
builders:
  part_generator_1:
    import: 'package:phase_part_pkg/builder.dart'
    builder_factories: ['partGen1Factory']
    build_extensions: {'.dart': ['.dummy1']}
    auto_apply: 'root_package'
    build_to: 'cache'
  part_generator_2:
    import: 'package:phase_part_pkg/builder.dart'
    builder_factories: ['partGen2Factory']
    build_extensions: {'.dart': ['.dummy2']}
    auto_apply: 'root_package'
    build_to: 'cache'
    required_inputs: ['.dummy1']
  part_generator_3:
    import: 'package:phase_part_pkg/builder.dart'
    builder_factories: ['partGen3Factory']
    build_extensions: {'.dart': ['.resolved.txt']}
    auto_apply: 'root_package'
    build_to: 'cache'
    required_inputs: ['.dummy2']
''',
          'lib/builder.dart': '''
import 'package:build/build.dart';

Builder partGen1Factory(BuilderOptions options) => PartGen1Builder();
Builder partGen2Factory(BuilderOptions options) => PartGen2Builder();
Builder partGen3Factory(BuilderOptions options) => PartGen3Builder();

class PartGen1Builder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.dart': ['.dummy1']};

  @override
  Future<void> build(BuildStep buildStep) async {
    final lib = await buildStep.inputLibrary;
    final hasClass1 = lib.getClass('Class1') != null;
    buildStep.partWriter.write("class Class1 {\\n  // Gen1 checked hasClass1: \$hasClass1\\n}");
  }
}

class PartGen2Builder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.dart': ['.dummy2']};

  @override
  Future<void> build(BuildStep buildStep) async {
    final lib = await buildStep.inputLibrary;
    final hasClass1 = lib.getClass('Class1') != null;
    final hasClass2 = lib.getClass('Class2') != null;
    buildStep.partWriter.write("class Class2 {\\n  // Gen2 checked hasClass1: \$hasClass1, hasClass2: \$hasClass2\\n}");
  }
}

class PartGen3Builder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.dart': ['.resolved.txt']};

  @override
  Future<void> build(BuildStep buildStep) async {
    final lib = await buildStep.inputLibrary;
    final hasClass1 = lib.getClass('Class1') != null;
    final hasClass2 = lib.getClass('Class2') != null;
    final hasClass3 = lib.getClass('Class3') != null;

    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.resolved.txt'),
      'Gen3 checks - Class1: \$hasClass1, Class2: \$hasClass2, Class3: \$hasClass3',
    );
    buildStep.partWriter.write("class Class3 {\\n  // Gen3 checked hasClass1: \$hasClass1, hasClass2: \$hasClass2, hasClass3: \$hasClass3\\n}");
  }
}
''',
        },
      );

      tester.writePackage(
        name: 'root_pkg',
        dependencies: ['build_runner'],
        pathDependencies: ['phase_part_pkg'],
        files: {
          'lib/a.dart': '''
part '_generated_parts/a.dart';

class A {}
''',
        },
      );

      final output = await tester.run(
        'root_pkg',
        'dart run build_runner build --force-jit',
      );
      expect(output, contains(BuildLog.successPattern));

      expect(
        tester.read(
          'root_pkg/.dart_tool/build/generated/root_pkg/lib/a.resolved.txt',
        ),
        contains('Gen3 checks - Class1: true, Class2: true, Class3: false'),
      );

      expect(
        tester.read(
          'root_pkg/.dart_tool/build/generated/root_pkg/lib/_generated_parts/a.dart',
        ),
        "part of '../a.dart';\n\nclass Class1 {\n  // Gen1 checked hasClass1: false\n}\n\n"
        "class Class2 {\n  // Gen2 checked hasClass1: true, hasClass2: false\n}\n\n"
        "class Class3 {\n  // Gen3 checked hasClass1: true, hasClass2: true, hasClass3: false\n}",
      );
    },
  );

  test('partWriter supports imports with enhanced-parts experiment', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'write_part_imports_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': '''
builders:
  write_part_builder:
    import: 'package:write_part_imports_pkg/builder.dart'
    builder_factories: ['writePartBuilderFactory']
    build_extensions: {'.dart': []}
    auto_apply: 'root_package'
    build_to: 'cache'
''',
        'lib/builder.dart': '''
import 'package:build/build.dart';

Builder writePartBuilderFactory(BuilderOptions options) => WritePartBuilder();

class WritePartBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.dart': []};

  @override
  Future<void> build(BuildStep buildStep) async {
    final prefix = buildStep.partWriter.importPrefix;
    buildStep.partWriter.addImport('package:foo/foo.dart', as: '\${prefix}foo');
    buildStep.partWriter.write('// part content');
  }
}
''',
      },
    );

    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['write_part_imports_pkg'],
      files: {
        'analysis_options.yaml': '''
analyzer:
  enable-experiment:
    - enhanced-parts
''',
        'lib/a.dart': '''
part '_generated_parts/a.dart';
class A {}
''',
      },
    );

    final output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(
      tester.read(
        'root_pkg/.dart_tool/build/generated/root_pkg/lib/_generated_parts/a.dart',
      ),
      "part of '../a.dart';\n\nimport 'package:foo/foo.dart' as i0_foo;\n\n// part content",
    );
  });
}
