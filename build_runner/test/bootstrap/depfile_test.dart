// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner/src/bootstrap/depfile.dart';
import 'package:test/test.dart';

void main() {
  group('Depfile', () {
    test('parses', () async {
      expect(Depfile.parse('output: input1 input2\n'), [
        'output',
        'input1',
        'input2',
      ]);
    });

    test('parses when filenames have spaces and backslashes', () async {
      expect(
        Depfile.parse(
          r'output: input1 input2 input\ with\ space input4 path\\input5'
          '\n',
        ),
        [
          'output',
          'input1',
          'input2',
          'input with space',
          'input4',
          r'path\input5',
        ],
      );
    });
  });
}
