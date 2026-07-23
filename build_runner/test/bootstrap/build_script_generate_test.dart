// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner/src/bootstrap/build_script_generate.dart';
import 'package:test/test.dart';

void main() {
  group('FactoryExpression', () {
    test('accepts valid identifiers', () {
      expect(
        () => FactoryExpression(
          builderKey: 'a:a',
          name: 'valid',
          import: 'package:a/a.dart',
        ),
        returnsNormally,
      );
      expect(
        () => FactoryExpression(
          builderKey: 'a:a',
          name: 'Valid.named',
          import: 'package:a/a.dart',
        ),
        returnsNormally,
      );
    });

    test('rejects identifiers with invalid characters', () {
      expect(
        () => FactoryExpression(
          builderKey: 'a:a',
          name: 'invalid(){}',
          import: 'package:a/a.dart',
        ),
        throwsArgumentError,
      );
      expect(
        () => FactoryExpression(
          builderKey: 'a:a',
          name: 'Builder != ()',
          import: 'package:a/a.dart',
        ),
        throwsArgumentError,
      );
    });

    test('rejects imports with invalid characters', () {
      expect(
        () => FactoryExpression(
          builderKey: 'a:a',
          name: 'valid',
          import: "package:a/a.dart';\n",
        ),
        throwsArgumentError,
      );
      expect(
        () => FactoryExpression(
          builderKey: 'a:a',
          name: 'valid',
          import: r'package:a/a.dart$',
        ),
        throwsArgumentError,
      );
      expect(
        () => FactoryExpression(
          builderKey: 'a:a',
          name: 'valid',
          import: "package:a/a.dart'",
        ),
        throwsArgumentError,
      );
    });
  });

  group('BuilderFactoriesExpressions', () {
    test('accepts valid builder keys', () {
      final expressions = BuilderFactoriesExpressions(
        builderFactories: {
          'valid_package:valid-builder': [
            FactoryExpression(
              builderKey: 'valid_package:valid-builder',
              name: 'valid',
              import: 'package:a/a.dart',
            ),
          ],
        },
        postProcessBuilderFactories: {},
      );
      expect(() => expressions.renderBuilderFactories, returnsNormally);
    });

    test('rejects builder keys with invalid characters', () {
      final expressions = BuilderFactoriesExpressions(
        builderFactories: {
          "a:a'; //": [
            FactoryExpression(
              builderKey: "a:a'; //",
              name: 'valid',
              import: 'package:a/a.dart',
            ),
          ],
        },
        postProcessBuilderFactories: {},
      );
      expect(() => expressions.renderBuilderFactories, throwsArgumentError);
    });
  });
}
