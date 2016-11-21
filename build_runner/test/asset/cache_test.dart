// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'dart:async';

import 'package:test/test.dart';

import 'package:build/build.dart';
import 'package:build_runner/src/asset/cache.dart';

import '../common/common.dart';

void main() {
  AssetCache cache;
  final a = makeAsset();
  final b = makeAsset();
  final c = makeAsset();
  final otherA = makeAsset('${a.id}', 'some other content');

  group('AssetCache', () {
    setUp(() {
      cache = new AssetCache();
      cache..put(a)..put(b)..put(c);
    });

    test('can put assets', () {
      var d = makeAsset();
      expect(cache.put(d), null);
      expect(cache.get(d.id), d);
    });

    test('can get assets', () {
      expect(cache.get(a.id), a);
      expect(cache.get(b.id), b);
      expect(cache.get(c.id), c);
      expect(cache.get(makeAssetId()), isNull);
    });

    test('can check for existence of assets', () {
      expect(cache.contains(a.id), isTrue);
      expect(cache.contains(b.id), isTrue);
      expect(cache.contains(c.id), isTrue);
      expect(cache.contains(makeAssetId()), isFalse);
    });

    test('can remove assets', () {
      expect(cache.remove(b.id), b);
      expect(cache.contains(b.id), isFalse);
      expect(cache.get(b.id), isNull);
    });

    test('put throws if the asset exists and overwrite == false', () {
      var asset = makeAsset('${a.id}');
      expect(() => cache.put(asset), throwsArgumentError);
    });

    test('put doesn\'t throw if the asset exists and overwrite == true', () {
      cache.put(otherA, overwrite: true);
      expect(cache.get(otherA.id), otherA);
      expect(cache.get(a.id), isNot(a));
    });
  });

  group('CachedAssetReader', () {
    CachedAssetReader reader;
    InMemoryAssetReader childReader;
    Map<AssetId, DatedString> childReaderAssets;

    setUp(() {
      cache = new AssetCache();
      childReaderAssets = {};
      childReader = new InMemoryAssetReader(childReaderAssets);
      reader = new CachedAssetReader(cache, childReader);
    });

    test('reads from the cache first', () async {
      expect(a.stringContents, isNot(otherA.stringContents));
      expect(a.id, otherA.id);

      childReaderAssets[otherA.id] = new DatedString(otherA.stringContents);
      cache.put(a);
      expect(await reader.readAsString(a.id), a.stringContents);
    });

    test('falls back on the childReader', () async {
      childReaderAssets[a.id] = new DatedString(a.stringContents);
      expect(await reader.readAsString(a.id), a.stringContents);
    });

    test('reads add values to the cache', () async {
      childReaderAssets[a.id] = new DatedString(a.stringContents);
      await reader.readAsString(a.id);
      expect(cache.get(a.id), equalsAsset(a));
      childReaderAssets.remove(a.id);
      expect(await reader.readAsString(a.id), a.stringContents);
    });

    test('hasInput checks the cache and child reader', () async {
      expect(await reader.hasInput(a.id), isFalse);
      cache.put(a);
      expect(await reader.hasInput(a.id), isTrue);
      childReaderAssets[a.id] = new DatedString(a.stringContents);
      expect(await reader.hasInput(a.id), isTrue);
      cache.remove(a.id);
      expect(await reader.hasInput(a.id), isTrue);
      childReaderAssets.remove(a.id);
      expect(await reader.hasInput(a.id), isFalse);
    });

    test('Multiple readAsString calls wait on the same future', () async {
      childReaderAssets[a.id] = new DatedString(a.stringContents);
      var futures = <Future>[];
      futures.add(reader.readAsString(a.id));
      futures.add(reader.readAsString(a.id));
      expect(futures[0], futures[1]);
      await Future.wait(futures);

      // Subsequent calls should not return the same future.
      expect(reader.readAsString(a.id), isNot(futures[0]));
    });

    test('Multiple hasInput calls return the same future', () async {
      childReaderAssets[a.id] = new DatedString(a.stringContents);
      var futures = <Future>[];
      futures.add(reader.hasInput(a.id));
      futures.add(reader.hasInput(a.id));
      expect(futures[0], futures[1]);
      await Future.wait(futures);

      // Subsequent calls should not return the same future.
      expect(reader.hasInput(a.id), isNot(futures[0]));
    });

    test('lastModified uses the reader', () async {
      expect(reader.lastModified(a.id), throwsA(assetNotFoundException));

      var time = new DateTime.now();
      childReaderAssets[b.id] = new DatedString(b.stringContents, time);
      expect(await reader.lastModified(b.id), time);
    });

    group('async methods will never throw synchronously', () {
      var cache = new _ThrowingCache();
      var reader = new CachedAssetReader(cache, childReader);

      test('hasInput', () {
        return reader.hasInput(a.id).then((_) {
          throw 'future should not succeed';
        }, onError: (_) {});
      });

      test('readAsString', () {
        return reader.readAsString(a.id).then((_) {
          throw 'future should not succeed';
        }, onError: (_) {});
      });
    });
  });

  group('CachedAssetWriter', () {
    CachedAssetWriter writer;
    InMemoryAssetWriter childWriter;
    Map<AssetId, DatedString> childWriterAssets;

    setUp(() {
      cache = new AssetCache();
      childWriter = new InMemoryAssetWriter();
      childWriterAssets = childWriter.assets;
      writer = new CachedAssetWriter(cache, childWriter);
    });

    test('writes to the cache synchronously', () {
      writer.writeAsString(a);
      expect(cache.get(a.id), a);
      expect(childWriterAssets[a.id], isNull);
    });

    test('writes to the cache and the child writer', () async {
      await writer.writeAsString(a);
      expect(cache.get(a.id), a);
      expect(childWriterAssets[a.id].value, a.stringContents);

      await writer.writeAsString(b);
      expect(cache.get(b.id), b);
      expect(childWriterAssets[b.id].value, b.stringContents);
    });

    test('multiple sync writes for the same asset throws', () async {
      writer.writeAsString(a);
      expect(writer.writeAsString(a), throwsArgumentError);
    });

    test('multiple async writes for the same asset throws', () async {
      await writer.writeAsString(a);
      expect(writer.writeAsString(a), throwsArgumentError);
    });

    test('delete deletes from cache and writer', () async {
      await writer.writeAsString(a);
      await writer.delete(a.id);
      expect(cache.get(a.id), isNull);
      expect(childWriterAssets[a.id], isNull);
    });

    group('async methods will never throw synchronously', () {
      var cache = new _ThrowingCache();
      var writer = new CachedAssetWriter(cache, childWriter);

      test('delete', () {
        return writer.delete(a.id).then((_) {
          throw 'future should not succeed';
        }, onError: (_) {});
      });

      test('writeAsString', () {
        return writer.writeAsString(a).then((_) {
          throw 'future should not succeed';
        }, onError: (_) {});
      });
    });
  });
}

class _ThrowingCache implements AssetCache {
  @override
  bool contains(AssetId id) => throw new UnimplementedError();

  @override
  Asset remove(AssetId id) => throw new UnimplementedError();

  @override
  Asset get(AssetId id) => throw new UnimplementedError();

  @override
  void put(Asset id, {bool overwrite: false}) => throw new UnimplementedError();
}
