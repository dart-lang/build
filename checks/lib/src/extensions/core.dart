import 'package:checks/context.dart';

extension TypeChecks on Check<Object?> {
  Check<T> isA<T>() {
    return context.nest<T>('is a $T', (v) {
      if (v is! T) {
        return CheckResult(
            Rejection(actual: literal(v), which: 'Is a ${v.runtimeType}'),
            null);
      }
      return CheckResult(null, v);
    }, atSameLevel: true);
  }
}

extension HasField<T> on Check<T> {
  Check<R> has<R>(R Function(T) extract, String name) {
    return context.nest('has $name', (T value) {
      try {
        return CheckResult(null, extract(value));
      } catch (_) {
        return CheckResult<R>(
            Rejection(
                actual: literal(value),
                which: 'threw while trying to read property'),
            null);
      }
    });
  }

  // Help with nested castades.
  void that(void Function(Check<T>) condition) {
    condition(this);
  }
}

extension BoolChecks on Check<bool> {
  void isTrue() {
    context.expect(() => ['is true'], (v) {
      if (v) return null;
      return Rejection(actual: literal(v));
    });
  }

  void isFalse() {
    context.expect(() => ['is false'], (v) {
      if (!v) return null;
      return Rejection(actual: literal(v));
    });
  }
}

extension EqualityChecks<T> on Check<T> {
  void equals(T other) {
    context.expect(() => ['equals ${literal(other)}'], (v) {
      if (v == other) return null;
      return Rejection(actual: literal(v), which: 'is not equal');
    });
  }

  void identicalTo(T other) {
    context.expect(() => ['is identical to ${literal(other)}'], (v) {
      if (identical(v, other)) return null;
      return Rejection(actual: literal(v), which: 'is not identical');
    });
  }
}

extension NullabilityChecks<T> on Check<T?> {
  Check<T> isNotNull() {
    return context.nest<T>('is not null', (v) {
      if (v == null) return CheckResult(Rejection(actual: literal(v)), null);
      return CheckResult(null, v);
    }, atSameLevel: true);
  }

  void isNull() {
    context.expect(() => const ['is null'], (v) {
      if (v != null) return Rejection(actual: literal(v));
      return null;
    });
  }
}

extension StringChecks on Check<String> {
  void contains(Pattern pattern) {
    context.expect(() => ['contains $pattern'], (s) {
      if (s.contains(pattern)) return null;
      return Rejection(actual: literal(s), which: 'Does not contain $pattern');
    });
  }
}
