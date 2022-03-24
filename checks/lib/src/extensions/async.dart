import 'dart:async';

import 'package:async/async.dart';
import 'package:checks/context.dart';
import 'package:test_api/hooks.dart';

extension FutureChecks<T> on Check<Future<T>> {
  Future<Check<T>> completes() async {
    return await context.nestAsync<T>('Completes to', (v) async {
      try {
        return Extracted.value(await v);
      } catch (e) {
        return Extracted.rejection(
            actual: 'A future that completes to an error',
            which: ['Threw ${literal(e)}']);
      }
    });
  }

  Future<Check<E>> throws<E>() async {
    return await context.nestAsync<E>('Completes as an error of type $E',
        (v) async {
      try {
        return Extracted.rejection(
            actual: 'Completed to ${literal(await v)}',
            which: ['Did not throw']);
      } catch (e) {
        if (e is E) return Extracted.value(e as E);
        return Extracted.rejection(
            actual: 'Completed to error ${literal(e)}',
            which: ['Is not an $E']);
      }
    });
  }
}

extension StreamChecks<T> on Check<StreamQueue<T>> {
  Future<Check<T>> emits() async {
    return await context.nestAsync<T>('Emits a value', (v) async {
      if (!await v.hasNext) {
        return Extracted.rejection(
            actual: 'an empty stream', which: ['did not emit any value']);
      }
      try {
        return Extracted.value(await v.next);
      } catch (e) {
        return Extracted.rejection(
            actual: 'A stream with error ${literal(e)}',
            which: ['emittid an error instead of a value']);
      }
    });
  }

  Future<void> emitsThrough(void Function(Check<T>) condition) async {
    await context.expectAsync(
        () => [
              'Emits any values then a value that:',
              ...indent(describe(condition))
            ], (v) async {
      var count = 0;
      await for (var emitted in v.rest) {
        if (softCheck(emitted, condition) == null) {
          return null;
        }
        count++;
      }
      return Rejection(
          actual: 'a stream',
          which: ['ended after emitting $count elements with none matching']);
    });
  }

  Future<void> neverEmits(void Function(Check<T>) condition) async {
    await context.expectAsync(
        () => ['Never emis a value that:', ...indent(describe(condition))],
        (v) async {
      var count = 0;
      await for (var emitted in v.rest) {
        if (softCheck(emitted, condition) == null) {
          return Rejection(actual: 'a stream', which: [
            'emitted ${literal(emitted)}',
            if (count > 0) 'following $count other items'
          ]);
        }
        count++;
      }
      return null;
    });
  }
}

extension ChainAsync<T> on Future<Check<T>> {
  Future<void> that(FutureOr<void> Function(Check<T>) condition) async {
    await condition(await this);
  }
}

extension IgnoreAsync on Future {
  void byEndOfTest() {
    whenComplete(TestHandle.current.markPending().complete);
  }
}
