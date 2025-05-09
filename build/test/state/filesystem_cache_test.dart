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
    group('with non-utf8 encoding', () {
      test('uses the encoding for the bytes representation', () async {
        cache.writeAsString(
          txt1,
          txt1String,
          encoding: OneWayUtf8IncompatibleEncoding(),
          writer: () {},
        );
        expect(
          cache.readAsBytes(txt1, ifAbsent: () => throw UnimplementedError()),
          Utf8IncompatibleEncoding().encoder.convert(txt1String),
        );
      });

      test('converts from bytes instead of using the String cache', () async {
        cache.writeAsString(
          txt1,
          txt1String,
          encoding: OneWayUtf8IncompatibleEncoding(),
          writer: () {},
        );

        // Check the decode is used by passing a decoder that throws.
        expect(
          () => cache.readAsString(
            txt1,
            encoding: OneWayUtf8IncompatibleEncoding(),
            ifAbsent: () => throw UnimplementedError(),
          ),
          throwsA(isA<UnimplementedError>()),
        );

        // Pass the real decoder and check the result.
        expect(
          cache.readAsString(
            txt1,
            encoding: Utf8IncompatibleEncoding(),
            ifAbsent: () => throw UnimplementedError(),
          ),
          txt1String,
        );

        // Read as UTF-8 should fail.
        expect(
          () => cache.readAsString(
            txt1,
            encoding: utf8,
            ifAbsent: () => throw UnimplementedError(),
          ),
          throwsA(isA<FormatException>()),
        );
      });
    });

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

/// An encoding that produces bytes that are not valid UTF-8.
class Utf8IncompatibleEncoding extends Encoding {
  @override
  Converter<List<int>, String> get decoder => Utf8IncompatibleDecoder();

  @override
  Converter<String, List<int>> get encoder => Utf8IncompatibleEncoder();

  @override
  String get name => 'TestEncoding';
}

/// An encoder that produces bytes that are not valid UTF-8.
///
/// The bytes are UTF-8 prefixed with four 0xff.
class Utf8IncompatibleEncoder extends Converter<String, List<int>> {
  @override
  List<int> convert(String input) => [
    0xff,
    0xff,
    0xff,
    0xff,
    ...utf8.encode(input),
  ];
}

class Utf8IncompatibleDecoder extends Converter<List<int>, String> {
  @override
  String convert(List<int> input) {
    for (var i = 0; i != 4; ++i) {
      if (input[i] != 0xff) throw ArgumentError('Expected four 0xff .');
    }
    return utf8.decode(input.skip(4).toList());
  }
}

/// [Utf8IncompatibleEncoding] but throws on decode.
class OneWayUtf8IncompatibleEncoding extends Utf8IncompatibleEncoding {
  @override
  Converter<List<int>, String> get decoder => throw UnimplementedError();
}
