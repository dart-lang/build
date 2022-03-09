import 'package:async/async.dart';
import 'package:checks/context.dart';

extension FutureChecks<T> on Check<Future<T>> {
  Future<Check<T>> completes() async {
    return await context.nestAsync<T>('Completes to', (v) async {
      try {
        return CheckResult(null, await v);
      } catch (e) {
        return CheckResult(
            Rejection(
                actual: 'A future that completes to an error',
                which: 'Threw ${literal(e)}'),
            null);
      }
    });
  }

  Future<Check<E>> throws<E>() async {
    return await context.nestAsync<E>('Completes as an error of type $E',
        (v) async {
      try {
        return CheckResult(
            Rejection(
                actual: 'Completed to ${literal(await v)}',
                which: 'Did not throw'),
            null);
      } catch (e) {
        if (e is E) return CheckResult(null, e as E);
        return CheckResult(
            Rejection(
                actual: 'Completed to error ${literal(e)}',
                which: 'Is not an $E'),
            null);
      }
    });
  }
}

extension StreamChecks<T> on Check<StreamQueue<T>> {
  Future<Check<T>> emits() async {
    return await context.nestAsync<T>('Emits a value', (v) async {
      if (!await v.hasNext) {
        return CheckResult(
            Rejection(
                actual: 'an empty stream', which: 'did not emit any value'),
            null);
      }
      try {
        return CheckResult(null, await v.next);
      } catch (e) {
        return CheckResult(
            Rejection(
                actual: 'A stream with error ${literal(e)}',
                which: 'emittid an error instead of a value'),
            null);
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
        if (softCheck(emitted, condition)) {
          return null;
        }
        count++;
      }
      return Rejection(
          actual: 'a stream',
          which: 'ended after emitting $count elements with none matching');
    });
  }

  Future<void> neverEmits(void Function(Check<T>) condition) async {
    await context.expectAsync(
        () => ['Never emis a value that:', ...indent(describe(condition))],
        (v) async {
      var count = 0;
      await for (var emitted in v.rest) {
        if (softCheck(emitted, condition)) {
          return Rejection(
              actual: 'a stream',
              which: 'emitted ${literal(emitted)}'
                  '${count > 0 ? ' following $count other items' : ''}');
        }
        count++;
      }
      return null;
    });
  }
}
