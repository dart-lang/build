// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:source_gen/src/output_helpers.dart';
import 'package:test/test.dart';

void main() {
  group('valid values', () {
    _testSimpleValue('null', null, []);
    _testSimpleValue('String', 'string', ['string']);
    _testSimpleValue('empty List', [], []);
    _testSimpleValue('List', ['a', 'b', 'c'], ['a', 'b', 'c']);
    _testSimpleValue('Iterable', new Iterable.generate(3, (i) => i.toString()),
        ['0', '1', '2']);

    _testFunction('Future<Stream>',
        new Future.value(new Stream.fromIterable(['value'])), ['value']);
  });

  group('invalid values', () {
    _testSimpleValue('number', 42, throwsArgumentError);
    _testSimpleValue(
        'mixed good and bad', ['good', 42, 'also good'], throwsArgumentError);

    var badInstance = new _ThrowOnToString();
    _testSimpleValue('really bad class', badInstance, throwsArgumentError);

    _testSimpleValue(
        'iterable with errors', _throwingIterable(), throwsArgumentError);

    _testFunction('sync throw', () => throw new ArgumentError('Error message'),
        throwsArgumentError);

    _testFunction(
        'new Future.error',
        () => new Future.error(new ArgumentError('Error message')),
        throwsArgumentError);

    _testFunction(
        'throw in async',
        () async => throw new ArgumentError('Error message'),
        throwsArgumentError);
  });
}

void _testSimpleValue(String testName, Object value, expected) {
  _testFunction(testName, value, expected);

  assert(value is! Future);

  _testFunction('Future<$testName>', new Future.value(value), expected);

  if (value is Iterable) {
    _testFunction('Stream with values from $testName',
        new Stream.fromIterable(value), expected);
  } else {
    _testFunction('Stream single value $testName',
        new Stream.fromIterable([value]), expected);
  }
}

void _testFunction(String testName, value, expected) {
  test(testName, () async {
    if (expected is List) {
      expect(await normalizeGeneratorOutput(value).toList(), expected);
    } else {
      expect(() => normalizeGeneratorOutput(value).drain(), expected);
    }
  });
}

Iterable<String> _throwingIterable() sync* {
  yield 'a';
  yield 'b';
  throw new ArgumentError('Error in iterator!');
}

class _ThrowOnToString {
  @override
  String toString() {
    throw new UnsupportedError('cannot call toString');
  }
}
