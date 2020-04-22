// Copyright 2016 Dart Mockito authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:mockito/src/call_pair.dart';
import 'package:mockito/src/invocation_matcher.dart';
// ignore: deprecated_member_use
import 'package:test_api/test_api.dart';
// TODO(srawlins): Remove this when we no longer need to check for an
// incompatiblity between test_api and test.
// https://github.com/dart-lang/mockito/issues/175
import 'package:test_api/src/backend/invoker.dart';

bool _whenInProgress = false;
bool _untilCalledInProgress = false;
bool _verificationInProgress = false;
_WhenCall _whenCall;
_UntilCall _untilCall;
final List<_VerifyCall> _verifyCalls = <_VerifyCall>[];
final _TimeStampProvider _timer = _TimeStampProvider();
final List<dynamic> _capturedArgs = [];
final List<ArgMatcher> _storedArgs = <ArgMatcher>[];
final Map<String, ArgMatcher> _storedNamedArgs = <String, ArgMatcher>{};

@Deprecated(
    'This function is not a supported function, and may be deleted as early as '
    'Mockito 5.0.0')
void setDefaultResponse(
    Mock mock, CallPair<dynamic> Function() defaultResponse) {
  mock._defaultResponse = defaultResponse;
}

/// Opt-into [Mock] throwing [NoSuchMethodError] for unimplemented methods.
///
/// The default behavior when not using this is to always return `null`.
void throwOnMissingStub(Mock mock) {
  mock._defaultResponse =
      () => CallPair<dynamic>.allInvocations(mock._noSuchMethod);
}

/// Extend or mixin this class to mark the implementation as a [Mock].
///
/// A mocked class implements all fields and methods with a default
/// implementation that does not throw a [NoSuchMethodError], and may be further
/// customized at runtime to define how it may behave using [when].
///
/// __Example use__:
///
///     // Real class.
///     class Cat {
///       String getSound(String suffix) => 'Meow$suffix';
///     }
///
///     // Mock class.
///     class MockCat extends Mock implements Cat {}
///
///     void main() {
///       // Create a new mocked Cat at runtime.
///       var cat = new MockCat();
///
///       // When 'getSound' is called, return 'Woof'
///       when(cat.getSound(any)).thenReturn('Woof');
///
///       // Try making a Cat sound...
///       print(cat.getSound('foo')); // Prints 'Woof'
///     }
///
/// A class which `extends Mock` should not have any directly implemented
/// overridden fields or methods. These fields would not be usable as a [Mock]
/// with [verify] or [when]. To implement a subset of an interface manually use
/// [Fake] instead.
///
/// **WARNING**: [Mock] uses [noSuchMethod](goo.gl/r3IQUH), which is a _form_ of
/// runtime reflection, and causes sub-standard code to be generated. As such,
/// [Mock] should strictly _not_ be used in any production code, especially if
/// used within the context of Dart for Web (dart2js, DDC) and Dart for Mobile
/// (Flutter).
class Mock {
  static Null _answerNull(_) => null;

  static const _nullResponse = CallPair<Null>.allInvocations(_answerNull);

  final StreamController<Invocation> _invocationStreamController =
      StreamController.broadcast();
  final _realCalls = <RealCall>[];
  final _responses = <CallPair<dynamic>>[];

  String _givenName;
  int _givenHashCode;

  _ReturnsCannedResponse _defaultResponse = () => _nullResponse;

  void _setExpected(CallPair<dynamic> cannedResponse) {
    _responses.add(cannedResponse);
  }

  /// Handles method stubbing, method call verification, and real method calls.
  ///
  /// If passed, [returnValue] will be returned during method stubbing and
  /// method call verification. This is useful in cases where the method
  /// invocation which led to `noSuchMethod` being called has a non-nullable
  /// return type.
  @override
  @visibleForTesting
  dynamic noSuchMethod(Invocation invocation, [Object /*?*/ returnValue]) {
    // noSuchMethod is that 'magic' that allows us to ignore implementing fields
    // and methods and instead define them later at compile-time per instance.
    // See "Emulating Functions and Interactions" on dartlang.org: goo.gl/r3IQUH
    invocation = _useMatchedInvocationIfSet(invocation);
    if (_whenInProgress) {
      _whenCall = _WhenCall(this, invocation);
      return returnValue;
    } else if (_verificationInProgress) {
      _verifyCalls.add(_VerifyCall(this, invocation));
      return returnValue;
    } else if (_untilCalledInProgress) {
      _untilCall = _UntilCall(this, invocation);
      return returnValue;
    } else {
      _realCalls.add(RealCall(this, invocation));
      _invocationStreamController.add(invocation);
      var cannedResponse = _responses.lastWhere(
          (cr) => cr.call.matches(invocation, {}),
          orElse: _defaultResponse);
      var response = cannedResponse.response(invocation);
      return response;
    }
  }

  dynamic _noSuchMethod(Invocation invocation) =>
      const Object().noSuchMethod(invocation);

