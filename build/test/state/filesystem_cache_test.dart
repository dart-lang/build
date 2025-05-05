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
    test('reads from ifAbsent', () async {
      expect(cache.exists(txt1, ifAbsent: () => true), isTrue);
      expect(cache.exists(txt2, ifAbsent: () => false), isFalse);
    });

    test('does not re-read from ifAbsent', () async {
      expect(cache.exists(txt1, ifAbsent: () => true), isTrue);
      expect(
        cache.exists(txt1, ifAbsent: () => false),
        isTrue /* cached value */,
      );
    });

    test('can be invalidated with invalidate', () async {
      expect(cache.exists(txt1, ifAbsent: () => true), isTrue);
      cache.invalidate([txt1]);
      expect(
        cache.exists(txt1, ifAbsent: () => false),
        isFalse /* updated value */,
      );
    });

    test('reads from latest writeAsBytes without calling ifAbsent', () async {
      cache.writeAsBytes(
        txt1,
        txt1Bytes,
        writer: () => throw UnimplementedError(),
      );
      expect(
        cache.exists(txt1, ifAbsent: () => throw UnimplementedError()),
        true,
      );
    });

    test('reads from writeAsString without calling ifAbsent', () async {
      cache.writeAsString(
        txt1,
        txt1String,
        writer: () => throw UnimplementedError(),
      );
      expect(
        cache.exists(txt1, ifAbsent: () => throw UnimplementedError()),
        true,
      );
    });

    test('reads from delete without calling ifAbsent', () async {
      cache.writeAsString(
        txt1,
        txt1String,
        writer: () => throw UnimplementedError(),
      );
      cache.delete(txt1, deleter: () => throw UnimplementedError());
      expect(
        cache.exists(txt1, ifAbsent: () => throw UnimplementedError()),
        false,
      );
    });
  });

  group('readAsBytes', () {
    test('reads from ifAbsent', () async {
      expect(cache.readAsBytes(txt1, ifAbsent: () => txt1Bytes), txt1Bytes);
    });

    test('does not re-read from ifAbsent', () async {
      expect(cache.readAsBytes(txt1, ifAbsent: () => txt1Bytes), txt1Bytes);
      expect(
        cache.readAsBytes(txt1, ifAbsent: () => txt2Bytes),
        txt1Bytes /* cached value */,
      );
    });

    test('can be invalidated with invalidate', () async {
      expect(cache.readAsBytes(txt1, ifAbsent: () => txt1Bytes), txt1Bytes);
      cache.invalidate([txt1]);
      expect(
        cache.readAsBytes(txt1, ifAbsent: () => txt2Bytes),
        txt2Bytes /* updated value */,
      );
    });

    test('reads from latest writeAsBytes without calling ifAbsent', () async {
      cache.writeAsBytes(
        txt1,
        txt1Bytes,
        writer: () => throw UnimplementedError(),
      );
      expect(
        cache.readAsBytes(txt1, ifAbsent: () => throw UnimplementedError()),
        txt1Bytes,
      );
    });

    test('reads from writeAsString without calling ifAbsent', () async {
      cache.writeAsString(
        txt1,
        txt1String,
        writer: () => throw UnimplementedError(),
      );
      expect(
        cache.readAsBytes(txt1, ifAbsent: () => throw UnimplementedError()),
        txt1Bytes,
      );
    });
  });

  group('readAsString', () {
    test('reads from isAbsent', () async {
      expect(cache.readAsString(txt1, ifAbsent: () => txt1Bytes), txt1String);
    });

    test('does not re-read from isAbsent', () async {
      expect(cache.readAsString(txt1, ifAbsent: () => txt1Bytes), txt1String);
      expect(
        cache.readAsString(txt1, ifAbsent: () => txt2Bytes),
        txt1String /* cached value */,
      );
    });

    test('can be invalidated with invalidate', () async {
      expect(cache.readAsString(txt1, ifAbsent: () => txt1Bytes), txt1String);
      cache.invalidate([txt1]);
      expect(
        cache.readAsString(txt1, ifAbsent: () => txt2Bytes),
        txt2String /* updated value */,
      );
    });

    test('reads from latest writeAsBytes without calling ifAbsent', () async {
      cache.writeAsBytes(
        txt1,
        txt1Bytes,
        writer: () => throw UnimplementedError(),
      );
      expect(
        cache.readAsString(txt1, ifAbsent: () => throw UnimplementedError()),
        txt1String,
      );
    });

    test('reads from writeAsString without calling ifAbsent', () async {
      cache.writeAsString(
        txt1,
        txt1String,
        writer: () => throw UnimplementedError(),
      );
      expect(
        cache.readAsString(txt1, ifAbsent: () => throw UnimplementedError()),
        txt1String,
      );
    });
  });

  group('writeAsBytes', () {
    test('writes on flush', () async {
      var written = false;
      cache.writeAsBytes(
        txt1,
        txt1Bytes,
        writer: () {
          written = true;
        },
      );
      expect(written, isFalse);
      cache.flush();
      expect(written, isTrue);
    });
  });

  group('writeAsString', () {
    test('writes on flush', () async {
      var written = false;
      cache.writeAsString(
        txt1,
        txt1String,
        writer: () {
          written = true;
        },
      );
      expect(written, isFalse);
      cache.flush();
      expect(written, isTrue);
    });
  });

  group('delete', () {
    test('deletes on flush', () async {
      var deleted = false;
      cache.delete(
        txt1,
        deleter: () {
          deleted = true;
        },
      );
      expect(deleted, isFalse);
      cache.flush();
      expect(deleted, isTrue);
    });
  });
}
