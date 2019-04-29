// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_config/build_config.dart';
import 'package:test/test.dart';

Matcher _throwsError(matcher) => throwsA(
      isA<ArgumentError>().having(
        (e) {
          printOnFailure("ACTUAL\nr'''\n${e.message}'''");
          return e.message;
        },
        'message',
        matcher,
      ),
    );

void main() {
  group('parse errors', () {
    test('for missing default target', () {
      var buildYaml = r'''
targets:
  not_package_name:
    sources: ["lib/**"]
''';
      expect(() => BuildConfig.parse('package_name', [], buildYaml),
          _throwsError(r'''
line 2, column 3: Unsupported value for "targets". Must specify a target with the name `package_name` or `$default`.
  ╷
2 │ ┌   not_package_name:
3 │ └     sources: ["lib/**"]
  ╵'''));
    });

    test('for bad build extensions', () {
      var buildYaml = r'''
builders:
  some_builder:
    build_extensions:
      .dart:
      - .dart
    builder_factories: ["someFactory"]
    import: package:package_name/builders.dart
''';
      expect(() => BuildConfig.parse('package_name', [], buildYaml),
          _throwsError(r'''
line 4, column 7: Unsupported value for "build_extensions". May not overwrite an input, the output extensions must not contain the input extension
  ╷
4 │ ┌       .dart:
5 │ │       - .dart
6 │ │     builder_factories: ["someFactory"]
  │ └────^
  ╵'''));
    });

    test('for empty include globs', () {
      var buildYaml = r'''
targets:
  $default:
    builders:
      some_package:some_builder:
        generate_for:
        -
''';
      expect(() => BuildConfig.parse('package_name', [], buildYaml),
          _throwsError(r'''
line 6, column 9: Unsupported value for "generate_for". Include globs must not be empty
  ╷
6 │         -
  │         ^
  ╵'''));
    });
  });
}