  @override
  int get hashCode => _givenHashCode ?? 0;

  @override
  bool operator ==(other) => (_givenHashCode != null && other is Mock)
      ? _givenHashCode == other._givenHashCode
      : identical(this, other);

  @override
  String toString() => _givenName ?? runtimeType.toString();

  String _realCallsToString([Iterable<RealCall> realCalls]) {
    var stringRepresentations =
        (realCalls ?? _realCalls).map((call) => call.toString());
    if (stringRepresentations.any((s) => s.contains('\n'))) {
      // As each call contains newlines, put each on its own line, for better
      // readability.
      return stringRepresentations.join(',\n');
    } else {
      // A compact String should be perfect.
      return stringRepresentations.join(', ');
    }
  }

  String _unverifiedCallsToString() =>
      _realCallsToString(_realCalls.where((call) => !call.verified));
}

/// Extend or mixin this class to mark the implementation as a [Fake].
///
/// A fake has a default behavior for every field and method of throwing
/// [UnimplementedError]. Fields and methods that are excersized by the code
/// under test should be manually overridden in the implementing class.
///
/// A fake does not have any support for verification or defining behavior from
/// the test, it cannot be used as a [Mock].
///
/// In most cases a shared full fake implementation without a `noSuchMethod` is
/// preferable to `extends Fake`, however `extends Fake` is preferred against
/// `extends Mock` mixed with manual `@override` implementations.
///
/// __Example use__:
///
///     // Real class.
///     class Cat {
///       String meow(String suffix) => 'Meow$suffix';
///       String hiss(String suffix) => 'Hiss$suffix';
///     }
///
///     // Fake class.
///     class FakeCat extends Fake implements Cat {
///       @override
///       String meow(String suffix) => 'FakeMeow$suffix';
///     }
///
///     void main() {
///       // Create a new fake Cat at runtime.
///       var cat = new FakeCat();
///
///       // Try making a Cat sound...
///       print(cat.meow('foo')); // Prints 'FakeMeowfoo'
///       print(cat.hiss('foo')); // Throws
///     }
///
/// **WARNING**: [Fake] uses [noSuchMethod](goo.gl/r3IQUH), which is a _form_ of
/// runtime reflection, and causes sub-standard code to be generated. As such,
/// [Fake] should strictly _not_ be used in any production code, especially if
/// used within the context of Dart for Web (dart2js, DDC) and Dart for Mobile
/// (Flutter).
abstract class Fake {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(invocation.memberName.toString().split('"')[1]);
  }
}

typedef _ReturnsCannedResponse = CallPair<dynamic> Function();

// When using an [ArgMatcher], we transform our invocation to have knowledge of
// which arguments are wrapped, and which ones are not. Otherwise we just use
// the existing invocation object.
Invocation _useMatchedInvocationIfSet(Invocation invocation) {
  if (_storedArgs.isNotEmpty || _storedNamedArgs.isNotEmpty) {
    invocation = _InvocationForMatchedArguments(invocation);
  }
  return invocation;
}

/// An Invocation implementation that takes arguments from [_storedArgs] and
/// [_storedNamedArgs].
class _InvocationForMatchedArguments extends Invocation {
  @override
  final Symbol memberName;
  @override
  final Map<Symbol, dynamic> namedArguments;
  @override
  final List<dynamic> positionalArguments;
  @override
  final bool isGetter;
  @override
  final bool isMethod;
  @override
  final bool isSetter;

  factory _InvocationForMatchedArguments(Invocation invocation) {
    if (_storedArgs.isEmpty && _storedNamedArgs.isEmpty) {
      throw StateError(
          '_InvocationForMatchedArguments called when no ArgMatchers have been saved.');
    }

    // Handle named arguments first, so that we can provide useful errors for
    // the various bad states. If all is well with the named arguments, then we
    // can process the positional arguments, and resort to more general errors
    // if the state is still bad.
    var namedArguments = _reconstituteNamedArgs(invocation);
    var positionalArguments = _reconstitutePositionalArgs(invocation);

    _storedArgs.clear();
    _storedNamedArgs.clear();

    return _InvocationForMatchedArguments._(
        invocation.memberName,
        positionalArguments,
        namedArguments,
        invocation.isGetter,
        invocation.isMethod,
        invocation.isSetter);
  }

