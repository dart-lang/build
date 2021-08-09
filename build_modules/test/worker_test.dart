// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  test('can pass dart2js arguments with spaces', () async {
    await testBuilder(
        TestBuilder(
            build: (BuildStep buildStep, _) async {
              var resource =
                  await buildStep.fetchResource(dart2JsWorkerResource);
              await scratchSpace.ensureAssets([buildStep.inputId], buildStep);
              var result = await resource
                  .compile(['web/foo bar.dart', '-o', 'web/foo bar.dart.js']);
              expect(result.succeeded, true, reason: result.output);
              await scratchSpace.copyOutput(
                  buildStep.inputId.changeExtension('.dart.js'), buildStep);
              expect(result.output, contains('web/foo%20bar.dart.js'));
            },
            buildExtensions: {
              '.dart': ['.dart.js']
            }),
        {
          'a|web/foo bar.dart': 'main() {}',
        },
        outputs: {
          'a|web/foo bar.dart.js': decodedMatches(
              contains('//# sourceMappingURL=foo%20bar.dart.js.map')),
        });
  });
}
