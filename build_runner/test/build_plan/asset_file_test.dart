// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/build_plan/asset_file.dart';
import 'package:test/test.dart';

void main() {
  group('AssetFile', () {
    test('source creates visible asset file', () {
      final file = AssetFile.source(AssetId('a', 'lib/a.dart'));
      expect(file.id, AssetId('a', 'lib/a.dart'));
      expect(file.hidden, false);
      expect(file.toString(), 'source:a|lib/a.dart');
    });

    test('cache creates hidden asset file', () {
      final file = AssetFile.cache(AssetId('a', 'lib/a.dart'));
      expect(file.id, AssetId('a', 'lib/a.dart'));
      expect(file.hidden, true);
      expect(file.toString(), 'cache:a|lib/a.dart');
    });

    test('equality and hashCode', () {
      final file1 = AssetFile.source(AssetId('a', 'lib/a.dart'));
      final file2 = AssetFile.source(AssetId('a', 'lib/a.dart'));
      final file3 = AssetFile.cache(AssetId('a', 'lib/a.dart'));

      expect(file1, equals(file2));
      expect(file1.hashCode, equals(file2.hashCode));
      expect(file1, isNot(equals(file3)));
    });
  });
}
