import 'dart:async';

import 'package:test_api/hooks.dart';

import 'describe.dart';

/// A target for checking expectations against a value in a test.
///
/// A Check my have a real value, in which case the expectations can be
/// validated or rejected; or it may be a placeholder, in which case
/// expectations describe what would be checked but cannot be rejected.
///
/// Expectations are defined as extension methods specialized on the generic
/// [T]. Expectations can use the [ContextExtension] to interact with the
/// [Context] for this check.
class Check<T> {
  final Context<T> _context;
  Check._(this._context);

  /// Mark the currently running test as skipped and return a [Check] that will
  /// ignore all expectations.
  ///
  /// Any expectations against the return value will not be checked and will not
  /// be included in the "Expected" or "Actual" string representations of a
  /// failure.
  ///
  /// ```dart
  /// checkThat(actual)
  ///     ..stillChecked()
  ///     ..skip('reason the expectation is temporarily not met').notChecked();
  /// ```
  ///
  /// If `skip` is used in a callback passed to `softCheck` or `describe` it
  /// will still mark the test as skipped, even though failing the expectation
  /// would not have otherwise caused the test to fail.
  Check<T> skip(String message) {
    TestHandle.current.markSkipped(message);
    return Check._(_SkippedContext());
  }
}

/// Returns a [Check] that can be used to validate expectations against [value].
///
/// Expectations that are not satisfied throw a [TestFailure] to interrupt the
/// currently running test and mark it as failed.
///
/// If [because] is passed it will be included as a "Reason:" line in failure
/// messages.
///
/// ```dart
/// checkThat(actual).equals(expected);
/// ```
Check<T> checkThat<T>(T value, {String? because}) => Check._(_TestContext._(
    value: _Present(value),
    label: 'a $T',
    reason: because,
    fail: (m, _) => throw TestFailure(m),
    allowAsync: true));

/// Checks whether [value] satifies all expectations invoked in [condition].
///
/// Returns `null` if all expectations are satisfied, otherwise returns the
/// [Rejection] for the first expectation that fails.
///
/// Asynchronous expectations are not allowed in [condition] and will cause a
/// runtime error if they are used.
Rejection? softCheck<T>(T value, void Function(Check<T>) condition) {
  Rejection? rejection;
  final check = Check<T>._(_TestContext._(
      value: _Present(value),
      fail: (_, r) {
        rejection = r;
      },
      allowAsync: false));
  condition(check);
  return rejection;
}

/// Return a String describing the expectations checked by [condition].
///
/// Elements in the returned value are individual lines in the description. An
/// expectation may be a single line, or multiple lines.
///
/// Matches the "Expected: " lines in the output of a failure message if a value
/// did not meet the last expectation in [condition], without the first labeled
/// line.
Iterable<String> describe<T>(void Function(Check<T>) condition) {
  final context = _TestContext<T>._(
      value: _Absent(),
      fail: (_, __) {
        throw UnimplementedError();
      },
      allowAsync: false);
  condition(Check._(context));
  return context.expected.skip(1);
}

extension ContextExtension<T> on Check<T> {
  /// The expectations and nesting context for this check.
  Context<T> get context => _context;
}

/// The expectation and nesting context already applied to a [Check].
///
/// This is the surface of interaction for expectation extension method
/// implementations.
///
/// `expect` and `expectAsync` can test the value and optionally reject it.
/// `nest` and `nestAsync` can test the value, and also extract some other
/// property from it for further checking.
abstract class Context<T> {
  /// Expect that [predicate] will not return a [Rejection] for the checked
  /// value.
  ///
  /// The property that is asserted by this expectation is described by
  /// [clause]. Often this is a single statement like "equals <1>" or "is
  /// greather than 10", but it may be multiple lines such as describing that an
  /// Iterable contains an element meeting a complex expectation. If any element
  /// in the returned iterable contains a newline it may cause problems with
  /// indentation in the output.
  void expect(
      Iterable<String> Function() clause, Rejection? Function(T) predicate);

  /// Expect that [predicate] will not result in a [Rejection] for the checked
  /// value.
  ///
  /// The property that is asserted by this expectation is described by
  /// [clause]. Often this is a single statement like "equals <1>" or "is
  /// greather than 10", but it may be multiple lines such as describing that an
  /// Iterable contains an element meeting a complex expectation. If any element
  /// in the returned iterable contains a newline it may cause problems with
  /// indentation in the output.
  ///
  /// Some context may disallow asynchronous expectations, for instance in
  /// [softCheck] which must synchronously check the value. In those contexts
  /// this method will throw.
  Future<void> expectAsync<R>(Iterable<String> Function() clause,
      FutureOr<Rejection?> Function(T) predicate);

  /// Extract a property from the value for further checking.
  ///
  /// If the property cannot be extracted, [extract] should return an
  /// [Extracted.rejection] describing the problem. Otherwise it should return
  /// an [Extracted.value].
  ///
  /// The [label] will be used preceding "that:" in a description. Expectations
  /// applied to the returned [Check] will follow the label, indented by two
  /// more spaces.
  ///
  /// If [atSameLevel] is true then [R] should be a subtype of [T], and a
  /// returned [Extracted.value] should be the same instance as passed value.
  /// This may be useful to refine the type for further checks. In this case the
  /// label is used like a single line "clause" passed to [expect], and
  /// expectations applied to the return [Check] will behave as if they were
  /// applied to the Check for this context.
  Check<R> nest<R>(String label, Extracted<R> Function(T) extract,
      {bool atSameLevel = false});