  // Reconstitutes the named arguments in an invocation from
  // [_storedNamedArgs].
  //
  // The `namedArguments` in [invocation] which are null should be represented
  // by a stored value in [_storedNamedArgs].
  static Map<Symbol, dynamic> _reconstituteNamedArgs(Invocation invocation) {
    final namedArguments = <Symbol, dynamic>{};
    final storedNamedArgSymbols =
        _storedNamedArgs.keys.map((name) => Symbol(name));

    // Iterate through [invocation]'s named args, validate them, and add them
    // to the return map.
    invocation.namedArguments.forEach((name, arg) {
      if (arg == null) {
        if (!storedNamedArgSymbols.contains(name)) {
          // Either this is a parameter with default value `null`, or a `null`
          // argument was passed, or an unnamed ArgMatcher was used. Just use
          // `null`.
          namedArguments[name] = null;
        }
      } else {
        // Add each real named argument (not wrapped in an ArgMatcher).
        namedArguments[name] = arg;
      }
    });

    // Iterate through the stored named args, validate them, and add them to
    // the return map.
    _storedNamedArgs.forEach((name, arg) {
      var nameSymbol = Symbol(name);
      if (!invocation.namedArguments.containsKey(nameSymbol)) {
        // Clear things out for the next call.
        _storedArgs.clear();
        _storedNamedArgs.clear();
        throw ArgumentError(
            'An ArgumentMatcher was declared as named $name, but was not '
            'passed as an argument named $name.\n\n'
            'BAD:  when(obj.fn(anyNamed: "a")))\n'
            'GOOD: when(obj.fn(a: anyNamed: "a")))');
      }
      if (invocation.namedArguments[nameSymbol] != null) {
        // Clear things out for the next call.
        _storedArgs.clear();
        _storedNamedArgs.clear();
        throw ArgumentError(
            'An ArgumentMatcher was declared as named $name, but a different '
            'value (${invocation.namedArguments[nameSymbol]}) was passed as '
            '$name.\n\n'
            'BAD:  when(obj.fn(b: anyNamed("a")))\n'
            'GOOD: when(obj.fn(b: anyNamed("b")))');
      }
      namedArguments[nameSymbol] = arg;
    });

    return namedArguments;
  }

  static List<dynamic> _reconstitutePositionalArgs(Invocation invocation) {
    final positionalArguments = <dynamic>[];
    final nullPositionalArguments =
        invocation.positionalArguments.where((arg) => arg == null);
    if (_storedArgs.length > nullPositionalArguments.length) {
      // More _positional_ ArgMatchers were stored than were actually passed as
      // positional arguments. There are three ways this call could have been
      // parsed and resolved:
      //
      // * an ArgMatcher was passed in [invocation] as a named argument, but
      //   without a name, and thus stored in [_storedArgs], something like
      //   `when(obj.fn(a: any))`,
      // * an ArgMatcher was passed in an expression which was passed in
      //   [invocation], and thus stored in [_storedArgs], something like
      //   `when(obj.fn(Foo(any)))`, or
      // * a combination of the above.
      _storedArgs.clear();
      _storedNamedArgs.clear();
      throw ArgumentError(
          'An argument matcher (like `any`) was either not used as an '
          'immediate argument to ${invocation.memberName} (argument matchers '
          'can only be used as an argument for the very method being stubbed '
          'or verified), or was used as a named argument without the Mockito '
          '"named" API (Each argument matcher that is used as a named argument '
          'needs to specify the name of the argument it is being used in. For '
          'example: `when(obj.fn(x: anyNamed("x")))`).');
    }
    var storedIndex = 0;
    var positionalIndex = 0;
    while (storedIndex < _storedArgs.length &&
        positionalIndex < invocation.positionalArguments.length) {
      var arg = _storedArgs[storedIndex];
      if (invocation.positionalArguments[positionalIndex] == null) {
        // Add the [ArgMatcher] given to the argument matching helper.
        positionalArguments.add(arg);
        storedIndex++;
        positionalIndex++;
      } else {
        // An argument matching helper was not used; add the [ArgMatcher] from
        // [invocation].
        positionalArguments
            .add(invocation.positionalArguments[positionalIndex]);
        positionalIndex++;
      }
    }
    while (positionalIndex < invocation.positionalArguments.length) {
      // Some trailing non-ArgMatcher arguments.
      positionalArguments.add(invocation.positionalArguments[positionalIndex]);
      positionalIndex++;
    }

    return positionalArguments;
  }

  _InvocationForMatchedArguments._(this.memberName, this.positionalArguments,
      this.namedArguments, this.isGetter, this.isMethod, this.isSetter);
}

@Deprecated(
    'This function does not provide value; hashCode and toString() can be '
    'stubbed individually. This function may be deleted as early as Mockito '
    '5.0.0')
T named<T extends Mock>(T mock, {String name, int hashCode}) => mock
  .._givenName = name
  .._givenHashCode = hashCode;

/// Clear stubs of, and collected interactions with [mock].
void reset(var mock) {
  mock._realCalls.clear();
  mock._responses.clear();
}

/// Clear the collected interactions with [mock].
void clearInteractions(var mock) {
  mock._realCalls.clear();
}

class PostExpectation<T> {
  void thenReturn(T expected) {
    if (expected is Future) {
      throw ArgumentError('`thenReturn` should not be used to return a Future. '
          'Instead, use `thenAnswer((_) => future)`.');
    }
    if (expected is Stream) {
      throw ArgumentError('`thenReturn` should not be used to return a Stream. '
          'Instead, use `thenAnswer((_) => stream)`.');
    }
    return _completeWhen((_) => expected);
  }

