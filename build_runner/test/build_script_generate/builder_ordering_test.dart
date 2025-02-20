// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_test_common/build_configs.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/src/build_script_generate/builder_ordering.dart';
import 'package:test/test.dart';

void main() {
  group('Builder ordering', () {
    test('orders builders with "runs_before"', () async {
      final buildConfigs = parseBuildConfigs({
        'a': {
          'builders': {
            'a': {
              'builder_factories': ['createBuilder'],
              'build_extensions': <String, List<String>>{},
              'target': '',
              'import': '',
              'runs_before': [':c'],
            },
            'b': {
              'builder_factories': ['createBuilder'],
              'build_extensions': <String, List<String>>{},
              'target': '',
              'import': '',
              'runs_before': [':a'],
            },
            'c': {
              'builder_factories': ['createBuilder'],
              'build_extensions': <String, List<String>>{},
              'target': '',
              'import': '',
            },
          },
        },
      });
      final orderedBuilders = findBuilderOrder(
        buildConfigs.values.expand((v) => v.builderDefinitions.values),
        {},
      );
      final orderedKeys = orderedBuilders.map((b) => b.key);
      expect(orderedKeys, ['a:b', 'a:a', 'a:c']);
    });

    test('orders builders with global "runs_before"', () {
      runInBuildConfigZone(
        () {
          final buildConfigs = parseBuildConfigs({
            'a': {
              'builders': {
                'a': {
                  'builder_factories': ['createBuilder'],
                  'build_extensions': <String, List<String>>{},
                  'target': '',
                  'import': '',
                },
                'b': {
                  'builder_factories': ['createBuilder'],
                  'build_extensions': <String, List<String>>{},
                  'target': '',
                  'import': '',
                },
                'c': {
                  'builder_factories': ['createBuilder'],
                  'build_extensions': <String, List<String>>{},
                  'target': '',
                  'import': '',
                },
              },
            },
          });
          final orderedBuilders = findBuilderOrder(
            buildConfigs.values.expand((v) => v.builderDefinitions.values),
            {
              'a:b': GlobalBuilderConfig.fromJson({
                'runs_before': ['a:a'],
              }),
              'a:a': GlobalBuilderConfig.fromJson({
                'runs_before': ['a:c'],
              }),
            },
          );
          final orderedKeys = orderedBuilders.map((b) => b.key);
          expect(orderedKeys, ['a:b', 'a:a', 'a:c']);
        },
        'a',
        [],
      );
    });

    test('orders builders with global and local "runs_before"', () {
      runInBuildConfigZone(
        () {
          final buildConfigs = parseBuildConfigs({
            'a': {
              'builders': {
                'a': {
                  'builder_factories': ['createBuilder'],
                  'build_extensions': <String, List<String>>{},
                  'target': '',
                  'import': '',
                },
                'b': {
                  'builder_factories': ['createBuilder'],
                  'build_extensions': <String, List<String>>{},
                  'target': '',
                  'import': '',
                  'runs_before': [':a'],
                },
                'c': {
                  'builder_factories': ['createBuilder'],
                  'build_extensions': <String, List<String>>{},
                  'target': '',
                  'import': '',
                },
              },
            },
          });
          final orderedBuilders = findBuilderOrder(
            buildConfigs.values.expand((v) => v.builderDefinitions.values),
            {
              'a:a': GlobalBuilderConfig.fromJson({
                'runs_before': ['a:c'],
              }),
            },
          );
          final orderedKeys = orderedBuilders.map((b) => b.key);
          expect(orderedKeys, ['a:b', 'a:a', 'a:c']);
        },
        'a',
        [],
      );
    });

    test('orders builders with `required_inputs`', () async {
      final buildConfigs = parseBuildConfigs({
        'a': {
          'builders': {
            'runs_second': {
              'builder_factories': ['createBuilder'],
              'build_extensions': <String, List<String>>{},
              'target': '',
              'import': '',
              'required_inputs': ['.first_output'],
            },
            'runs_first': {
              'builder_factories': ['createBuilder'],
              'build_extensions': {
                '.anything': ['.first_output'],
              },
              'target': '',
              'import': '',
            },
          },
        },
      });
      final orderedBuilders = findBuilderOrder(
        buildConfigs.values.expand((v) => v.builderDefinitions.values),
        {},
      );
      final orderedKeys = orderedBuilders.map((b) => b.key);
      expect(orderedKeys, ['a:runs_first', 'a:runs_second']);
    });

    test('disallows cycles', () async {
      final buildConfigs = parseBuildConfigs({
        'a': {
          'builders': {
            'builder_a': {
              'builder_factories': ['createBuilder'],
              'build_extensions': <String, List<String>>{},
              'target': '',
              'import': '',
              'required_inputs': ['.output_b'],
              'runs_before': [':builder_b'],
            },
            'builder_b': {
              'builder_factories': ['createBuilder'],
              'build_extensions': {
                '.anything': ['.output_b'],
              },
              'target': '',
              'import': '',
            },
          },
        },
      });
      expect(
        () => findBuilderOrder(
          buildConfigs.values.expand((v) => v.builderDefinitions.values),
          {},
        ),
        throwsA(anything),
      );
    });

    test('allows self cycles with `required_inputs`', () async {
      final buildConfigs = parseBuildConfigs({
        'a': {
          'builders': {
            'self_cycle': {
              'builder_factories': ['createBuilder'],
              'build_extensions': {
                '.in': ['.out'],
                '.out': ['.another'],
              },
              'target': '',
              'import': '',
              'required_inputs': ['.out'],
            },
          },
        },
      });
      final orderedBuilders = findBuilderOrder(
        buildConfigs.values.expand((v) => v.builderDefinitions.values),
        {},
      );
      final orderedKeys = orderedBuilders.map((b) => b.key);
      expect(orderedKeys, ['a:self_cycle']);
    });
  });
}
