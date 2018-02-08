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
import 'package:test/test.dart';

bool _whenInProgress = false;
bool _untilCalledInProgress = false;
bool _verificationInProgress = false;
_WhenCall _whenCall;
_UntilCall _untilCall;
final List<_VerifyCall> _verifyCalls = <_VerifyCall>[];
final _TimeStampProvider _timer = new _TimeStampProvider();
final List _capturedArgs = [];
final List<ArgMatcher> _typedArgs = <ArgMatcher>[];
final Map<String, ArgMatcher> _typedNamedArgs = <String, ArgMatcher>{};

// Hidden from the public API, used by spy.dart.
void setDefaultResponse(Mock mock, CallPair defaultResponse()) {
  mock._defaultResponse = defaultResponse;
}

/// Opt-into [Mock] throwing [NoSuchMethodError] for unimplemented methods.
///
/// The default behavior when not using this is to always return `null`.
void throwOnMissingStub(Mock mock) {
  mock._defaultResponse = () => new CallPair.allInvocations(mock._noSuchMethod);
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
///       when(cat.getSound(typed(any))).thenReturn('Woof');
///
///       // Try making a Cat sound...
///       print(cat.getSound('foo')); // Prints 'Woof'
///     }
///
/// **WARNING**: [Mock] uses [noSuchMethod](goo.gl/r3IQUH), which is a _form_ of
/// runtime reflection, and causes sub-standard code to be generated. As such,
/// [Mock] should strictly _not_ be used in any production code, especially if
/// used within the context of Dart for Web (dart2js, DDC) and Dart for Mobile
/// (Flutter).
class Mock {
  static _answerNull(_) => null;

  static const _nullResponse = const CallPair.allInvocations(_answerNull);

  final StreamController<Invocation> _invocationStreamController =
      new StreamController.broadcast();
  final _realCalls = <RealCall>[];
  final _responses = <CallPair>[];

  String _givenName;
  int _givenHashCode;

  _ReturnsCannedResponse _defaultResponse = () => _nullResponse;

  void _setExpected(CallPair cannedResponse) {
    _responses.add(cannedResponse);
  }

  @override
  @visibleForTesting
  noSuchMethod(Invocation invocation) {
    // noSuchMethod is that 'magic' that allows us to ignore implementing fields
    // and methods and instead define them later at compile-time per instance.
    // See "Emulating Functions and Interactions" on dartlang.org: goo.gl/r3IQUH
    invocation = _useTypedInvocationIfSet(invocation);
    if (_whenInProgress) {
      _whenCall = new _WhenCall(this, invocation);
      return null;
    } else if (_verificationInProgress) {
      _verifyCalls.add(new _VerifyCall(this, invocation));
      return null;
    } else if (_untilCalledInProgress) {
      _untilCall = new _UntilCall(this, invocation);
      return null;
    } else {
      _realCalls.add(new RealCall(this, invocation));
      _invocationStreamController.add(invocation);
      var cannedResponse = _responses.lastWhere(
          (cr) => cr.call.matches(invocation, {}),
          orElse: _defaultResponse);
      var response = cannedResponse.response(invocation);
      return response;
    }
  }

  _noSuchMethod(Invocation invocation) =>
      const Object().noSuchMethod(invocation);

  @override
  int get hashCode => _givenHashCode == null ? 0 : _givenHashCode;

  @override
  bool operator ==(other) => (_givenHashCode != null && other is Mock)
      ? _givenHashCode == other._givenHashCode
      : identical(this, other);

  @override
  String toString() => _givenName != null ? _givenName : runtimeType.toString();
}

typedef CallPair _ReturnsCannedResponse();

// When using the typed() matcher, we transform our invocation to have knowledge
// of which arguments are wrapped with typed() and which ones are not. Otherwise
// we just use the existing invocation object.
Invocation _useTypedInvocationIfSet(Invocation invocation) {
  if (_typedArgs.isNotEmpty || _typedNamedArgs.isNotEmpty) {
    invocation = new _InvocationForTypedArguments(invocation);
  }
  return invocation;
}

/// An Invocation implementation that takes arguments from [_typedArgs] and
/// [_typedNamedArgs].
class _InvocationForTypedArguments extends Invocation {
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

  factory _InvocationForTypedArguments(Invocation invocation) {
    if (_typedArgs.isEmpty && _typedNamedArgs.isEmpty) {
      throw new StateError(
          "_InvocationForTypedArguments called when no typed calls have been saved.");
    }

    // Handle named arguments first, so that we can provide useful errors for
    // the various bad states. If all is well with the named arguments, then we
    // can process the positional arguments, and resort to more general errors
    // if the state is still bad.
    var namedArguments = _reconstituteNamedArgs(invocation);
    var positionalArguments = _reconstitutePositionalArgs(invocation);

    _typedArgs.clear();
    _typedNamedArgs.clear();

    return new _InvocationForTypedArguments._(
        invocation.memberName,
        positionalArguments,
        namedArguments,
        invocation.isGetter,
        invocation.isMethod,
        invocation.isSetter);
  }

  // Reconstitutes the named arguments in an invocation from [_typedNamedArgs].
  //
  // The namedArguments in [invocation] which are null should be represented
  // by a stored value in [_typedNamedArgs]. The null presumably came from
  // [typed].
  static Map<Symbol, dynamic> _reconstituteNamedArgs(Invocation invocation) {
    var namedArguments = <Symbol, dynamic>{};
    var _typedNamedArgSymbols =
        _typedNamedArgs.keys.map((name) => new Symbol(name));

    // Iterate through [invocation]'s named args, validate them, and add them
    // to the return map.
    invocation.namedArguments.forEach((name, arg) {
      if (arg == null) {
        if (!_typedNamedArgSymbols.contains(name)) {
          // Incorrect usage of [typed], something like:
          // `when(obj.fn(a: typed(any)))`.
          throw new ArgumentError(
              'A typed argument was passed in as a named argument named "$name", '
              'but did not pass a value for `named`. Each typed argument that is '
              'passed as a named argument needs to specify the `named` argument. '
              'For example: `when(obj.fn(x: typed(any, named: "x")))`.');
        }
      } else {
        // Add each real named argument that was _not_ passed with [typed].
        namedArguments[name] = arg;
      }
    });

    // Iterate through the stored named args (stored with [typed]), validate
    // them, and add them to the return map.
    _typedNamedArgs.forEach((name, arg) {
      Symbol nameSymbol = new Symbol(name);
      if (!invocation.namedArguments.containsKey(nameSymbol)) {
        throw new ArgumentError(
            'A typed argument was declared as named $name, but was not passed '
            'as an argument named $name.\n\n'
            'BAD:  when(obj.fn(typed(any, named: "a")))\n'
            'GOOD: when(obj.fn(a: typed(any, named: "a")))');
      }
      if (invocation.namedArguments[nameSymbol] != null) {
        throw new ArgumentError(
            'A typed argument was declared as named $name, but a different '
            'value (${invocation.namedArguments[nameSymbol]}) was passed as '
            '$name.\n\n'
            'BAD:  when(obj.fn(b: typed(any, name: "a")))\n'
            'GOOD: when(obj.fn(b: typed(any, name: "b")))');
      }
      namedArguments[nameSymbol] = arg;
    });

    return namedArguments;
  }

  static List<dynamic> _reconstitutePositionalArgs(Invocation invocation) {
    var positionalArguments = <dynamic>[];
    var nullPositionalArguments =
        invocation.positionalArguments.where((arg) => arg == null);
    if (_typedArgs.length != nullPositionalArguments.length) {
      throw new ArgumentError(
          'null arguments are not allowed alongside typed(); use '
          '"typed(eq(null))"');
    }
    int typedIndex = 0;
    int positionalIndex = 0;
    while (typedIndex < _typedArgs.length &&
        positionalIndex < invocation.positionalArguments.length) {
      var arg = _typedArgs[typedIndex];
      if (invocation.positionalArguments[positionalIndex] == null) {
        // [typed] was used; add the [_ArgMatcher] given to [typed].
        positionalArguments.add(arg);
        typedIndex++;
        positionalIndex++;
      } else {
        // [typed] was not used; add the [_ArgMatcher] from [invocation].
        positionalArguments
            .add(invocation.positionalArguments[positionalIndex]);
        positionalIndex++;
      }
    }
    while (positionalIndex < invocation.positionalArguments.length) {
      // Some trailing non-[typed] arguments.
      positionalArguments.add(invocation.positionalArguments[positionalIndex]);
      positionalIndex++;
    }

    return positionalArguments;
  }

  _InvocationForTypedArguments._(this.memberName, this.positionalArguments,
      this.namedArguments, this.isGetter, this.isMethod, this.isSetter);
}

named(var mock, {String name, int hashCode}) => mock
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

class PostExpectation {
  thenReturn(expected) {
    if (expected is Future) {
      throw new ArgumentError(
          '`thenReturn` should not be used to return a Future. '
          'Instead, use `thenAnswer((_) => future)`.');
    }
    if (expected is Stream) {
      throw new ArgumentError(
          '`thenReturn` should not be used to return a Stream. '
          'Instead, use `thenAnswer((_) => stream)`.');
    }
    return _completeWhen((_) => expected);
  }

  thenThrow(throwable) {
    return _completeWhen((_) {
      throw throwable;
    });
  }

  thenAnswer(Answering answer) {
    return _completeWhen(answer);
  }

  _completeWhen(Answering answer) {
    _whenCall._setExpected(answer);
    var mock = _whenCall.mock;
    _whenCall = null;
    _whenInProgress = false;
    return mock;
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
    int index = 0;
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
    int index = 0;
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
    var candidate = new DateTime.now();
    if (candidate.millisecondsSinceEpoch <= _now) {
      candidate = new DateTime.fromMillisecondsSinceEpoch(_now + 1);
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
    var args = invocation.positionalArguments
        .map((v) => v == null ? "null" : v.toString())
        .join(", ");
    if (invocation.namedArguments.isNotEmpty) {
      var namedArgs = invocation.namedArguments.keys
          .map((key) =>
              "${_symbolToString(key)}: ${invocation.namedArguments[key]}")
          .join(", ");
      args += ", {$namedArgs}";
    }

    var method = _symbolToString(invocation.memberName);
    if (invocation.isMethod) {
      method = "$method($args)";
    } else if (invocation.isGetter) {
      method = "$method";
    } else if (invocation.isSetter) {
      method = "$method=$args";
    } else {
      throw new StateError(
          'Invocation should be getter, setter or a method call.');
    }

    var verifiedText = verified ? "[VERIFIED] " : "";
    return "$verifiedText$mock.$method";
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

  void _setExpected(Answering answer) {
    mock._setExpected(new CallPair(isInvocation(whenInvocation), answer));
  }
}

class _UntilCall {
  final InvocationMatcher _invocationMatcher;
  final Mock _mock;

  _UntilCall(this._mock, Invocation invocation)
      : _invocationMatcher = new InvocationMatcher(invocation);

  bool _matchesInvocation(RealCall realCall) =>
      _invocationMatcher.matches(realCall.invocation);

  List<RealCall> get _realCalls => _mock._realCalls;

  Future<Invocation> get invocationFuture {
    if (_realCalls.any(_matchesInvocation)) {
      return new Future.value(
          _realCalls.firstWhere(_matchesInvocation).invocation);
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
    var expectedMatcher = new InvocationMatcher(verifyInvocation);
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
        message = "No matching calls (actually, no calls at all).";
      } else {
        var otherCalls = mock._realCalls.join(", ");
        message = "No matching calls. All calls: $otherCalls";
      }
      fail("$message\n"
          "(If you called `verify(...).called(0);`, please instead use "
          "`verifyNever(...);`.)");
    }
    if (never && matchingInvocations.isNotEmpty) {
      var calls = mock._realCalls.join(", ");
      fail("Unexpected calls. All calls: $calls");
    }
    matchingInvocations.forEach((inv) {
      inv.verified = true;
    });
  }
}

class ArgMatcher {
  final Matcher matcher;
  final bool _capture;

  ArgMatcher(this.matcher, this._capture);

  @override
  String toString() => '$ArgMatcher {$matcher: $_capture}';
}

/// An argument matcher that matches any argument passed in "this" position.
get any => new ArgMatcher(anything, false);

/// An argument matcher that matches any argument passed in "this" position, and
/// captures the argument for later access with `captured`.
get captureAny => new ArgMatcher(anything, true);

/// An argument matcher that matches an argument that matches [matcher].
argThat(Matcher matcher) => new ArgMatcher(matcher, false);

/// An argument matcher that matches an argument that matches [matcher], and
/// captures the argument for later access with `captured`.
captureThat(Matcher matcher) => new ArgMatcher(matcher, true);

/// A Strong-mode safe argument matcher that wraps other argument matchers.
/// See the README for a full explanation.
T typed<T>(ArgMatcher matcher, {String named}) {
  if (named == null) {
    _typedArgs.add(matcher);
  } else {
    _typedNamedArgs[named] = matcher;
  }
  return null;
}

class VerificationResult {
  List captured = [];
  int callCount;

  VerificationResult(this.callCount) {
    captured = new List.from(_capturedArgs, growable: false);
    _capturedArgs.clear();
  }

  void called(matcher) {
    expect(callCount, wrapMatcher(matcher),
        reason: "Unexpected number of calls");
  }
}

typedef dynamic Answering(Invocation realInvocation);

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
/// Note: because of an unintended limitation, `verify(...).called(0);` will
/// not work as expected. Please use `verifyNever(...);` instead.
///
/// See also: [verifyNever], [verifyInOrder], [verifyZeroInteractions], and
/// [verifyNoMoreInteractions].
Verification get verify => _makeVerify(false);

Verification _makeVerify(bool never) {
  if (_verifyCalls.isNotEmpty) {
    throw new StateError(_verifyCalls.join());
  }
  _verificationInProgress = true;
  return <T>(T mock) {
    _verificationInProgress = false;
    if (_verifyCalls.length == 1) {
      _VerifyCall verifyCall = _verifyCalls.removeLast();
      var result =
          new VerificationResult(verifyCall.matchingInvocations.length);
      verifyCall._checkWith(never);
      return result;
    } else {
      fail("Used on a non-mockito object");
    }
  };
}

_InOrderVerification get verifyInOrder {
  if (_verifyCalls.isNotEmpty) {
    throw new StateError(_verifyCalls.join());
  }
  _verificationInProgress = true;
  return <T>(List<T> _) {
    _verificationInProgress = false;
    DateTime dt = new DateTime.fromMillisecondsSinceEpoch(0);
    var tmpVerifyCalls = new List<_VerifyCall>.from(_verifyCalls);
    _verifyCalls.clear();
    List<RealCall> matchedCalls = [];
    for (_VerifyCall verifyCall in tmpVerifyCalls) {
      RealCall matched = verifyCall._findAfter(dt);
      if (matched != null) {
        matchedCalls.add(matched);
        dt = matched.timeStamp;
      } else {
        Set<Mock> mocks =
            tmpVerifyCalls.map((_VerifyCall vc) => vc.mock).toSet();
        List<RealCall> allInvocations =
            mocks.expand((m) => m._realCalls).toList(growable: false);
        allInvocations
            .sort((inv1, inv2) => inv1.timeStamp.compareTo(inv2.timeStamp));
        String otherCalls = "";
        if (allInvocations.isNotEmpty) {
          otherCalls = " All calls: ${allInvocations.join(", ")}";
        }
        fail(
            "Matching call #${tmpVerifyCalls.indexOf(verifyCall)} not found.$otherCalls");
      }
    }
    for (var call in matchedCalls) {
      call.verified = true;
    }
  };
}

void verifyNoMoreInteractions(var mock) {
  var unverified = mock._realCalls.where((inv) => !inv.verified).toList();
  if (unverified.isNotEmpty) {
    fail("No more calls expected, but following found: " + unverified.join());
  }
}

void verifyZeroInteractions(var mock) {
  if (mock._realCalls.isNotEmpty) {
    fail("No interaction expected, but following found: " +
        mock._realCalls.join());
  }
}

typedef Expectation = PostExpectation Function<T>(T x);

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
    throw new StateError('Cannot call `when` within a stub response');
  }
  _whenInProgress = true;
  return <T>(T _) {
    _whenInProgress = false;
    return new PostExpectation();
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
  List<RealCall> allInvocations =
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
  _typedArgs.clear();
  _typedNamedArgs.clear();
}
