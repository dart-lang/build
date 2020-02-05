// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_modules/src/module_cache.dart';

void main() {
  group(DecodingCache, () {
    Map<String, int> toBytesCalls;
    Map<String, int> fromBytesCalls;
    DecodingCache<String> cache;
    ResourceManager resourceManager;

    setUp(() async {
      toBytesCalls = {};
      fromBytesCalls = {};
      final resource = DecodingCache.resource<String>((bytes) {
        var decoded = utf8.decode(bytes);
        fromBytesCalls.putIfAbsent(decoded, () => 0);
        fromBytesCalls[decoded] += 1;
        return decoded;
      }, (value) {
        toBytesCalls.putIfAbsent(value, () => 0);
        toBytesCalls[value] += 1;
        return utf8.encode(value);
      });
      resourceManager = ResourceManager();
      cache = await resourceManager.fetch(resource);
    });

    tearDown(() async {
      await resourceManager.beforeExit();
    });

    test('can fetch from disk', () async {
      final id = AssetId('foo', 'lib/foo');
      final reader = InMemoryAssetReader(sourceAssets: {id: 'foo'});
      expect(await cache.find(id, reader), 'foo');
      expect(reader.assetsRead, contains(id));
      expect(fromBytesCalls, contains('foo'));
    });

    test('skips read for value written this build', () async {
      final id = AssetId('foo', 'lib/foo');
      final reader = InMemoryAssetReader(sourceAssets: {id: 'foo'});
      await cache.write(id, InMemoryAssetWriter(), 'bar');
      expect(await cache.find(id, reader), 'bar');
      expect(reader.assetsRead, contains(id), reason: 'Should call canRead');
      expect(fromBytesCalls, isNot(contains('bar')));
    });

    test('skips read on subsequent fetches', () async {
      final id = AssetId('foo', 'lib/foo');
      final reader1 = InMemoryAssetReader(sourceAssets: {id: 'foo'});
      await cache.find(id, reader1);
      expect(fromBytesCalls['foo'], 1);
      final reader2 = InMemoryAssetReader(sourceAssets: {id: 'foo'});
      expect(await cache.find(id, reader2), 'foo');
      expect(reader2.assetsRead, contains(id), reason: 'Should call canRead');
      expect(fromBytesCalls['foo'], 1, reason: 'No extra call to deserialize');
    });

    test('skips read on subsequent builds if digest has not changed', () async {
      final id = AssetId('foo', 'lib/foo');
      final reader1 = InMemoryAssetReader(sourceAssets: {id: 'foo'});
      await cache.find(id, reader1);
      expect(fromBytesCalls['foo'], 1);
      await resourceManager.disposeAll();
      final reader2 = InMemoryAssetReader(sourceAssets: {id: 'foo'});
      expect(await cache.find(id, reader2), 'foo');
      expect(reader2.assetsRead, contains(id), reason: 'Should call canRead');
      expect(fromBytesCalls['foo'], 1, reason: 'No extra call to deserialize');
    });

    test('rereads on subsequent builds if digest has changed', () async {
      final id = AssetId('foo', 'lib/foo');
      final reader1 = InMemoryAssetReader(sourceAssets: {id: 'foo'});
      await cache.find(id, reader1);
      expect(fromBytesCalls['foo'], 1);
      await resourceManager.disposeAll();
      final reader2 = InMemoryAssetReader(sourceAssets: {id: 'bar'});
      expect(await cache.find(id, reader2), 'bar');
      expect(reader2.assetsRead, contains(id));
      expect(fromBytesCalls['bar'], 1, reason: 'Deserialize with new value');
    });
  });
}
