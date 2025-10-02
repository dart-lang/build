// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/src/build_plan/build_triggers.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  group('BuildTriggers', () {
    test('parses import triggers', () {
      final (triggers, _) = BuildTriggers.parseList(
        triggers: ['import foo/foo.dart', 'import foo/bar.dart'],
      );

      expect(triggers, [
        ImportBuildTrigger('foo/foo.dart'),
        ImportBuildTrigger('foo/bar.dart'),
      ]);
    });

    test('parses annotation triggers', () {
      final (triggers, _) = BuildTriggers.parseList(
        triggers: ['annotation foo', 'annotation bar'],
      );

      expect(triggers, [
        AnnotationBuildTrigger('foo'),
        AnnotationBuildTrigger('bar'),
      ]);
    });
  });

  test('parses import triggers', () {
    final (triggers, _) = BuildTriggers.parseList(
      triggers: ['import foo/foo.dart', 'import foo/bar.dart'],
    );

    expect(triggers, [
      ImportBuildTrigger('foo/foo.dart'),
      ImportBuildTrigger('foo/bar.dart'),
    ]);
  });

  test('reports warnings', () {
    final triggers = BuildTriggers.fromConfigs({
      'my_pkg': BuildConfig.parse('my_pkg', [], '''
triggers:
  other_pkg|builder:
    - import 7
    - annotation 3
    - bleh
'''),
      'an_other_pkg': BuildConfig.parse('an_other_pkg', [], '''
triggers:
  a_fourth_pkg:another_builder:
    - blah
'''),
    });

    expect(triggers.renderWarnings, '''
build.yaml of package:my_pkg:
  Invalid builder name: `other_pkg|builder`
  Invalid import trigger: `7`
  Invalid annotation trigger: `3`
  Invalid trigger: `bleh`
build.yaml of package:an_other_pkg:
  Invalid trigger: `blah`
See https://pub.dev/packages/build_config#triggers for valid usage.
''');
  });

  group('ImportBuildTrigger', () {
    test('matches appropriately', () {
      final trigger = ImportBuildTrigger('my_package/foo.dart');
      expect(
        trigger.triggersOn(
          parse('''
import 'package:my_package/foo.dart';
'''),
        ),
        true,
      );
      expect(
        trigger.triggersOn(
          parse('''
import "package:m" "y_package/fo" 'o.dart';
'''),
        ),
        true,
      );
      expect(
        trigger.triggersOn(
          parse('''
import 'package:my_package/bar.dart';
'''),
        ),
        false,
      );
      expect(
        trigger.triggersOn(
          parse('''
import 'my_package/foo.dart';
'''),
        ),
        false,
      );
    });
  });

  group('AnnotationBuildTrigger', () {
    test('matches appropriately', () {
      final trigger = AnnotationBuildTrigger('foo');
      expect(
        trigger.triggersOn(
          parse('''
@foo
class Foo{}
'''),
        ),
        true,
      );
      expect(
        trigger.triggersOn(
          parse('''
@import_prefix.foo
class Foo{}
'''),
        ),
        true,
      );
      expect(
        trigger.triggersOn(
          parse('''
@
foo
class Foo{}
'''),
        ),
        true,
      );
      expect(
        trigger.triggersOn(
          parse('''
// foo
class Foo{}
'''),
        ),
        false,
      );
    });

    test('matches constructors appropriately', () {
      final trigger = AnnotationBuildTrigger('Bar');
      expect(
        trigger.triggersOn(
          parse('''
class Bar {
  const Bar();
}
@Bar()
class Foo{}
'''),
        ),
        true,
      );
      expect(
        trigger.triggersOn(
          parse('''
class Bar {
  const Bar();
}
@import_prefix.Bar()
class Foo{}
'''),
        ),
        true,
      );
    });

    test('matches named constructors appropriately', () {
      final trigger = AnnotationBuildTrigger('Bar.baz');
      expect(
        trigger.triggersOn(
          parse('''
class Bar {
  const Bar.baz();
}
@Bar.baz()
class Foo{}
'''),
        ),
        true,
      );
      expect(
        trigger.triggersOn(
          parse('''
import 'other.dart' as import_prefix;

@import_prefix.Bar.baz()
class Foo{}
'''),
        ),
        true,
      );
    });
  });

  test('matches prefix like class name', () {
    // Import prefixes and class names can't be distinguished in syntax, so
    // an import prefix matches the same as a class name. In practice this
    // doesn't matter much because they use different case conventions.
    final trigger = AnnotationBuildTrigger('import_prefix.Bar');
    expect(
      trigger.triggersOn(
        parse('''
import "other.dart" as import_prefix;
@import_prefix.Bar()
class Foo{}
'''),
      ),
      true,
    );
  });

  group('annotation triggers', () {
    test('stop builder if missing', () async {
      final result = await testBuilders(
        [WriteOutputsBuilder()],

        {
          'a|lib/a.dart': '',
          'a|build.yaml': r'''
targets:
  $default:
    builders:
      pkg:write_outputs:
        options:
          run_only_if_triggered: true
triggers:
  pkg:write_outputs:
    - annotation foo
''',
        },
        outputs: {},
        testingBuilderConfig: false,
      );
      expect(result.succeeded, true);
    });

    test('trigger builder in same file', () async {
      await testBuilders(
        [WriteOutputsBuilder()],
        {
          'a|lib/a.dart': '@foo class A {}',
          'a|build.yaml': r'''
targets:
  $default:
    builders:
      pkg:write_outputs:
        options:
          run_only_if_triggered: true
triggers:
  pkg:write_outputs:
    - annotation foo
''',
        },
        outputs: {'a|lib/a.dart.out': ''},
        testingBuilderConfig: false,
      );
    });

    test('ignore missing part file', () async {
      final result = await testBuilders(
        [WriteOutputsBuilder()],
        {
          'a|lib/a.dart': 'part "a.part"; class A {}',
          'a|build.yaml': r'''
targets:
  $default:
    builders:
      pkg:write_outputs:
        options:
          run_only_if_triggered: true
triggers:
  pkg:write_outputs:
    - annotation foo
''',
        },
        outputs: {},
        testingBuilderConfig: false,
      );
      expect(result.succeeded, true);
    });

    test('trigger builder in part file', () async {
      await testBuilders(
        [WriteOutputsBuilder()],
        {
          'a|lib/a.dart': 'part "a.part"; class A {}',
          'a|lib/a.part': 'part of "a.dart"; @foo class B {}',
          'a|build.yaml': r'''
targets:
  $default:
    builders:
      pkg:write_outputs:
        options:
          run_only_if_triggered: true
triggers:
  pkg:write_outputs:
    - annotation foo
''',
        },
        outputs: {'a|lib/a.dart.out': ''},
        testingBuilderConfig: false,
      );
    });
  });
}

List<CompilationUnit> parse(String content) => [
  parseString(content: content).unit,
];

/// Builder called `pkg:write_outputs` that runs on `.dart` files and writes an
/// empty String to `.dart.out`.
class WriteOutputsBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': ['.dart.out'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    await buildStep.writeAsString(buildStep.inputId.addExtension('.out'), '');
  }

  @override
  String toString() => 'pkg:write_outputs';
}
