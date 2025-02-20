// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:build/build.dart';
import 'package:build/src/state/filesystem_cache.dart';
import 'package:test/test.dart';

void main() {
  final txt1 = AssetId('a', 'foo.txt');
  final txt2 = AssetId('a', 'missing.txt');

  final txt1Bytes = Uint8List.fromList([1, 2, 3]);
  final txt2Bytes = Uint8List.fromList([4, 5, 6]);

  late FilesystemCache cache;

  setUp(() {
    cache = InMemoryFilesystemCache();
  });

  group('exists', () {
    test('reads from ifAbsent', () async {
      expect(await cache.exists(txt1, ifAbsent: () async => true), isTrue);
      expect(await cache.exists(txt2, ifAbsent: () async => false), isFalse);
    });

    test('does not re-read from ifAbsent', () async {
      expect(await cache.exists(txt1, ifAbsent: () async => true), isTrue);
      expect(
        await cache.exists(txt1, ifAbsent: () async => false),
        isTrue /* cached value */,
      );
    });

    test('can be invalidated with invalidate', () async {
      expect(await cache.exists(txt1, ifAbsent: () async => true), isTrue);
      await cache.invalidate([txt1]);
      expect(
        await cache.exists(txt1, ifAbsent: () async => false),
        isFalse /* updated value */,
      );
    });
  });

  group('readAsBytes', () {
    test('reads from ifAbsent', () async {
      expect(
        await cache.readAsBytes(txt1, ifAbsent: () async => txt1Bytes),
        txt1Bytes,
      );
    });

    test('does not re-read from ifAbsent', () async {
      expect(
        await cache.readAsBytes(txt1, ifAbsent: () async => txt1Bytes),
        txt1Bytes,
      );
      expect(
        await cache.readAsBytes(txt1, ifAbsent: () async => txt2Bytes),
        txt1Bytes /* cached value */,
      );
    });

    test('can be invalidated with invalidate', () async {
      expect(
        await cache.readAsBytes(txt1, ifAbsent: () async => txt1Bytes),
        txt1Bytes,
      );
      await cache.invalidate([txt1]);
      expect(
        await cache.readAsBytes(txt1, ifAbsent: () async => txt2Bytes),
        txt2Bytes /* updated value */,
      );
    });
  });

  group('readAsString', () {
    test('reads from isAbsent', () async {
      expect(await cache.readAsString(txt1, ifAbsent: () async => '1'), '1');
    });

    test('does not re-read from isAbsent', () async {
      expect(await cache.readAsString(txt1, ifAbsent: () async => '1'), '1');
      expect(
        await cache.readAsString(txt1, ifAbsent: () async => '2'),
        '1' /* cached value */,
      );
    });

    test('can be invalidated with invalidate', () async {
      expect(await cache.readAsString(txt1, ifAbsent: () async => '1'), '1');
      await cache.invalidate([txt1]);
      expect(
        await cache.readAsString(txt1, ifAbsent: () async => '2'),
        '2' /* updated value */,
      );
    });
  });
}
