// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_contract_weaver/src/exit_rewriter.dart';
import 'package:test/test.dart';

void main() {
  /// The rewritten `return e;` for a function returning [returnType].
  String rewrite(String? returnType, {bool isAsync = false}) => ExitRewriter(
    returnType: returnType,
    isAsync: isAsync,
  ).returnValue('e', 'CHECKS;\n').replaceAll('\n', ' ');

  group('ExitRewriter', () {
    group('synchronous', () {
      test('types the result as the return type', () {
        expect(
          rewrite('Map<String, int>'),
          'return ((Map<String, int> result) { CHECKS; return result; })(e);',
        );
      });

      for (final type in [null, 'void', 'dynamic']) {
        test('leaves the result untyped for $type', () {
          expect(rewrite(type), startsWith('return ((result) {'));
        });
      }

      test('does not treat FutureOr as a future', () {
        expect(rewrite('FutureOr<int>'), startsWith('return ((FutureOr<int>'));
      });
    });

    group('returning a future without async', () {
      for (final (type, value) in [
        ('Future<int>', 'int'),
        ('async.Future<int>', 'int'),
        ('Future<Map<String, List<int>>>', 'Map<String, List<int>>'),
      ]) {
        test('chains on $type with a $value result', () {
          expect(
            rewrite(type),
            'return (e).then(($value result) { CHECKS; return result; });',
          );
        });
      }

      test('leaves the result untyped for a bare Future', () {
        expect(rewrite('Future'), startsWith('return (e).then((result) {'));
      });
    });

    group('async', () {
      test('names the value type so inference keeps it', () {
        expect(
          rewrite('Future<int>', isAsync: true),
          'return await (Future<int>.value(e)'
          '.then((int result) { CHECKS; return result; }));',
        );
      });

      for (final type in ['Future<void>', 'Future<dynamic>', 'Future', null]) {
        test('leaves the value untyped for $type', () {
          expect(
            rewrite(type, isAsync: true),
            startsWith('return await (Future.value(e).then((result) {'),
          );
        });
      }

      test('unwraps FutureOr', () {
        expect(
          rewrite('FutureOr<int>', isAsync: true),
          contains('Future<int>.value(e).then((int result)'),
        );
      });
    });
  });
}
