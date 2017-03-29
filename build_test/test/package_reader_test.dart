// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

void main() {
  group('$PackageAssetReader', () {
    AssetReader reader;

    final buildTest = new AssetId('build_test', 'lib/build_test.dart');
    final buildMissing = new AssetId('build_test', 'lib/build_missing.dart');

    setUp(() async {
      reader = await PackageAssetReader.currentIsolate(
        rootPackage: 'build_test',
      );
    });

    test('should be able to read `build_test.dart`', () async {
      expect(await reader.hasInput(buildTest), isTrue);
      expect(await reader.readAsString(buildTest), isNotEmpty);
    });

    test('should not be able to read a missing file', () async {
      expect(await reader.hasInput(buildMissing), isFalse);
    });

    test('should be able to use `findAssets`', () {
      expect(reader.findAssets(new Glob('lib/*.dart')), [
        buildTest,
      ]);
    });
  });
}