  void thenThrow(throwable) {
    return _completeWhen((_) {
      throw throwable;
    });
  }

  void thenAnswer(Answering<T> answer) {
    return _completeWhen(answer);
  }

  void _completeWhen(Answering<T> answer) {
    if (_whenCall == null) {
      throw StateError(
          'Mock method was not called within `when()`. Was a real method '
          'called?');
    }
    _whenCall._setExpected<T>(answer);
    _whenCall = null;
    _whenInProgress = false;
  }
}

class InvocationMatcher {
  final Invocation roleInvocation;

  InvocationMatcher(this.roleInvocation);

  bool matches(Invocation invocation) {
    var isMatching =
        _isMethodMatches(invocation) && _isArgumentsMatches(invocation);
    if (isMatching) {
      _captureArguments(invocation);
    }
    return isMatching;
  }

  bool _isMethodMatches(Invocation invocation) {
    if (invocation.memberName != roleInvocation.memberName) {
      return false;
    }
    if ((invocation.isGetter != roleInvocation.isGetter) ||
        (invocation.isSetter != roleInvocation.isSetter) ||
        (invocation.isMethod != roleInvocation.isMethod)) {
      return false;
    }
    return true;
  }

  void _captureArguments(Invocation invocation) {
    var index = 0;
    for (var roleArg in roleInvocation.positionalArguments) {
      var actArg = invocation.positionalArguments[index];
      if (roleArg is ArgMatcher && roleArg._capture) {
        _capturedArgs.add(actArg);
      }
      index++;
    }
    for (var roleKey in roleInvocation.namedArguments.keys) {
      var roleArg = roleInvocation.namedArguments[roleKey];
      var actArg = invocation.namedArguments[roleKey];
      if (roleArg is ArgMatcher) {
        if (roleArg is ArgMatcher && roleArg._capture) {
          _capturedArgs.add(actArg);
        }
      }
    }
  }

  bool _isArgumentsMatches(Invocation invocation) {
    if (invocation.positionalArguments.length !=
        roleInvocation.positionalArguments.length) {
      return false;
    }
    if (invocation.namedArguments.length !=
        roleInvocation.namedArguments.length) {
      return false;
    }
    var index = 0;
    for (var roleArg in roleInvocation.positionalArguments) {
      var actArg = invocation.positionalArguments[index];
      if (!isMatchingArg(roleArg, actArg)) {
        return false;
      }
      index++;
    }
    Set roleKeys = roleInvocation.namedArguments.keys.toSet();
    Set actKeys = invocation.namedArguments.keys.toSet();
    if (roleKeys.difference(actKeys).isNotEmpty ||
        actKeys.difference(roleKeys).isNotEmpty) {
      return false;
    }
    for (var roleKey in roleInvocation.namedArguments.keys) {
      var roleArg = roleInvocation.namedArguments[roleKey];
      var actArg = invocation.namedArguments[roleKey];
      if (!isMatchingArg(roleArg, actArg)) {
        return false;
      }
    }
    return true;
  }

  bool isMatchingArg(roleArg, actArg) {
    if (roleArg is ArgMatcher) {
      return roleArg.matcher.matches(actArg, {});
    } else {
      return equals(roleArg).matches(actArg, {});
    }
  }
}

class _TimeStampProvider {
  int _now = 0;
  DateTime now() {
    var candidate = DateTime.now();
    if (candidate.millisecondsSinceEpoch <= _now) {
      candidate = DateTime.fromMillisecondsSinceEpoch(_now + 1);
    }
    _now = candidate.millisecondsSinceEpoch;
    return candidate;
  }
}

class RealCall {
  final Mock mock;
  final Invocation invocation;
  final DateTime timeStamp;

  bool verified = false;

  RealCall(this.mock, this.invocation) : timeStamp = _timer.now();

  @override
  String toString() {
    var argString = '';
    var args = invocation.positionalArguments.map((v) => '$v');
    if (args.any((arg) => arg.contains('\n'))) {
      // As one or more arg contains newlines, put each on its own line, and
      // indent each, for better readability.
      argString += '\n' +
          args
              .map((arg) => arg.splitMapJoin('\n', onNonMatch: (m) => '    $m'))
              .join(',\n');
    } else {
      // A compact String should be perfect.
      argString += args.join(', ');
    }
    if (invocation.namedArguments.isNotEmpty) {
      if (argString.isNotEmpty) argString += ', ';
      var namedArgs = invocation.namedArguments.keys.map((key) =>
          '${_symbolToString(key)}: ${invocation.namedArguments[key]}');
      if (namedArgs.any((arg) => arg.contains('\n'))) {
        // As one or more arg contains newlines, put each on its own line, and
        // indent each, for better readability.
        namedArgs = namedArgs
            .map((arg) => arg.splitMapJoin('\n', onNonMatch: (m) => '    $m'));
        argString += '{\n${namedArgs.join(',\n')}}';
      } else {
        // A compact String should be perfect.
        argString += '{${namedArgs.join(', ')}}';
      }
    }

    var method = _symbolToString(invocation.memberName);
    if (invocation.isMethod) {
      method = '$method($argString)';
    } else if (invocation.isGetter) {
      method = '$method';
    } else if (invocation.isSetter) {
      method = '$method=$argString';
    } else {
      throw StateError('Invocation should be getter, setter or a method call.');
    }

    var verifiedText = verified ? '[VERIFIED] ' : '';
    return '$verifiedText$mock.$method';
  }

