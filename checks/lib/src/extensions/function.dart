import 'dart:async';

import 'package:checks/context.dart';

extension ExpectCalled2<R, A1, A2> on Check<R Function(A1, A2)> {
  R Function(A1, A2) isCalled() {
    final completer = Completer<void>();
    R Function(A1, A2)? boundFunction;
    unawaited(context.expectAsync(() => ['is called'], (v) async {
      boundFunction = v;
      await completer.future;
      return null; // Can only fail by never completing.
    }));
    return (a1, a2) {
      completer.complete();
      // TODO - is there something weird about
      // describe<int Function(int, int)>((c) {
      //   var wrapped = c.isCalled();
      //   // wrapped is unusable
      // })
      return boundFunction!.call(a1, a2);
    };
  }
}

extension ThrowsCheck<T> on Check<T Function()> {
  // TODO - try to automatically handle async? Or maybe disallow async?
  Check<E> throws<E>() {
    return context.nest<E>('Completes as an error of type $E', (v) {
      try {
        final result = v();
        return CheckResult(
            Rejection(
                actual: 'Returned ${literal(result)}', which: 'Did not throw'),
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
