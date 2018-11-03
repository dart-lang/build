// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:build_config/build_config.dart';

void main() {
  group('parse errors', () {
    test('for missing default target', () {
      var buildYaml = r'''
targets:
  not_package_name:
    sources: ["lib/**"]
''';
      expect(() => BuildConfig.parse('package_name', [], buildYaml),
          throwsArgumentError);
    });
  });
}
