// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner/src/bootstrap/build_script_generate.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';

void main() {
  test('the formatter leaves the build script unchanged', () {
    final script = renderBuildScript(
      BuilderFactoriesExpressions(
        builderFactories: {
          'a:a': [
            FactoryExpression(
              builderKey: 'a:a',
              name: 'aBuilder',
              import: 'package:a/a.dart',
            ),
          ],
        },
        postProcessBuilderFactories: {},
      ),
    );
    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );
    expect(formatter.format(script), script);
  });
}
