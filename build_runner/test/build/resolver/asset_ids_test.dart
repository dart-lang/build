// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/build/resolver/asset_ids.dart';
import 'package:test/test.dart';

void main() {
  group('AssetIdExtension', () {
    group('windowsPath', () {
      test('converts slashes to backslashes', () {
        final id = AssetId('a', 'lib/a.dart');
        expect(id.windowsPath, r'lib\a.dart');
      });

      test('throws if path contains a colon', () {
        final id = AssetId('a', 'lib/foo:a.dart');
        expect(() => id.windowsPath, throwsArgumentError);
      });
    });
  });
}
