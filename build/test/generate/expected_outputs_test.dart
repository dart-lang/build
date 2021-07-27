// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  test('replaces file extensions', () {
    _expectOutputs(
      {
        '.dart': ['.g.dart']
      },
      _asset('lib/foo.dart'),
      [_asset('lib/foo.g.dart')],
    );
  });

  group('capture groups', () {
    test('can match files in directory', () {
      _expectOutputs(
        {
          'proto/{{}}.proto': ['lib/src/generated/{{}}.dart']
        },
        _asset('proto/service.proto'),
        [_asset('lib/src/generated/service.dart')],
      );
    });

    test('can match files in subdirectories', () {
      _expectOutputs(
        {
          'proto/{{}}.proto': ['lib/src/generated/{{}}.dart']
        },
        _asset('proto/services/auth.proto'),
        [_asset('lib/src/generated/services/auth.dart')],
      );
    });

    test('can only be used once per input', () {
      expect(
        () => expectedOutputs(
            TestBuilder(buildExtensions: {'{{}}/{{}}/foo.txt': []}),
            _asset('foo.txt')),
        throwsArgumentError,
      );
    });

    test('need to be used in outputs', () {
      expect(
        () => expectedOutputs(
          TestBuilder(buildExtensions: {
            '{{}}.txt': ['invalid.txt']
          }),
          _asset('foo.txt'),
        ),
        throwsArgumentError,
      );
    });

    test('may not be used in the same output multiple times', () {
      expect(
        () => expectedOutputs(
          TestBuilder(buildExtensions: {
            '{{}}.txt': ['{{}}/{{}}/.foo']
          }),
          _asset('foo.txt'),
        ),
        throwsArgumentError,
      );
    });

    test('can use `^` to start at the beginning', () {
      const extensions = {
        '^lib/{{}}.dart': ['lib/generated/{{}}.dart']
      };

      _expectOutputs(extensions, _asset('lib/foo.dart'),
          [_asset('lib/generated/foo.dart')]);
      _expectOutputs(extensions, _asset('web/nested/lib/foo.dart'), isEmpty);
    });

    test('can be used at the start of an input', () {
      _expectOutputs(
        {
          '{{}}.proto': ['lib/src/{{}}.dart']
        },
        _asset('proto/services/auth.proto'),
        [_asset('lib/src/proto/services/auth.dart')],
      );
    });

    test('match greedily', () {
      _expectOutputs(
        {
          'lib/{{}}.dart': ['docs/{{}}.md']
        },
        // The input extension should match the outer "lib/"
        _asset('lib/src/lib/foo.dart'),
        [_asset('docs/src/lib/foo.md')],
      );
    });

    test('can be used at the end of an input', () {
      _expectOutputs(
        {
          'lib/{{}}': ['lib/copied/{{}}']
        },
        _asset('lib/src/foo.dart'),
        [_asset('lib/copied/src/foo.dart')],
      );
    });
  });
}

void _expectOutputs(
    Map<String, List<String>> extensions, AssetId input, dynamic expected) {
  expect(expectedOutputs(TestBuilder(buildExtensions: extensions), input),
      expected);
}

AssetId _asset(String path) => AssetId('a', path);
