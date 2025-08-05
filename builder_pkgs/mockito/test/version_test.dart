// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart.testing/google3_test_dirs.dart' show runfilesDir;
import 'package:mockito/src/version.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('check versions', () async {
    final packageRoot = p.join(
      runfilesDir,
      'google3',
      'third_party',
      'dart',
      'mockito',
    );
    final pubspecFile = p.normalize(p.join(packageRoot, 'pubspec.yaml'));
    final pubspecContent =
        loadYaml(File(pubspecFile).readAsStringSync()) as YamlMap;

    expect(packageVersion, pubspecContent['version']);
  });
}
