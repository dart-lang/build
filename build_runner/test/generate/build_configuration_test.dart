// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_runner/build_runner.dart';

import '../common/build_configs.dart';
import '../common/common.dart';

void main() {
  test('uses builder options', () async {
    Builder copyBuilder(BuilderOptions options) => new CopyBuilder(
        inputExtension: options.config['inputExtension'] as String ?? '');

    final buildConfigs = parseBuildConfigs({
      'a': {
        'targets': {
          'a': {
            'builders': {
              'a|optioned_builder': {
                'options': {'inputExtension': '.matches'}
              }
            }
          }
        }
      }
    });
    await testBuilders(
        [
          apply('a|optioned_builder', [copyBuilder], toRoot(),
              hideOutput: false),
        ],
        {
          'a|lib/file.nomatch': 'a',
          'a|lib/file.matches': 'b',
        },
        overrideBuildConfig: buildConfigs,
        outputs: {
          'a|lib/file.copy': 'b',
        });
  });
}