  // This used to use MirrorSystem, which cleans up the Symbol() wrapper.
  // Since this toString method is just used in Mockito's own tests, it's not
  // a big deal to massage the toString a bit.
  //
  // Input: Symbol("someMethodName")
  static String _symbolToString(Symbol symbol) =>
      symbol.toString().split('"')[1];
}

class _WhenCall {
  final Mock mock;
  final Invocation whenInvocation;
  _WhenCall(this.mock, this.whenInvocation);

  void _setExpected<T>(Answering<T> answer) {
    mock._setExpected(CallPair<T>(isInvocation(whenInvocation), answer));
  }
}

class _UntilCall {
  final InvocationMatcher _invocationMatcher;
  final Mock _mock;

  _UntilCall(this._mock, Invocation invocation)
      : _invocationMatcher = InvocationMatcher(invocation);

  bool _matchesInvocation(RealCall realCall) =>
      _invocationMatcher.matches(realCall.invocation);

  List<RealCall> get _realCalls => _mock._realCalls;

  Future<Invocation> get invocationFuture {
    if (_realCalls.any(_matchesInvocation)) {
      return Future.value(_realCalls.firstWhere(_matchesInvocation).invocation);
    }

    return _mock._invocationStreamController.stream
        .firstWhere(_invocationMatcher.matches);
  }
}

class _VerifyCall {
  final Mock mock;
  final Invocation verifyInvocation;
  List<RealCall> matchingInvocations;

  _VerifyCall(this.mock, this.verifyInvocation) {
    var expectedMatcher = InvocationMatcher(verifyInvocation);
    matchingInvocations = mock._realCalls.where((RealCall recordedInvocation) {
      return !recordedInvocation.verified &&
          expectedMatcher.matches(recordedInvocation.invocation);
    }).toList();
  }

  RealCall _findAfter(DateTime dt) {
    return matchingInvocations.firstWhere(
        (inv) => !inv.verified && inv.timeStamp.isAfter(dt),
        orElse: () => null);
  }

  void _checkWith(bool never) {
    if (!never && matchingInvocations.isEmpty) {
      var message;
      if (mock._realCalls.isEmpty) {
        message = 'No matching calls (actually, no calls at all).';
      } else {
        var otherCalls = mock._realCallsToString();
        message = 'No matching calls. All calls: $otherCalls';
      }
      fail('$message\n'
          '(If you called `verify(...).called(0);`, please instead use '
          '`verifyNever(...);`.)');
    }
    if (never && matchingInvocations.isNotEmpty) {
      var calls = mock._unverifiedCallsToString();
      fail('Unexpected calls: $calls');
    }
    matchingInvocations.forEach((inv) {
      inv.verified = true;
    });
  }

  @override
  String toString() =>
      'VerifyCall<mock: $mock, memberName: ${verifyInvocation.memberName}>';
}

// An argument matcher that acts like an argument during stubbing or
// verification, and stores "matching" information.
//
/// Users do not need to construct this manually; users can instead use the
/// built-in values, [any], [anyNamed], [captureAny], [captureAnyNamed], or the
/// functions [argThat] and [captureThat].
class ArgMatcher {
  final Matcher matcher;
  final bool _capture;

  ArgMatcher(this.matcher, this._capture);

  @override
  String toString() => '$ArgMatcher {$matcher: $_capture}';
}

/// An argument matcher that matches any argument passed in "this" position.
Null get any => _registerMatcher(anything, false, argumentMatcher: 'any');

/// An argument matcher that matches any named argument passed in for the
/// parameter named [named].
Null anyNamed(String named) => _registerMatcher(anything, false,
    named: named, argumentMatcher: 'anyNamed');

/// An argument matcher that matches any argument passed in "this" position, and
/// captures the argument for later access with `captured`.
Null get captureAny =>
    _registerMatcher(anything, true, argumentMatcher: 'captureAny');

/// An argument matcher that matches any named argument passed in for the
/// parameter named [named], and captures the argument for later access with
/// `captured`.
Null captureAnyNamed(String named) => _registerMatcher(anything, true,
    named: named, argumentMatcher: 'captureAnyNamed');

/// An argument matcher that matches an argument that matches [matcher].
Null argThat(Matcher matcher, {String named}) =>
    _registerMatcher(matcher, false, named: named, argumentMatcher: 'argThat');

