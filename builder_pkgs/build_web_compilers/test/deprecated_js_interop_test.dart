// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:build_web_compilers/src/build_modules/platform.dart';
import 'package:build_web_compilers/src/common.dart';
import 'package:build_web_compilers/src/dart2js_bootstrap.dart';
import 'package:build_web_compilers/src/platforms.dart';
import 'package:logging/logging.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../bin/fes_manager.dart';

void main() {
  group('parseDeprecatedJsInteropArg', () {
    test('parses both forms', () {
      expect(parseDeprecatedJsInteropArg('--deprecated-js-interop'), isTrue);
      expect(
        parseDeprecatedJsInteropArg('--no-deprecated-js-interop'),
        isFalse,
      );
    });

    test('returns null for non-matching arguments', () {
      expect(parseDeprecatedJsInteropArg('-O4'), isNull);
      expect(
        parseDeprecatedJsInteropArg('--deprecated-js-interop=false'),
        isNull,
      );
      expect(parseDeprecatedJsInteropArg(''), isNull);
    });
  });

  group('parseFesManagerOptionalArgs', () {
    test('parses environment defines and deprecated-js-interop', () {
      final parsed = parseFesManagerOptionalArgs([
        '-DFOO=bar',
        '--no-deprecated-js-interop',
        '-DBAZ=qux=extra',
      ]);
      expect(parsed.environment, {'FOO': 'bar', 'BAZ': 'qux=extra'});
      expect(parsed.deprecatedJsInterop, isFalse);
    });

    test('parses --deprecated-js-interop', () {
      final parsed = parseFesManagerOptionalArgs(['--deprecated-js-interop']);
      expect(parsed.deprecatedJsInterop, isTrue);
      expect(parsed.environment, isEmpty);
    });

    test('defaults to null when omitted', () {
      final parsed = parseFesManagerOptionalArgs(['-DFOO=bar']);
      expect(parsed.deprecatedJsInterop, isNull);
      expect(parsed.environment, {'FOO': 'bar'});
    });
  });

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

  group('parseSdkVersion', () {
    test('parses the leading version', () {
      expect(
        parseSdkVersion('3.14.0 (stable) (Tue Nov 1 00:00:00 2026)'),
        Version(3, 14, 0),
      );
      expect(
        parseSdkVersion('3.14.0-286.0.dev (dev) on "linux_x64"'),
        Version.parse('3.14.0-286.0.dev'),
      );
      expect(
        parseSdkVersion('3.15.0-edge (main)'),
        Version.parse('3.15.0-edge'),
      );
    });

    test('returns null for an unparsable version', () {
      expect(parseSdkVersion('unknown'), isNull);
      expect(parseSdkVersion(''), isNull);
    });

    test('parses the running SDK version', () {
      expect(runningSdkVersion, isNotNull);
    });
  });

  group('checkDeprecatedJsInteropSdkSupport', () {
    final tooOld = [Version(3, 13, 0), Version.parse('3.14.0-285.0.dev')];
    final supported = [
      minDeprecatedJsInteropSdkVersion,
      Version.parse('3.14.0-300.0.dev'),
      Version(3, 14, 0),
      Version.parse('3.15.0-edge'),
    ];

    test('throws when the option is set on an older SDK', () {
      for (final value in [true, false]) {
        for (final version in tooOld) {
          expect(
            () => checkDeprecatedJsInteropSdkSupport(value, version),
            throwsA(
              isArgumentError.having(
                (e) => e.message,
                'message',
                allOf(
                  contains('`deprecated-js-interop`'),
                  contains('$minDeprecatedJsInteropSdkVersion'),
                  contains('$version'),
                ),
              ),
            ),
          );
        }
      }
    });

    test('allows the option on a supported SDK', () {
      for (final value in [true, false]) {
        for (final version in supported) {
          checkDeprecatedJsInteropSdkSupport(value, version);
        }
      }
    });

    test('skips the check if the option or version is unknown', () {
      for (final version in [...tooOld, null]) {
        checkDeprecatedJsInteropSdkSupport(null, version);
      }
      checkDeprecatedJsInteropSdkSupport(false, null);
    });
  });

  group('warnIfDeprecatedJsInteropWithPlatformSdk', () {
    late List<LogRecord> warnings;

    setUp(() {
      warnings = [];
      final subscription = Logger.root.onRecord
          .where((record) => record.level == Level.WARNING)
          .listen(warnings.add);
      addTearDown(subscription.cancel);
    });

    test('warns when both options are set', () {
      warnIfDeprecatedJsInteropWithPlatformSdk(false, '/custom/sdk');
      expect(
        warnings.single.message,
        allOf(
          contains('`deprecated-js-interop`'),
          contains('`platform-sdk`'),
          contains('/custom/sdk'),
          contains('--no-deprecated-js-interop'),
        ),
      );
    });

    test('does not warn unless both options are set', () {
      warnIfDeprecatedJsInteropWithPlatformSdk(null, '/custom/sdk');
      warnIfDeprecatedJsInteropWithPlatformSdk(true, null);
      warnIfDeprecatedJsInteropWithPlatformSdk(null, null);
      expect(warnings, isEmpty);
    });
  });

  group('validatedDart2JsArgs', () {
    const userArgs = ['-O4', '--no-deprecated-js-interop', '--minify'];
    late List<LogRecord> warnings;

    setUp(() {
      warnings = [];
      final subscription = Logger.root.onRecord
          .where((record) => record.level == Level.WARNING)
          .listen(warnings.add);
      addTearDown(subscription.cancel);
    });

    test('keeps manual flags when the option is not configured', () {
      expect(
        validatedDart2JsArgs(userArgs, deprecatedJsInterop: null),
        userArgs,
      );
      expect(warnings.single.message, contains('--no-deprecated-js-interop'));
      expect(warnings.single.message, isNot(contains('ignored')));
    });

    test('drops manual flags when the option is configured', () {
      for (final value in [true, false]) {
        warnings.clear();
        expect(validatedDart2JsArgs(userArgs, deprecatedJsInterop: value), [
          '-O4',
          '--minify',
        ]);
        expect(
          warnings.single.message,
          contains(
            'It is ignored because the `deprecated-js-interop` option '
            'is set to `$value`.',
          ),
        );
      }
    });

    test('warns about, but keeps, other overlapping flags', () {
      const args = ['--native-null-assertions', '--enable-experiment=foo'];
      expect(validatedDart2JsArgs(args, deprecatedJsInterop: false), args);
      expect(warnings, hasLength(2));
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
