// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_config/build_config.dart';
import 'package:build_runner_core/src/package_graph/build_triggers.dart';
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
        trigger.triggersOnPrimaryInput('''
import 'package:my_package/foo.dart';
'''),
        true,
      );
      expect(
        trigger.triggersOnPrimaryInput('''
import 'package:my_package/bar.dart';
'''),
        false,
      );
      expect(
        trigger.triggersOnPrimaryInput('''
import 'my_package/foo.dart';
'''),
        false,
      );
    });
  });

  group('AnnotationBuildTrigger', () {
    test('matches appropriately', () {
      final trigger = AnnotationBuildTrigger('foo');
      expect(
        trigger.triggersOnPrimaryInput('''
@foo
class Foo{}
'''),
        true,
      );
      expect(
        trigger.triggersOnPrimaryInput('''
foo
class Foo{}
'''),
        false,
      );
    });
  });
}