/// An argument matcher that matches an argument that matches [matcher], and
/// captures the argument for later access with `captured`.
Null captureThat(Matcher matcher, {String named}) =>
    _registerMatcher(matcher, true,
        named: named, argumentMatcher: 'captureThat');

@Deprecated('ArgMatchers no longer need to be wrapped in Mockito 3.0')
Null typed<T>(ArgMatcher matcher, {String named}) => null;

@Deprecated('Replace with `argThat`')
Null typedArgThat(Matcher matcher, {String named}) =>
    argThat(matcher, named: named);

@Deprecated('Replace with `captureThat`')
Null typedCaptureThat(Matcher matcher, {String named}) =>
    captureThat(matcher, named: named);

/// Registers [matcher] into the stored arguments collections.
///
/// Creates an [ArgMatcher] with [matcher] and [capture], then if [named] is
/// non-null, stores that into the positional stored arguments list; otherwise
/// stores it into the named stored arguments map, keyed on [named].
/// [argumentMatcher] is the name of the public API used to register [matcher],
/// for error messages.
Null _registerMatcher(Matcher matcher, bool capture,
    {String named, String argumentMatcher}) {
  if (!_whenInProgress && !_untilCalledInProgress && !_verificationInProgress) {
    // It is not meaningful to store argument matchers outside of stubbing
    // (`when`), or verification (`verify` and `untilCalled`). Such argument
    // matchers will be processed later erroneously.
    _storedArgs.clear();
    _storedNamedArgs.clear();
    throw ArgumentError(
        'The "$argumentMatcher" argument matcher is used outside of method '
        'stubbing (via `when`) or verification (via `verify` or `untilCalled`). '
        'This is invalid, and results in bad behavior during the next stubbing '
        'or verification.');
  }
  var argMatcher = ArgMatcher(matcher, capture);
  if (named == null) {
    _storedArgs.add(argMatcher);
  } else {
    _storedNamedArgs[named] = argMatcher;
  }
  return null;
}

/// Information about a stub call verification.
///
/// This class is most useful to users in two ways:
///
/// * verifying call count, via [called],
/// * collecting captured arguments, via [captured].
class VerificationResult {
  List<dynamic> _captured;

  /// List of all arguments captured in real calls.
  ///
  /// This list will include any captured default arguments and has no
  /// structure differentiating the arguments of one call from another. Given
  /// the following class:
  ///
  /// ```dart
  /// class C {
  ///   String methodWithPositionalArgs(int x, [int y]) => '';
  ///   String methodWithTwoNamedArgs(int x, {int y, int z}) => '';
  /// }
  /// ```
  ///
  /// the following stub calls will result in the following captured arguments:
  ///
  /// ```dart
  /// mock.methodWithPositionalArgs(1);
  /// mock.methodWithPositionalArgs(2, 3);
  /// var captured = verify(
  ///     mock.methodWithPositionalArgs(captureAny, captureAny)).captured;
  /// print(captured); // Prints "[1, null, 2, 3]"
  ///
  /// mock.methodWithTwoNamedArgs(1, y: 42, z: 43);
  /// mock.methodWithTwoNamedArgs(1, y: 44, z: 45);
  /// var captured = verify(
  ///     mock.methodWithTwoNamedArgs(any,
  ///         y: captureAnyNamed('y'), z: captureAnyNamed('z'))).captured;
  /// print(captured); // Prints "[42, 43, 44, 45]"
  /// ```
  ///
  /// Named arguments are listed in the order they are captured in, not the
  /// order in which they were passed.
  // TODO(https://github.com/dart-lang/linter/issues/1992): Remove ignore
  // comments below when google3 has linter with this bug fixed.
  // ignore: unnecessary_getters_setters
  List<dynamic> get captured => _captured;

  @Deprecated(
      'captured should be considered final - assigning this field may be '
      'removed as early as Mockito 5.0.0')
  // ignore: unnecessary_getters_setters
  set captured(List<dynamic> captured) => _captured = captured;

  /// The number of calls matched in this verification.
  int callCount;

  bool _testApiMismatchHasBeenChecked = false;

  @Deprecated(
      'User-constructed VerificationResult is deprecated; this constructor may '
      'be deleted as early as Mockito 5.0.0')
  VerificationResult(int callCount) : this._(callCount);

  VerificationResult._(this.callCount)
      : _captured = List<dynamic>.from(_capturedArgs, growable: false) {
    _capturedArgs.clear();
  }

