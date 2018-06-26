// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';

/// Runs [run] and converts [Future], [Iterable], and [Stream] implementations
/// containing [String] to a single [Stream] while ensuring all thrown
/// exceptions are forwarded through the return value.
Stream<String> normalizeGeneratorOutput(dynamic run()) =>
    StreamCompleter.fromFuture(
        new Future.sync(run).then(_normalizeGeneratorOutput));

Stream<String> _normalizeGeneratorOutput(Object value) {
  if (value is String) {
    value = [value];
  }

  value ??= [];

  if (value is Iterable) {
    value = safeIteratorToStream(value as Iterable);
  }

  if (value is Stream) {
    return value.where((e) => e != null).map((e) {
      if (e is String) {
        return e;
      }

      throw _argError(e);
    });
  }
  throw _argError(value);
}

/// `Stream.fromIterable` has some weird behavior with errors. See
/// See https://github.com/dart-lang/sdk/issues/33431
Stream safeIteratorToStream(Iterable source) {
  var controller = new StreamController();

  new Future(() {
    try {
      var iterator = source.iterator;
      while (iterator.moveNext()) {
        controller.add(iterator.current);
      }
    } catch (e, stack) {
      controller.addError(e, stack);
    } finally {
      controller.close();
    }
  });

  return controller.stream;
}

ArgumentError _argError(Object value) =>
    new ArgumentError(badValueErrorMessage(value));

String badValueErrorMessage(Object value) =>
    'Must be a String or be an Iterable/Stream containing String values. '
    'Found `${Error.safeToString(value)}` (${value.runtimeType}).';
