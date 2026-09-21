// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration4'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  test('build command write part', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    // All the builders used below, in packages that `root_pkg` depends on.
    // None is applied automatically; each section of the test enables the
    // builders it wants in `root_pkg/build.yaml`.
    tester.writePackage(
      name: 'write_part_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': r'''
builders:
  write_part_builder:
    import: 'package:write_part_pkg/builder.dart'
    builder_factories: ['writePartBuilderFactory']
    build_extensions: {'.dart': []}
    build_to: 'cache'
    adds_to_library: true
''',
        'lib/builder.dart': r'''
import 'package:build/build.dart';

Builder writePartBuilderFactory(BuilderOptions options) => WritePartBuilder();

class WritePartBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.dart': []};

  @override
  Future<void> build(BuildStep buildStep) async {
    (await buildStep.librarySourceSink)?.add('// part content');
  }
}
''',
      },
    );

    tester.writePackage(
      name: 'multi_part_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': r'''
builders:
  builder1:
    import: 'package:multi_part_pkg/builder.dart'
    builder_factories: ['factory1']
    build_extensions: {'.dart': []}
    build_to: 'cache'
    adds_to_library: true
  builder2:
    import: 'package:multi_part_pkg/builder.dart'
    builder_factories: ['factory2']
    build_extensions: {'.dart': []}
    build_to: 'cache'
    adds_to_library: true
''',
        'lib/builder.dart': r'''
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
    (await buildStep.librarySourceSink)?.add(content);
  }
}
''',
      },
    );

    tester.writePackage(
      name: 'phase_part_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': r'''
builders:
  part_generator_1:
    import: 'package:phase_part_pkg/builder.dart'
    builder_factories: ['partGen1Factory']
    build_extensions: {'.dart': ['.dummy1']}
    build_to: 'cache'
    adds_to_library: true
  part_generator_2:
    import: 'package:phase_part_pkg/builder.dart'
    builder_factories: ['partGen2Factory']
    build_extensions: {'.dart': ['.dummy2']}
    build_to: 'cache'
    required_inputs: ['.dummy1']
    adds_to_library: true
  part_generator_3:
    import: 'package:phase_part_pkg/builder.dart'
    builder_factories: ['partGen3Factory']
    build_extensions: {'.dart': ['.resolved.txt']}
    build_to: 'cache'
    required_inputs: ['.dummy2']
    adds_to_library: true
''',
        'lib/builder.dart': r'''
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
    final hasClass2 = lib.getClass('Class2') != null;
    final hasClass3 = lib.getClass('Class3') != null;
    (await buildStep.librarySourceSink)
      ?.add("class Class1 {\n  // Gen1 checked hasClass1: $hasClass1, hasClass2: $hasClass2, hasClass3: $hasClass3\n}");
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
    (await buildStep.librarySourceSink)
      ?.add("class Class2 {\n  // Gen2 checked hasClass1: $hasClass1, hasClass2: $hasClass2\n}");
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
      'Gen3 checks - Class1: $hasClass1, Class2: $hasClass2, Class3: $hasClass3',
    );
    (await buildStep.librarySourceSink)
      ?.add("class Class3 {\n  // Gen3 checked hasClass1: $hasClass1, hasClass2: $hasClass2, hasClass3: $hasClass3\n}");
  }
}
''',
      },
    );

    tester.writePackage(
      name: 'write_part_imports_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': r'''
builders:
  write_part_builder:
    import: 'package:write_part_imports_pkg/builder.dart'
    builder_factories: ['writePartBuilderFactory']
    build_extensions: {'.dart': ['.dummy']}
    build_to: 'cache'
    adds_to_library: true
  resolve_part_builder:
    import: 'package:write_part_imports_pkg/builder.dart'
    builder_factories: ['resolvePartBuilderFactory']
    build_extensions: {'.dart': ['.resolved.txt']}
    build_to: 'cache'
    required_inputs: ['.dummy']
''',
        'lib/builder.dart': r'''
import 'package:build/build.dart';

Builder writePartBuilderFactory(BuilderOptions options) => WritePartBuilder();
Builder resolvePartBuilderFactory(BuilderOptions options) =>
    ResolvePartBuilder();

class WritePartBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.dart': ['.dummy']};

  @override
  Future<void> build(BuildStep buildStep) async {
    final writer = await buildStep.librarySourceSink;
    if (writer == null) return;
    final prefix = writer.importPrefix;
    writer.addImport('dart:async', as: '${prefix}async');
    writer.addImport('package:root_pkg/dep.dart', as: '${prefix}dep');
    writer.add(
      'class Generated {'
      ' ${prefix}async.Future<void>? future;'
      ' ${prefix}dep.Dep? dep;'
      ' }',
    );
  }
}

class ResolvePartBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.dart': ['.resolved.txt']};

  @override
  Future<void> build(BuildStep buildStep) async {
    final library = await buildStep.inputLibrary;
    final generated = library.getClass('Generated');
    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.resolved.txt'),
      generated == null
          ? 'No Generated'
          : 'Generated: '
                '${generated.fields.map((f) => f.type.getDisplayString()).join(', ')}',
    );
  }
}
''',
      },
    );

    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: [
        'multi_part_pkg',
        'phase_part_pkg',
        'write_part_imports_pkg',
        'write_part_pkg',
      ],
      files: {
        'build.yaml': r'''
targets:
  $default:
    builders:
      write_part_pkg|write_part_builder:
        enabled: true
''',
        'lib/a.dart': 'class A {}',
      },
    );

    // One builder writes a part contribution.
    var output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(tester.read('root_pkg/lib/_br_/a.part.dart'), r'''
// dart format off
part of '../a.dart';

// === write_part_pkg:write_part_builder/0 contribution.
// part content

''');

    // Two builders writing parts to the same library concatenate.
    tester.write('root_pkg/build.yaml', r'''
targets:
  $default:
    builders:
      multi_part_pkg|builder1:
        enabled: true
      multi_part_pkg|builder2:
        enabled: true
''');
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(tester.read('root_pkg/lib/_br_/a.part.dart'), r'''
// dart format off
part of '../a.dart';

// === multi_part_pkg:builder2/0 contribution.
// contribution 2

// === multi_part_pkg:builder1/1 contribution.
// contribution 1

''');

    // A library resolved in a later phase sees the part written in an earlier
    // phase.
    tester.write('root_pkg/build.yaml', r'''
targets:
  $default:
    builders:
      phase_part_pkg|part_generator_1:
        enabled: true
      phase_part_pkg|part_generator_2:
        enabled: true
      phase_part_pkg|part_generator_3:
        enabled: true
''');
    tester.write('root_pkg/lib/a.dart', r'''
part '_br_/a.part.dart';

class A {}
''');
    output = await tester.run(
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
    expect(tester.read('root_pkg/lib/_br_/a.part.dart'), r'''
// dart format off
part of '../a.dart';

// === phase_part_pkg:part_generator_1/0 contribution.
class Class1 {
  // Gen1 checked hasClass1: false, hasClass2: false, hasClass3: false
}

// === phase_part_pkg:part_generator_2/1 contribution.
class Class2 {
  // Gen2 checked hasClass1: true, hasClass2: false
}

// === phase_part_pkg:part_generator_3/2 contribution.
class Class3 {
  // Gen3 checked hasClass1: true, hasClass2: true, hasClass3: false
}

''');

    // The same holds on an incremental build.
    tester.write('root_pkg/lib/a.dart', r'''
part '_br_/a.part.dart';

class A {
  void foo() {}
}
''');
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(tester.read('root_pkg/lib/_br_/a.part.dart'), r'''
// dart format off
part of '../a.dart';

// === phase_part_pkg:part_generator_1/0 contribution.
class Class1 {
  // Gen1 checked hasClass1: false, hasClass2: false, hasClass3: false
}

// === phase_part_pkg:part_generator_2/1 contribution.
class Class2 {
  // Gen2 checked hasClass1: true, hasClass2: false
}

// === phase_part_pkg:part_generator_3/2 contribution.
class Class3 {
  // Gen3 checked hasClass1: true, hasClass2: true, hasClass3: false
}

''');

    // Deleting a source file deletes its generated part, and leaves other
    // generated parts alone.
    tester.write('root_pkg/build.yaml', r'''
targets:
  $default:
    builders:
      write_part_pkg|write_part_builder:
        enabled: true
''');
    tester.write('root_pkg/lib/a.dart', 'class A {}');
    tester.write('root_pkg/lib/b.dart', 'class B {}');
    await tester.run('root_pkg', 'dart run build_runner build --force-jit');
    expect(
      tester.read('root_pkg/lib/_br_/a.part.dart'),
      contains('// part content'),
    );
    expect(
      tester.read('root_pkg/lib/_br_/b.part.dart'),
      contains('// part content'),
    );

    tester.delete('root_pkg/lib/a.dart');
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(tester.read('root_pkg/lib/_br_/a.part.dart'), isNull);
    expect(
      tester.read('root_pkg/lib/_br_/b.part.dart'),
      contains('// part content'),
    );

    // A contribution can add imports, and a builder in a later phase resolves
    // the library with the import in place. The `enhanced-parts` experiment is
    // what allows a part to have imports; writing the part does not need it,
    // analyzing the result does.
    tester.delete('root_pkg/lib/b.dart');
    tester.write('root_pkg/build.yaml', r'''
targets:
  $default:
    builders:
      write_part_imports_pkg|write_part_builder:
        enabled: true
      write_part_imports_pkg|resolve_part_builder:
        enabled: true
''');
    tester.write('root_pkg/lib/a.dart', r'''
part '_br_/a.part.dart';
class A {}
''');
    tester.write('root_pkg/lib/dep.dart', 'class Dep {}\n');
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit '
          '--enable-experiment=enhanced-parts',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(tester.read('root_pkg/lib/_br_/a.part.dart'), r'''
// dart format off
part of '../a.dart';

// === write_part_imports_pkg:write_part_builder/0 imports.
import 'dart:async' as $0async;
import 'package:root_pkg/dep.dart' as $0dep;

// === write_part_imports_pkg:write_part_builder/0 contribution.
class Generated {
  $0async.Future<void>? future;
  $0dep.Dep? dep;
}

''');
    expect(
      tester.read(
        'root_pkg/.dart_tool/build/generated/root_pkg/lib/a.resolved.txt',
      ),
      'Generated: Future<void>?, Dep?',
    );

    // `a.dart` only reaches `dep.dart` through the import in its part, so
    // changing `dep.dart` invalidates `a.resolved.txt` only if the deps of the
    // part are tracked.
    tester.write('root_pkg/lib/dep.dart', 'class Dep<T> {}\n');
    output = await tester.run(
      'root_pkg',
      'dart run build_runner build --force-jit '
          '--enable-experiment=enhanced-parts',
    );
    expect(output, contains(BuildLog.successPattern));
    expect(
      tester.read(
        'root_pkg/.dart_tool/build/generated/root_pkg/lib/a.resolved.txt',
      ),
      'Generated: Future<void>?, Dep<dynamic>?',
    );
  });
}
