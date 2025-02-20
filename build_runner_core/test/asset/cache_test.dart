// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_test_common/common.dart';
import 'package:build/build.dart';
import 'package:build_runner_core/src/asset/cache.dart';
import 'package:test/test.dart';

void main() {
  var fooTxt = AssetId('a', 'foo.txt');
  var missingTxt = AssetId('a', 'missing.txt');
  var fooContent = 'bar';
  var fooutf8Bytes = decodedMatches('bar');
  late InMemoryRunnerAssetReaderWriter delegate;
  late CachingAssetReader reader;

  setUp(() {
    delegate =
        InMemoryRunnerAssetReaderWriter()
          ..filesystem.writeAsStringSync(fooTxt, 'bar');
    reader = CachingAssetReader(delegate);
  });

  group('canRead', () {
    test('should read from the delegate', () async {
      expect(await reader.canRead(fooTxt), isTrue);
      expect(await reader.canRead(missingTxt), isFalse);
      expect(delegate.inputTracker.assetsRead, {fooTxt, missingTxt});
    });

    test('should not re-read from the delegate', () async {
      expect(await reader.canRead(fooTxt), isTrue);
      delegate.inputTracker.assetsRead.clear();
      expect(await reader.canRead(fooTxt), isTrue);
      expect(delegate.inputTracker.assetsRead, isEmpty);
    });

    test('can be invalidated with invalidate', () async {
      expect(await reader.canRead(fooTxt), isTrue);
      delegate.inputTracker.assetsRead.clear();
      expect(delegate.inputTracker.assetsRead, isEmpty);

      reader.invalidate([fooTxt]);
      expect(await reader.canRead(fooTxt), isTrue);
      expect(delegate.inputTracker.assetsRead, [fooTxt]);
    });
  });

  group('readAsBytes', () {
    test('should read from the delegate', () async {
      expect(await reader.readAsBytes(fooTxt), fooutf8Bytes);
      expect(delegate.inputTracker.assetsRead, [fooTxt]);
    });

    test('should not re-read from the delegate', () async {
      expect(await reader.readAsBytes(fooTxt), fooutf8Bytes);
      delegate.inputTracker.assetsRead.clear();
      expect(await reader.readAsBytes(fooTxt), fooutf8Bytes);
      expect(delegate.inputTracker.assetsRead, isEmpty);
    });

    test('can be invalidated with invalidate', () async {
      expect(await reader.readAsBytes(fooTxt), fooutf8Bytes);
      delegate.inputTracker.assetsRead.clear();
      expect(delegate.inputTracker.assetsRead, isEmpty);

      reader.invalidate([fooTxt]);
      expect(await reader.readAsBytes(fooTxt), fooutf8Bytes);
      expect(delegate.inputTracker.assetsRead, [fooTxt]);
    });

    test('should not cache bytes during readAsString calls', () async {
      expect(await reader.readAsString(fooTxt), fooContent);
      expect(delegate.inputTracker.assetsRead, [fooTxt]);
      delegate.inputTracker.assetsRead.clear();

      expect(await reader.readAsBytes(fooTxt), fooutf8Bytes);
      expect(delegate.inputTracker.assetsRead, [fooTxt]);
    });
  });

  group('readAsString', () {
    test('should read from the delegate', () async {
      expect(await reader.readAsString(fooTxt), fooContent);
      expect(delegate.inputTracker.assetsRead, [fooTxt]);
    });

    test('should not re-read from the delegate', () async {
      expect(await reader.readAsString(fooTxt), fooContent);
      delegate.inputTracker.assetsRead.clear();
      expect(await reader.readAsString(fooTxt), fooContent);
      expect(delegate.inputTracker.assetsRead, isEmpty);
    });

    test('can be invalidated with invalidate', () async {
      expect(await reader.readAsString(fooTxt), fooContent);
      delegate.inputTracker.assetsRead.clear();
      expect(delegate.inputTracker.assetsRead, isEmpty);

      reader.invalidate([fooTxt]);
      expect(await reader.readAsString(fooTxt), fooContent);
      expect(delegate.inputTracker.assetsRead, [fooTxt]);
    });

    test('uses cached bytes if available', () async {
      expect(await reader.readAsBytes(fooTxt), fooutf8Bytes);
      expect(delegate.inputTracker.assetsRead, [fooTxt]);
      delegate.inputTracker.assetsRead.clear();

      expect(await reader.readAsString(fooTxt), fooContent);
      expect(delegate.inputTracker.assetsRead, isEmpty);
    });
  });

  group('digest', () {
    test('should read from the delegate', () async {
      expect(await reader.digest(fooTxt), isNotNull);
      expect(delegate.inputTracker.assetsRead, [fooTxt]);
    });

    test('should re-read from the delegate (no cache)', () async {
      expect(await reader.digest(fooTxt), isNotNull);
      delegate.inputTracker.assetsRead.clear();
      expect(await reader.digest(fooTxt), isNotNull);
      expect(delegate.inputTracker.assetsRead, [fooTxt]);
    });
  });
}