  /// Check for a version incompatibility between mockito, test, and test_api.
  ///
  /// This incompatibility results in an inscrutible error for users. Catching
  /// it here allows us to give some steps to fix.
  // TODO(srawlins): Remove this when we don't need to check for an
  // incompatiblity between test_api and test any more.
  // https://github.com/dart-lang/mockito/issues/175
  void _checkTestApiMismatch() {
    try {
      Invoker.current;
    } on CastError catch (e) {
      if (!e
          .toString()
          .contains("type 'Invoker' is not a subtype of type 'Invoker'")) {
        // Hmm. This is a different CastError from the one we're trying to
        // protect against. Let it go.
        return;
      }
      print('Error: Package incompatibility between mockito, test, and '
          'test_api packages:');
      print('');
      print('* mockito ^4.0.0 is incompatible with test <1.4.0');
      print('* mockito <4.0.0 is incompatible with test ^1.4.0');
      print('');
      print('As mockito does not have a dependency on the test package, '
          'nothing stopped you from landing in this situation. :( '
          'Apologies.');
      print('');
      print('To fix: bump your dependency on the test package to something '
          'like: ^1.4.0, or downgrade your dependency on mockito to something '
          'like: ^3.0.0');
      rethrow;
    }
  }

  /// Assert that the number of calls matches [matcher].
  ///
  /// Examples:
  ///
  /// * `verify(mock.m()).called(1)` asserts that `m()` is called exactly once.
  /// * `verify(mock.m()).called(greaterThan(2))` asserts that `m()` is called
  ///   more than two times.
  ///
  /// To assert that a method was called zero times, use [verifyNever].
  void called(dynamic matcher) {
    if (!_testApiMismatchHasBeenChecked) {
      // Only execute the check below once. `Invoker.current` may look like a
      // cheap getter, but it involves Zones and casting.
      _testApiMismatchHasBeenChecked = true;
      _checkTestApiMismatch();
    }
    expect(callCount, wrapMatcher(matcher),
        reason: 'Unexpected number of calls');
  }
}

typedef Answering<T> = T Function(Invocation realInvocation);

typedef Verification = VerificationResult Function<T>(T matchingInvocations);

typedef _InOrderVerification = void Function<T>(List<T> recordedInvocations);

/// Verify that a method on a mock object was never called with the given
/// arguments.
///
/// Call a method on a mock object within a `verifyNever` call. For example:
///
/// ```dart
/// cat.eatFood("chicken");
/// verifyNever(cat.eatFood("fish"));
/// ```
///
/// Mockito will pass the current test case, as `cat.eatFood` has not been
/// called with `"chicken"`.
Verification get verifyNever => _makeVerify(true);

/// Verify that a method on a mock object was called with the given arguments.
///
/// Call a method on a mock object within the call to `verify`. For example:
///
/// ```dart
/// cat.eatFood("chicken");
/// verify(cat.eatFood("fish"));
/// ```
///
/// Mockito will fail the current test case if `cat.eatFood` has not been called
/// with `"fish"`. Optionally, call `called` on the result, to verify that the
/// method was called a certain number of times. For example:
///
/// ```dart
/// verify(cat.eatFood("fish")).called(2);
/// verify(cat.eatFood("fish")).called(greaterThan(3));
/// ```
///
/// Note: When mockito verifies a method call, said call is then excluded from
/// further verifications. A single method call cannot be verified from multiple
/// calls to `verify`, or `verifyInOrder`. See more details in the FAQ.
///
/// Note: because of an unintended limitation, `verify(...).called(0);` will
/// not work as expected. Please use `verifyNever(...);` instead.
///
/// See also: [verifyNever], [verifyInOrder], [verifyZeroInteractions], and
/// [verifyNoMoreInteractions].
Verification get verify => _makeVerify(false);

Verification _makeVerify(bool never) {
  if (_verifyCalls.isNotEmpty) {
    var message = 'Verification appears to be in progress.';
    if (_verifyCalls.length == 1) {
      message =
          '$message One verify call has been stored: ${_verifyCalls.single}';
    } else {
      message =
          '$message ${_verifyCalls.length} verify calls have been stored. '
          '[${_verifyCalls.first}, ..., ${_verifyCalls.last}]';
    }
    throw StateError(message);
  }
  _verificationInProgress = true;
  return <T>(T mock) {
    _verificationInProgress = false;
    if (_verifyCalls.length == 1) {
      var verifyCall = _verifyCalls.removeLast();
      var result = VerificationResult._(verifyCall.matchingInvocations.length);
      verifyCall._checkWith(never);
      return result;
    } else {
      fail('Used on a non-mockito object');
    }
  };
}

