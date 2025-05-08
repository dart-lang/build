// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:build/src/state/filesystem_cache.dart';
import 'package:test/test.dart';

void main() {
  final txt1 = AssetId('a', 'foo.txt');
  final txt1String = 'txt1';
  final txt1Bytes = utf8.encode(txt1String);

  final txt2 = AssetId('a', 'missing.txt');
  final txt2String = 'txt2';
  final txt2Bytes = utf8.encode(txt2String);

  late FilesystemCache cache;

  setUp(() {
    cache = InMemoryFilesystemCache();
  });

  group('exists', () {
    test('reads from ifAbsent', () {
      expect(cache.exists(txt1, ifAbsent: () => true), isTrue);
      expect(cache.exists(txt2, ifAbsent: () => false), isFalse);
    });

    test('does not re-read from ifAbsent', () {
      expect(cache.exists(txt1, ifAbsent: () => true), isTrue);
      expect(
        cache.exists(txt1, ifAbsent: () => false),
        isTrue /* cached value */,
      );
    });

    test('can be invalidated with invalidate', () {
      expect(cache.exists(txt1, ifAbsent: () => true), isTrue);
      cache.invalidate([txt1]);
      expect(
        cache.exists(txt1, ifAbsent: () => false),
        isFalse /* updated value */,
      );
    });
  });

  group('readAsBytes', () {
    test('reads from ifAbsent', () {
      expect(cache.readAsBytes(txt1, ifAbsent: () => txt1Bytes), txt1Bytes);
    });

    test('does not re-read from ifAbsent', () {
      expect(cache.readAsBytes(txt1, ifAbsent: () => txt1Bytes), txt1Bytes);
      expect(
        cache.readAsBytes(txt1, ifAbsent: () => txt2Bytes),
        txt1Bytes /* cached value */,
      );
    });

    test('can be invalidated with invalidate', () {
      expect(cache.readAsBytes(txt1, ifAbsent: () => txt1Bytes), txt1Bytes);
      cache.invalidate([txt1]);
      expect(
        cache.readAsBytes(txt1, ifAbsent: () => txt2Bytes),
        txt2Bytes /* updated value */,
      );
    });
  });

  group('readAsString', () {
    test('reads from isAbsent', () {
      expect(cache.readAsString(txt1, ifAbsent: () => txt1Bytes), txt1String);
    });

    test('does not re-read from isAbsent', () {
      expect(cache.readAsString(txt1, ifAbsent: () => txt1Bytes), txt1String);
      expect(
        cache.readAsString(txt1, ifAbsent: () => txt2Bytes),
        txt1String /* cached value */,
      );
    });

    test('can be invalidated with invalidate', () {
      expect(cache.readAsString(txt1, ifAbsent: () => txt1Bytes), txt1String);
      cache.invalidate([txt1]);
      expect(
        cache.readAsString(txt1, ifAbsent: () => txt2Bytes),
        txt2String /* updated value */,
      );
    });
  });
}
