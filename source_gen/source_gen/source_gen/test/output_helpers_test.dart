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
        () => new Future.value(new Stream.fromIterable(['value'])), ['value']);
  });

  group('invalid values', () {
    _testSimpleValue('number', 42, [badValueErrorMessage(42)]);
    _testSimpleValue('mixed good and bad', ['good', 42, 'also good'],
        ['good', badValueErrorMessage(42), 'also good']);

    var badInstance = new _ThrowOnToString();
    _testSimpleValue(
        'really bad class', badInstance, [badValueErrorMessage(badInstance)]);

    _testSimpleValue('iterable with errors', _throwingIterable(),
        ['a', 'b', 'Error in iterator!']);

    _testFunction('sync throw', () => throw new ArgumentError('Error message'),
        ['Error message']);

    _testFunction(
        'new Future.error',
        () => new Future.error(new ArgumentError('Error message')),
        ['Error message']);

    _testFunction(
        'throw in async',
        () async => throw new ArgumentError('Error message'),
        ['Error message']);
  });
}

void _testSimpleValue(String testName, Object value, List expected) {
  _testFunction(testName, () => value, expected);

  assert(value is! Future);

  _testFunction('Future<$testName>', () => new Future.value(value), expected);

  if (value is Iterable) {
    _testFunction('Stream with values from $testName',
        () => safeIteratorToStream(value), expected);
  } else {
    _testFunction('Stream single value $testName',
        () => new Stream.fromIterable([value]), expected);
  }
}

/// [expected] contains the [String] items expected from the [Stream] returned
/// by [normalizeGeneratorOutput].
///
/// If the stream returned by [normalizeGeneratorOutput] has errors of type
/// [ArgumentError], they are transformed into strings containing the content
/// of `toString` on the error. You can validate error behavior by including
/// the `message` content of any expected errors in [expected].
void _testFunction(String testName, Object func(), List expected) {
  test(testName, () async {
    var items = await normalizeGeneratorOutput(func).transform(
        new StreamTransformer<String, String>.fromHandlers(
            handleError: (error, stack, sink) {
      if (error is ArgumentError) {
        sink.add(error.message.toString());
      } else {
        printOnFailure(
            'Careful! Transforming to an error! $error (${error.runtimeType}).');
        sink.addError(error, stack);
      }
    })).toList();

    expect(items, expected);
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
