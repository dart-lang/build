// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_web_compilers/builders.dart';
import 'package:test/test.dart';

void main() {
  // The builder factories remember the first options they see for the whole
  // isolate, so this is a single test.
  test('deprecated-js-interop must match across builders', () {
    const disallowed = BuilderOptions({'deprecated-js-interop': false});
    final builders = [
      ddcMetaModuleBuilder,
      ddcModuleBuilder,
      dart2jsMetaModuleBuilder,
      dart2jsModuleBuilder,
      webEntrypointBuilder,
    ];
    for (final builder in builders) {
      expect(() => builder(disallowed), returnsNormally);
    }

    for (final options in const [
      BuilderOptions({'deprecated-js-interop': true}),
      BuilderOptions({}),
    ]) {
      for (final builder in builders) {
        expect(
          () => builder(options),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('`deprecated-js-interop` must be configured the same'),
            ),
          ),
        );
      }
    }
  });
}
