// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:build_web_compilers/src/build_modules/platform.dart';
import 'package:build_web_compilers/src/common.dart';
import 'package:build_web_compilers/src/dart2js_bootstrap.dart';
import 'package:build_web_compilers/src/platforms.dart';
import 'package:test/test.dart';

void main() {
  group('deprecatedJsInteropArg', () {
    test('is null when not configured', () {
      expect(deprecatedJsInteropArg(null), isNull);
    });

    test('returns exactly one form of the flag', () {
      expect(deprecatedJsInteropArg(true), '--deprecated-js-interop');
      expect(deprecatedJsInteropArg(false), '--no-deprecated-js-interop');
    });
  });

  group('readDeprecatedJsInteropOption', () {
    test('is null when not configured', () {
      expect(readDeprecatedJsInteropOption(const BuilderOptions({})), isNull);
    });

    test('reads true and false', () {
      for (final value in [true, false]) {
        expect(
          readDeprecatedJsInteropOption(
            BuilderOptions({deprecatedJsInteropOption: value}),
          ),
          value,
        );
      }
    });
  });

  test('isDeprecatedJsInteropArg matches both forms only', () {
    expect(isDeprecatedJsInteropArg('--deprecated-js-interop'), isTrue);
    expect(isDeprecatedJsInteropArg('--no-deprecated-js-interop'), isTrue);
    expect(isDeprecatedJsInteropArg('--deprecated-js-interop=false'), isFalse);
    expect(isDeprecatedJsInteropArg('-O4'), isFalse);
  });

  group('withoutOverriddenDart2JsArgs', () {
    const userArgs = ['-O4', '--no-deprecated-js-interop', '--minify'];

    test('keeps manual flags when the option is not configured', () {
      expect(
        withoutOverriddenDart2JsArgs(userArgs, deprecatedJsInterop: null),
        userArgs,
      );
    });

    test('drops manual flags when the option is configured', () {
      for (final value in [true, false]) {
        expect(
          withoutOverriddenDart2JsArgs(userArgs, deprecatedJsInterop: value),
          ['-O4', '--minify'],
        );
      }
    });
  });

  group('dart2JsFailureMessage', () {
    final entrypoint = AssetId('a', 'web/main.dart');

    test('includes stdout before stderr', () {
      final message = dart2JsFailureMessage(
        entrypoint,
        ProcessResult(
          0,
          1,
          'web/main.dart:1:8:\nError: └─ dart:html\n',
          'oops',
        ),
      );
      expect(
        message,
        'dart2js failed to compile a|web/main.dart (exit code 1).\n\n'
        'web/main.dart:1:8:\nError: └─ dart:html\n\n'
        'oops',
      );
    });

    test('omits empty output', () {
      final message = dart2JsFailureMessage(
        entrypoint,
        ProcessResult(0, 254, '  \n', 'Error: failed'),
      );
      expect(
        message,
        'dart2js failed to compile a|web/main.dart (exit code 254).\n\n'
        'Error: failed',
      );
    });
  });

  group('platformForDeprecatedJsInterop', () {
    final platform = DartPlatform.register('deprecated_js_interop_test', [
      'core',
      'html',
      'js_interop',
      'js_util',
    ]);

    test('keeps the platform unless the libraries are disallowed', () {
      for (final value in [null, true]) {
        final result = platformForDeprecatedJsInterop(platform, value);
        expect(result, same(platform));
      }
    });

    test('disables conditional imports of the deprecated libraries', () {
      final result = platformForDeprecatedJsInterop(platform, false);

      expect(result, platform);
      expect(result.supportsConditionalImportOf('html'), isFalse);
      expect(result.supportsConditionalImportOf('js_util'), isFalse);
      expect(result.supportsConditionalImportOf('js_interop'), isTrue);
      expect(result.supportsLibrary('html'), isTrue);
      expect(platform.supportsConditionalImportOf('html'), isTrue);
    });
  });
}
