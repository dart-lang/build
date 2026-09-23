// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_contract_weaver/src/cli/weaver_exception.dart';
import 'package:_contract_weaver/src/cli/weaver_options.dart';
import 'package:_contract_weaver/src/contract_import_rule.dart';
import 'package:test/test.dart';

void main() {
  group('WeaverOptions', () {
    test('defaults', () {
      expect(
        WeaverOptions.parse([]),
        WeaverOptions(
          (b) => b
            ..help = false
            ..clean = false
            ..analyzeOnly = false,
        ),
      );
    });

    test('parses its own options', () {
      expect(
        WeaverOptions.parse([
          '--clean',
          '--analyze-only',
          '--stage-dir=/tmp/stage',
          '--package=pkgs/foo',
        ]),
        WeaverOptions(
          (b) => b
            ..help = false
            ..clean = true
            ..analyzeOnly = true
            ..stageDir = '/tmp/stage'
            ..package = 'pkgs/foo',
        ),
      );
    });

    test('passes arguments after -- through to the tests, in order', () {
      expect(
        WeaverOptions.parse([
          '--clean',
          '--',
          'test/a_test.dart',
          '-j1',
          '--name',
          'foo',
        ]).testArgs,
        ['test/a_test.dart', '-j1', '--name', 'foo'],
      );
    });

    test('rejects an unknown option before --', () {
      expect(
        () => WeaverOptions.parse(['-j1']),
        throwsA(isA<WeaverException>()),
      );
    });

    test('does not pass help through to the tests', () {
      for (final flag in ['--help', '-h']) {
        final options = WeaverOptions.parse([flag]);
        expect(options.help, isTrue);
        expect(options.testArgs, isEmpty);
      }
    });

    test('parses repeated import rules', () {
      expect(
        WeaverOptions.parse([
          '--contract-import=.a,.b=package:p/a.dart',
          '--contract-import=.c=package:p/c.dart',
        ]).importRules,
        [
          ContractImportRule.of(
            markers: ['.a', '.b'],
            import: 'package:p/a.dart',
          ),
          ContractImportRule.of(markers: ['.c'], import: 'package:p/c.dart'),
        ],
      );
    });

    test('rejects an import rule without a URI', () {
      expect(
        () => WeaverOptions.parse(['--contract-import=.a']),
        throwsA(isA<WeaverException>()),
      );
    });
  });
}