  /// Extract an asynchronous property from the value for further checking.
  ///
  /// If the property cannot be extracted, [extract] should return an
  /// [Extracted.rejection] describing the problem. Otherwise it should return
  /// an [Extracted.value].
  ///
  /// The [label] will be used preceding "that:" in a description. Expectations
  /// applied to the returned [Check] will follow the label, indented by two
  /// more spaces.
  ///
  /// Some context may disallow asynchronous expectations, for instance in
  /// [softCheck] which must synchronously check the value. In those contexts
  /// this method will throw.
  Future<Check<R>> nestAsync<R>(
      String label, FutureOr<Extracted<R>> Function(T) extract);
}

/// A property extracted from a value being checked, or a rejection.
class Extracted<T> {
  final Rejection? rejection;
  final T? value;
  Extracted.rejection({required String actual, Iterable<String>? which})
      : this.rejection = Rejection(actual: actual, which: which),
        this.value = null;
  Extracted.value(this.value) : this.rejection = null;

  Extracted._(this.rejection) : this.value = null;

  Extracted<R> _map<R>(R Function(T) transform) {
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
    return transformed._map((v) => _Present(v));
  }

  @override
  Extracted<_Value<R>> map<R>(Extracted<R> Function(T) transform) =>
      transform(value)._map((v) => _Present(v));
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

class _TestContext<T> implements Context<T>, _ClauseDescription {
  final _Value<T> _value;
  final _TestContext<dynamic>? _parent;

  final List<_ClauseDescription> _clauses;
  final List<_TestContext> _aliases;

  // The "a value" in "a value that:".
  final String _label;
  final String? _reason;

  final void Function(String, Rejection?) _fail;

  final bool _allowAsync;

  _TestContext._({
    required _Value<T> value,
    required void Function(String, Rejection?) fail,
    required bool allowAsync,
    String? label,
    String? reason,
  })  : _value = value,
        _label = label ?? '',
        _reason = reason,
        _fail = fail,
        _allowAsync = allowAsync,
        _parent = null,
        _clauses = [],
        _aliases = [];

  _TestContext._alias(_TestContext original, this._value)
      : _parent = original._parent,
        _clauses = original._clauses,
        _aliases = original._aliases,
        _fail = original._fail,
        _allowAsync = original._allowAsync,
        // Properties that are never read from an aliased context
        _label = '',
        _reason = null;

  _TestContext._child(this._value, this._label, _TestContext<dynamic> parent)
      : _parent = parent,
        _fail = parent._fail,
        _allowAsync = parent._allowAsync,
        _clauses = [],
        _aliases = [],
        // Properties that are never read from any context other than root
        _reason = null;

  @override
  void expect(
      Iterable<String> Function() clause, Rejection? Function(T) predicate) {
    _clauses.add(_StringClause(clause));
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
    _clauses.add(_StringClause(clause));
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
      _clauses.add(_StringClause(() => [label]));
      _fail(_failure(rejection), rejection);
    }
    final value = result.value ?? _Absent<R>();
    final _TestContext<R> context;
    if (atSameLevel) {
      context = _TestContext._alias(this, value);
      _aliases.add(context);
      _clauses.add(_StringClause(() => [label]));
    } else {
      context = _TestContext._child(value, label, this);
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
      _clauses.add(_StringClause(() => [label]));
      _fail(_failure(rejection), rejection);
    }
    // TODO - does this need null fallback instead?
    final value = result.value as _Value<R>;
    final context = _TestContext<R>._child(value, label, this);
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
    if (identical(failedContext, this) || _aliases.contains(failedContext)) {
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

abstract class _ClauseDescription {
  Iterable<String> get expected;
  Iterable<String> actual(Rejection rejection, Context<dynamic> context);
}

class _StringClause implements _ClauseDescription {
  final Iterable<String> Function() _expected;
  @override
  Iterable<String> get expected => _expected();
  _StringClause(this._expected);
  // Assumes this will never get called when it was this clause that failed
  // because the TestContext that fails never inspect it's clauses and just
  // prints the failed one.
  // TODO: better way to model this?
  @override
  Iterable<String> actual(Rejection rejection, Context<dynamic> context) =>
      expected;
}

/// A description of a value that failed an expectation.
class Rejection {
  /// A description of the actual value as it relates to the expectation.
  ///
  /// This may use [literal] to show a String representation of the value, or it
  /// may be a description of a specific aspect of the value. For instance an
  /// expectation that a Future completes to a value may describe the actual as
  /// "A Future that completes to an error".
  ///
  /// This is printed following an "Actual: " label in the output of a failure
  /// message. The message will be indented to the level of the expectation in
  /// the description, and printed following the descriptions of any
  /// expectations that have already passed.
  final String actual;

  /// A description of the way that [actual] failed to meet the expectation.
  ///
  /// An expectation can provide extra detail, or focus attention on a specific
  /// part of the value. For instance when comparing multiple elements in a
  /// collection, the rejection may describe that the value "has an unequal
  /// value at index 3".
  ///
  /// Lines should be separate values in the iterable, if any element contains a
  /// newline it may cause problems with indentation in the output.
  ///
  /// When provided, this is printed following a "Which: " label at the end of
  /// the output for the failure message.
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