/// Verify that a list of methods on a mock object have been called with the
/// given arguments. For example:
///
/// ```dart
/// verifyInOrder([cat.eatFood("Milk"), cat.sound(), cat.eatFood(any)]);
/// ```
///
/// This verifies that `eatFood` was called with `"Milk"`, sound` was called
/// with no arguments, and `eatFood` was then called with some argument.
///
/// Note: [verifyInOrder] only verifies that each call was made in the order
/// given, but not that those were the only calls. In the example above, if
/// other calls were made to `eatFood` or `sound` between the three given
/// calls, or before or after them, the verification will still succeed.
_InOrderVerification get verifyInOrder {
  if (_verifyCalls.isNotEmpty) {
    throw StateError(_verifyCalls.join());
  }
  _verificationInProgress = true;
  return <T>(List<T> _) {
    _verificationInProgress = false;
    var dt = DateTime.fromMillisecondsSinceEpoch(0);
    var tmpVerifyCalls = List<_VerifyCall>.from(_verifyCalls);
    _verifyCalls.clear();
    var matchedCalls = <RealCall>[];
    for (var verifyCall in tmpVerifyCalls) {
      var matched = verifyCall._findAfter(dt);
      if (matched != null) {
        matchedCalls.add(matched);
        dt = matched.timeStamp;
      } else {
        var mocks = tmpVerifyCalls.map((vc) => vc.mock).toSet();
        var allInvocations =
            mocks.expand((m) => m._realCalls).toList(growable: false);
        allInvocations
            .sort((inv1, inv2) => inv1.timeStamp.compareTo(inv2.timeStamp));
        var otherCalls = '';
        if (allInvocations.isNotEmpty) {
          otherCalls = " All calls: ${allInvocations.join(", ")}";
        }
        fail('Matching call #${tmpVerifyCalls.indexOf(verifyCall)} '
            'not found.$otherCalls');
      }
    }
    for (var call in matchedCalls) {
      call.verified = true;
    }
  };
}

void _throwMockArgumentError(String method, var nonMockInstance) {
  if (nonMockInstance == null) {
    throw ArgumentError('$method was called with a null argument');
  }
  throw ArgumentError('$method must only be given a Mock object');
}

void verifyNoMoreInteractions(var mock) {
  if (mock is Mock) {
    var unverified = mock._realCalls.where((inv) => !inv.verified).toList();
    if (unverified.isNotEmpty) {
      fail('No more calls expected, but following found: ' + unverified.join());
    }
  } else {
    _throwMockArgumentError('verifyNoMoreInteractions', mock);
  }
}

void verifyZeroInteractions(var mock) {
  if (mock is Mock) {
    if (mock._realCalls.isNotEmpty) {
      fail('No interaction expected, but following found: ' +
          mock._realCalls.join());
    }
  } else {
    _throwMockArgumentError('verifyZeroInteractions', mock);
  }
}

typedef Expectation = PostExpectation<T> Function<T>(T x);

/// Create a stub method response.
///
/// Call a method on a mock object within the call to `when`, and call a
/// canned response method on the result. For example:
///
/// ```dart
/// when(cat.eatFood("fish")).thenReturn(true);
/// ```
///
/// Mockito will store the fake call to `cat.eatFood`, and pair the exact
/// arguments given with the response. When `cat.eatFood` is called outside a
/// `when` or `verify` context (a call "for real"), Mockito will respond with
/// the stored canned response, if it can match the mock method parameters.
///
/// The response generators include `thenReturn`, `thenAnswer`, and `thenThrow`.
///
/// See the README for more information.
Expectation get when {
  if (_whenCall != null) {
    throw StateError('Cannot call `when` within a stub response');
  }
  _whenInProgress = true;
  return <T>(T _) {
    _whenInProgress = false;
    return PostExpectation<T>();
  };
}

typedef InvocationLoader = Future<Invocation> Function<T>(T _);

/// Returns a future [Invocation] that will complete upon the first occurrence
/// of the given invocation.
///
/// Usage of this is as follows:
///
/// ```dart
/// cat.eatFood("fish");
/// await untilCalled(cat.chew());
/// ```
///
/// In the above example, the untilCalled(cat.chew()) will complete only when
/// that method is called. If the given invocation has already been called, the
/// future will return immediately.
InvocationLoader get untilCalled {
  _untilCalledInProgress = true;
  return <T>(T _) {
    _untilCalledInProgress = false;
    return _untilCall.invocationFuture;
  };
}

/// Print all collected invocations of any mock methods of [mocks].
void logInvocations(List<Mock> mocks) {
  var allInvocations =
      mocks.expand((m) => m._realCalls).toList(growable: false);
  allInvocations.sort((inv1, inv2) => inv1.timeStamp.compareTo(inv2.timeStamp));
  allInvocations.forEach((inv) {
    print(inv.toString());
  });
}

/// Reset the state of Mockito, typically for use between tests.
///
/// For example, when using the test package, mock methods may accumulate calls
/// in a `setUp` method, making it hard to verify method calls that were made
/// _during_ an individual test. Or, there may be unverified calls from previous
/// test cases that should not affect later test cases.
///
/// In these cases, [resetMockitoState] might be called at the end of `setUp`,
/// or in `tearDown`.
void resetMockitoState() {
  _whenInProgress = false;
  _untilCalledInProgress = false;
  _verificationInProgress = false;
  _whenCall = null;
  _untilCall = null;
  _verifyCalls.clear();
  _capturedArgs.clear();
  _storedArgs.clear();
  _storedNamedArgs.clear();
}
