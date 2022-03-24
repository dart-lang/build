import 'dart:async';

import 'package:test_api/hooks.dart';

import 'describe.dart';

class Check<T> {
  final Context<T> _context;
  Check._(this._context);

  Check<T> skip(String message) {
    TestHandle.current.markSkipped(message);
    return Check._(_SkippedContext());
  }
}

Check<T> checkThat<T>(T value, {String? reason}) => Check._(_TestContext._(
    _Present(value),
    'a $T',
    reason,
    null,
    [],
    (m, _) => throw TestFailure(m),
    [],
    true));

Rejection? softCheck<T>(T value, void Function(Check<T>) condition) {
  Rejection? rejection;
  final check = Check._(
      _TestContext<T>._(_Present(value), 'a $T', null, null, [], (_, r) {
    rejection = r;
  }, [], false));
  condition(check);
  return rejection;
}

Iterable<String> describe<T>(void Function(Check<T>) condition) {
  final context = _TestContext<T>._(_Absent(), '', null, null, [], (_, __) {
    throw UnimplementedError();
  }, [], true);
  condition(Check._(context));
  return context.expected.skip(1);
}

extension ContextExtension<T> on Check<T> {
  Context<T> get context => _context;
}

// How matcher extensions interact with this library.
//
// `expect` and `expectAsync` can test the value and optionally reject it.
// `nest` and `nestAsync` can test the value, and also extract some other
// property from it for further checking.
abstract class Context<T> {
  void expect(
      Iterable<String> Function() clause, Rejection? Function(T) predicate);
  Future<void> expectAsync<R>(Iterable<String> Function() clause,
      FutureOr<Rejection?> Function(T) predicate);
  Check<R> nest<R>(String label, Extracted<R> Function(T) extract,
      {bool atSameLevel = false});
  Future<Check<R>> nestAsync<R>(
      String label, FutureOr<Extracted<R>> Function(T) extract);
}

class Extracted<T> {
  final Rejection? rejection;
  final T? value;
  Extracted.rejection({required String actual, Iterable<String>? which})
      : this.rejection = Rejection(actual: actual, which: which),
        this.value = null;
  Extracted.value(this.value) : this.rejection = null;

  Extracted._(this.rejection) : this.value = null;

  Extracted<R> map<R>(R Function(T) transform) {
    if (rejection != null) return Extracted._(rejection);
    return Extracted.value(transform(value as T));
  }
}

abstract class _Value<T> {
  R? apply<R extends FutureOr<Rejection?>>(R Function(T) callback);
  Future<Extracted<_Value<R>>> mapAsync<R>(
      FutureOr<Extracted<R>> Function(T) transform);
  Extracted<_Value<R>> map<R>(Extracted<R> Function(T) transform);
}

class _Present<T> implements _Value<T> {
  final T value;
  _Present(this.value);

  @override
  R? apply<R extends FutureOr<Rejection?>>(R Function(T) c) => c(value);

  @override
  Future<Extracted<_Value<R>>> mapAsync<R>(
      FutureOr<Extracted<R>> Function(T) transform) async {
    final transformed = await transform(value);
    return transformed.map((v) => _Present(v));
  }

  @override
  Extracted<_Value<R>> map<R>(Extracted<R> Function(T) transform) =>
      transform(value).map((v) => _Present(v));
}

class _Absent<T> implements _Value<T> {
  @override
  R? apply<R extends FutureOr<Rejection?>>(R Function(T) c) => null;

  @override
  Future<Extracted<_Value<R>>> mapAsync<R>(
          FutureOr<Extracted<R>> Function(T) transform) async =>
      Extracted.value(_Absent<R>());

  @override
  Extracted<_Value<R>> map<R>(FutureOr<Extracted<R>> Function(T) transform) =>
      Extracted.value(_Absent<R>());
}

class _TestContext<T> implements Context<T>, ClauseDescription {
  final _Value<T> _value;
  final _TestContext<dynamic>? _parent;

  final List<ClauseDescription> _clauses;
  final List<_TestContext> _siblings;

  // The "a value" in "a value that:".
  final String _label;
  final String? _reason;

  final void Function(String, Rejection?) _fail;

  final bool _allowAsync;

  _TestContext._(this._value, this._label, this._reason, this._parent,
      this._clauses, this._fail, this._siblings, this._allowAsync);

  @override
  void expect(
      Iterable<String> Function() clause, Rejection? Function(T) predicate) {
    _clauses.add(StringClause(clause));
    final rejection = _value.apply(predicate);
    if (rejection != null) {
      _fail(_failure(rejection), rejection);
    }
  }

