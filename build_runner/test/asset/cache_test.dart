// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:test/test.dart';

import 'package:build_runner/src/asset/cache.dart';

import '../common/common.dart';

void main() {
  var fooTxt = new AssetId('a', 'foo.txt');
  var missingTxt = new AssetId('a', 'missing.txt');
  var fooContent = 'bar';
  var fooUTF8Bytes = decodedMatches('bar');
  var assets = <AssetId, dynamic>{
    fooTxt: 'bar',
  };
  InMemoryRunnerAssetReader delegate;
  CachingAssetReader reader;

  setUp(() {
    delegate = new InMemoryRunnerAssetReader(assets);
    reader = new CachingAssetReader(delegate);
  });

  group('canRead', () {
    test('should read from the delegate', () async {
      expect(await reader.canRead(fooTxt), isTrue);
      expect(await reader.canRead(missingTxt), isFalse);
      expect(delegate.assetsRead, [fooTxt, missingTxt]);
    });

    test('should not re-read from the delegate', () async {
      expect(await reader.canRead(fooTxt), isTrue);
      delegate.assetsRead.clear();
      expect(await reader.canRead(fooTxt), isTrue);
      expect(delegate.assetsRead, []);
    });

    test('can be invalidated with invalidate', () async {
      expect(await reader.canRead(fooTxt), isTrue);
      delegate.assetsRead.clear();
      expect(delegate.assetsRead, []);

      reader.invalidate([fooTxt]);
      expect(await reader.canRead(fooTxt), isTrue);
      expect(delegate.assetsRead, [fooTxt]);
    });
  });

  group('readAsBytes', () {
    test('should read from the delegate', () async {
      expect(await reader.readAsBytes(fooTxt), fooUTF8Bytes);
      expect(delegate.assetsRead, [fooTxt]);
    });

    test('should not re-read from the delegate', () async {
      expect(await reader.readAsBytes(fooTxt), fooUTF8Bytes);
      delegate.assetsRead.clear();
      expect(await reader.readAsBytes(fooTxt), fooUTF8Bytes);
      expect(delegate.assetsRead, []);
    });

    test('can be invalidated with invalidate', () async {
      expect(await reader.readAsBytes(fooTxt), fooUTF8Bytes);
      delegate.assetsRead.clear();
      expect(delegate.assetsRead, []);

      reader.invalidate([fooTxt]);
      expect(await reader.readAsBytes(fooTxt), fooUTF8Bytes);
      expect(delegate.assetsRead, [fooTxt]);
    });

    test('caches bytes from readAsString calls', () async {
      expect(await reader.readAsString(fooTxt), fooContent);
      expect(delegate.assetsRead, [fooTxt]);
      delegate.assetsRead.clear();

      expect(await reader.readAsBytes(fooTxt), fooUTF8Bytes);
      expect(delegate.assetsRead, []);
    });
  });

  group('readAsString', () {
    test('should read from the delegate', () async {
      expect(await reader.readAsString(fooTxt), fooContent);
      expect(delegate.assetsRead, [fooTxt]);
    });

    test('should not re-read from the delegate', () async {
      expect(await reader.readAsString(fooTxt), fooContent);
      delegate.assetsRead.clear();
      expect(await reader.readAsString(fooTxt), fooContent);
      expect(delegate.assetsRead, []);
    });

    test('can be invalidated with invalidate', () async {
      expect(await reader.readAsString(fooTxt), fooContent);
      delegate.assetsRead.clear();
      expect(delegate.assetsRead, []);

      reader.invalidate([fooTxt]);
      expect(await reader.readAsString(fooTxt), fooContent);
      expect(delegate.assetsRead, [fooTxt]);
    });

    test('uses cached bytes if available', () async {
      expect(await reader.readAsBytes(fooTxt), fooUTF8Bytes);
      expect(delegate.assetsRead, [fooTxt]);
      delegate.assetsRead.clear();

      expect(await reader.readAsString(fooTxt), fooContent);
      expect(delegate.assetsRead, []);
    });
  });

  group('digest', () {
    test('should read from the delegate', () async {
      expect(await reader.digest(fooTxt), isNotNull);
      expect(delegate.assetsRead, [fooTxt]);
    });

    test('should re-read from the delegate (no cache)', () async {
      expect(await reader.digest(fooTxt), isNotNull);
      delegate.assetsRead.clear();
      expect(await reader.digest(fooTxt), isNotNull);
      expect(delegate.assetsRead, [fooTxt]);
    });
  });
}
