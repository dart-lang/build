import 'package:checks/context.dart';

extension NumChecks on Check<num> {
  void isGreaterThan(num other) {
    context.expect(() => ['is greater than ${literal(other)}'], (v) {
      if (v > other) return null;
      return Rejection(
          actual: literal(v), which: ['Is not greater than ${literal(other)}']);
    });
  }
}