  @override
  Future<void> expectAsync<R>(Iterable<String> Function() clause,
      FutureOr<Rejection?> Function(T) predicate) async {
    if (!_allowAsync) {
      throw StateError(
          'Async expectations cannot be used in a synchronous check');
    }
    _clauses.add(StringClause(clause));
    final outstandingWork = TestHandle.current.markPending();
    final rejection = await _value.apply(predicate);
    outstandingWork.complete();
    if (rejection == null) return;
    _fail(_failure(rejection), rejection);
  }

  String _failure(Rejection rejection) {
    final root = _root;
    return [
      ..._prefixFirst('Expected: ', root.expected),
      ..._prefixFirst('Actual: ', root.actual(rejection, this)),
      if (_reason != null) 'Reason: $_reason',
    ].join('\n');
  }

  @override
  Check<R> nest<R>(String label, Extracted<R> Function(T) extract,
      {bool atSameLevel = false}) {
    final result = _value.map(extract);
    final rejection = result.rejection;
    if (rejection != null) {
      _clauses.add(StringClause(() => [label]));
      _fail(_failure(rejection), rejection);
    }
    final value = result.value ?? _Absent<R>();
    final _TestContext<R> context;
    if (atSameLevel) {
      context = _TestContext._(value, _label, null, _parent, _clauses, _fail,
          _siblings, _allowAsync);
      _siblings.add(context);
      _clauses.add(StringClause(() => [label]));
    } else {
      context =
          _TestContext._(value, label, null, this, [], _fail, [], _allowAsync);
      _clauses.add(context);
    }
    return Check._(context);
  }

  @override
  Future<Check<R>> nestAsync<R>(
      String label, FutureOr<Extracted<R>> Function(T) extract) async {
    if (!_allowAsync) {
      throw StateError(
          'Async expectations cannot be used in a synchronous check');
    }
    final outstandingWork = TestHandle.current.markPending();
    final result = await _value.mapAsync(extract);
    outstandingWork.complete();
    final rejection = result.rejection;
    if (rejection != null) {
      _clauses.add(StringClause(() => [label]));
      _fail(_failure(rejection), rejection);
    }
    // TODO - does this need null fallback instead?
    final value = result.value as _Value<R>;
    final context =
        _TestContext<R>._(value, label, null, this, [], _fail, [], _allowAsync);
    _clauses.add(context);
    return Check._(context);
  }

  _TestContext get _root {
    _TestContext<dynamic> current = this;
    while (current._parent != null) {
      current = current._parent!;
    }
    return current;
  }

  @override
  Iterable<String> get expected {
    assert(_clauses.isNotEmpty);
    return [
      '$_label that:',
      for (var clause in _clauses) ...indent(clause.expected),
    ];
  }

  @override
  Iterable<String> actual(Rejection rejection, Context<dynamic> failedContext) {
    if (identical(failedContext, this) || _siblings.contains(failedContext)) {
      final which = rejection.which;
      return [
        if (_parent != null) '$_label that:',
        '${_parent != null ? 'Actual: ' : ''}${rejection.actual}',
        if (which != null && which.isNotEmpty) ..._prefixFirst('Which: ', which)
      ];
    } else {
      return [
        '$_label that:',
        for (var clause in _clauses)
          ...indent(clause.actual(rejection, failedContext))
      ];
    }
  }
}

class _SkippedContext<T> implements Context<T> {
  @override
  void expect(
      Iterable<String> Function() clause, Rejection? Function(T) predicate) {
    // Ignore
  }

  @override
  Future<void> expectAsync<R>(Iterable<String> Function() clause,
      FutureOr<Rejection?> Function(T) predicate) async {
    // Ignore
  }

  @override
  Check<R> nest<R>(String label, Extracted<R> Function(T p1) extract,
      {bool atSameLevel = false}) {
    return Check._(_SkippedContext());
  }

  @override
  Future<Check<R>> nestAsync<R>(
      String label, FutureOr<Extracted<R>> Function(T p1) extract) async {
    return Check._(_SkippedContext());
  }
}

abstract class ClauseDescription {
  Iterable<String> get expected;
  Iterable<String> actual(Rejection rejection, Context<dynamic> context);
}

class StringClause implements ClauseDescription {
  final Iterable<String> Function() _expected;
  @override
  Iterable<String> get expected => _expected();
  StringClause(this._expected);
  // Assumes this will never get called when it was this clause that failed
  // because the TestContext that fails never inspect it's clauses and just
  // prints the failed one.
  // TODO: better way to model this?
  @override
  Iterable<String> actual(Rejection rejection, Context<dynamic> context) =>
      expected;
}

class Rejection {
  final String actual;
  final Iterable<String>? which;

  Rejection({required this.actual, this.which});
}

Iterable<String> _prefixFirst(String prefix, Iterable<String> lines) sync* {
  var isFirst = true;
  for (var line in lines) {
    if (isFirst) {
      yield '$prefix$line';
      isFirst = false;
    } else {
      yield line;
    }
  }
}
