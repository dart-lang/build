// Warning: Do not import dart:mirrors in this library, as it's exported via
// lib/mockito_no_mirrors.dart, which is used for Dart AOT projects such as
// Flutter.

import 'package:meta/meta.dart';
import 'package:test/test.dart';

bool _whenInProgress = false;
bool _verificationInProgress = false;
_WhenCall _whenCall = null;
final List<_VerifyCall> _verifyCalls = <_VerifyCall>[];
final _TimeStampProvider _timer = new _TimeStampProvider();
final List _capturedArgs = [];
final List<_ArgMatcher> _typedArgs = <_ArgMatcher>[];
final Map<String, _ArgMatcher> _typedNamedArgs = <String, _ArgMatcher>{};

// Hidden from the public API, used by spy.dart.
void setDefaultResponse(Mock mock, CannedResponse defaultResponse()) {
  mock._defaultResponse = defaultResponse;
}

/// Extend or mixin this class to mark the implementation as a [Mock].
///
/// A mocked class implements all fields and methods with a default
/// implementation that does not throw a [NoSuchMethodError], and may be further
/// customized at runtime to define how it may behave using [when].
///
/// __Example use__:
///   // Real class.
///   class Cat {
///     String getSound() => 'Meow';
///   }
///
///   // Mock class.
///   class MockCat extends Mock implements Cat {}
///
///   void main() {
///     // Create a new mocked Cat at runtime.
///     var cat = new MockCat();
///
///     // When 'getSound' is called, return 'Woof'
///     when(cat.getSound()).thenReturn('Woof');
///
///     // Try making a Cat sound...
///     print(cat.getSound()); // Prints 'Woof'
///   }
///
/// **WARNING**: [Mock] uses [noSuchMethod](goo.gl/r3IQUH), which is a _form_ of
/// runtime reflection, and causes sub-standard code to be generated. As such,
/// [Mock] should strictly _not_ be used in any production code, especially if
/// used within the context of Dart for Web (dart2js/ddc) and Dart for Mobile
/// (flutter).
class Mock {
  static CannedResponse _nullResponse() {
    return new CannedResponse(null, (_) => null);
  }

  final List<RealCall> _realCalls = <RealCall>[];
  final List<CannedResponse> _responses = <CannedResponse>[];
  String _givenName = null;
  int _givenHashCode = null;

  _ReturnsCannedResponse _defaultResponse = _nullResponse;

  void _setExpected(CannedResponse cannedResponse) {
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
    } else {
      _realCalls.add(new RealCall(this, invocation));
      var cannedResponse = _responses.lastWhere(
          (cr) => cr.matcher.matches(invocation),
          orElse: _defaultResponse);
      var response = cannedResponse.response(invocation);
      return response;
    }
  }

  int get hashCode => _givenHashCode == null ? 0 : _givenHashCode;

  bool operator ==(other) => (_givenHashCode != null && other is Mock)
      ? _givenHashCode == other._givenHashCode
      : identical(this, other);

  String toString() => _givenName != null ? _givenName : runtimeType.toString();
}

typedef CannedResponse _ReturnsCannedResponse();

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
  final Symbol memberName;
  final Map<Symbol, dynamic> namedArguments;
  final List<dynamic> positionalArguments;
  final bool isGetter;
  final bool isMethod;
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

void reset(var mock) {
  mock._realCalls.clear();
  mock._responses.clear();
}

void clearInteractions(var mock) {
  mock._realCalls.clear();
}

class PostExpectation {
  thenReturn(expected) {
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
      if (roleArg is _ArgMatcher && roleArg._capture) {
        _capturedArgs.add(actArg);
      }
      index++;
    }
    for (var roleKey in roleInvocation.namedArguments.keys) {
      var roleArg = roleInvocation.namedArguments[roleKey];
      var actArg = invocation.namedArguments[roleKey];
      if (roleArg is _ArgMatcher) {
        if (roleArg is _ArgMatcher && roleArg._capture) {
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
    if (roleArg is _ArgMatcher) {
      return roleArg._matcher.matches(actArg, {});
//    } else if(roleArg is Mock){
//      return identical(roleArg, actArg);
    } else {
      return equals(roleArg).matches(actArg, {});
    }
  }
}

class CannedResponse {
  InvocationMatcher matcher;
  Answering response;

  CannedResponse(this.matcher, this.response);
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
  // This used to use MirrorSystem, which cleans up the Symbol() wrapper.
  // Since this toString method is just used in Mockito's own tests, it's not
  // a big deal to massage the toString a bit.
  //
  // Input: Symbol("someMethodName")
  static String _symbolToString(Symbol symbol) {
    return symbol.toString().split('"')[1];
  }

  DateTime _timeStamp;
  final Mock mock;
  final Invocation invocation;
  bool verified = false;
  RealCall(this.mock, this.invocation) {
    _timeStamp = _timer.now();
  }

  DateTime get timeStamp => _timeStamp;

  String toString() {
    var verifiedText = verified ? "[VERIFIED] " : "";
    List<String> posArgs = invocation.positionalArguments
        .map((v) => v == null ? "null" : v.toString())
        .toList();
    List<String> mapArgList = invocation.namedArguments.keys.map((key) {
      return "${_symbolToString(key)}: ${invocation.namedArguments[key]}";
    }).toList(growable: false);
    if (mapArgList.isNotEmpty) {
      posArgs.add("{${mapArgList.join(", ")}}");
    }
    String args = posArgs.join(", ");
    String method = _symbolToString(invocation.memberName);
    if (invocation.isMethod) {
      method = ".$method($args)";
    } else if (invocation.isGetter) {
      method = ".$method";
    } else {
      method = ".$method=$args";
    }
    return "$verifiedText$mock$method";
  }
}

class _WhenCall {
  final Mock mock;
  final Invocation whenInvocation;
  _WhenCall(this.mock, this.whenInvocation);

  void _setExpected(Answering answer) {
    mock._setExpected(
        new CannedResponse(new InvocationMatcher(whenInvocation), answer));
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
      var otherCallsText = "";
      if (mock._realCalls.isNotEmpty) {
        otherCallsText = " All calls: ";
      }
      var calls = mock._realCalls.join(", ");
      fail("No matching calls.$otherCallsText$calls");
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

class _ArgMatcher {
  final Matcher _matcher;
  final bool _capture;

  _ArgMatcher(this._matcher, this._capture);
}

/// An argument matcher that matches any argument passed in "this" position.
get any => new _ArgMatcher(anything, false);

/// An argument matcher that matches any argument passed in "this" position, and
/// captures the argument for later access with `captured`.
get captureAny => new _ArgMatcher(anything, true);

/// An argument matcher that matches an argument that matches [matcher].
argThat(Matcher matcher) => new _ArgMatcher(matcher, false);

/// An argument matcher that matches an argument that matches [matcher], and
/// captures the argument for later access with `captured`.
captureThat(Matcher matcher) => new _ArgMatcher(matcher, true);

/// A Strong-mode safe argument matcher that wraps other argument matchers.
/// See the README for a full explanation.
/*=T*/ typed/*<T>*/(_ArgMatcher matcher, {String named}) {
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

typedef VerificationResult Verification(matchingInvocations);

typedef void InOrderVerification(recordedInvocations);

Verification get verifyNever => _makeVerify(true);

Verification get verify => _makeVerify(false);

Verification _makeVerify(bool never) {
  if (_verifyCalls.isNotEmpty) {
    throw new StateError(_verifyCalls.join());
  }
  _verificationInProgress = true;
  return (mock) {
    _verificationInProgress = false;
    if (_verifyCalls.length == 1) {
      _VerifyCall verifyCall = _verifyCalls.removeLast();
      var result =
          new VerificationResult(verifyCall.matchingInvocations.length);
      verifyCall._checkWith(never);
      return result;
    } else {
      fail("Used on non-mockito");
    }
  };
}

InOrderVerification get verifyInOrder {
  if (_verifyCalls.isNotEmpty) {
    throw new StateError(_verifyCalls.join());
  }
  _verificationInProgress = true;
  return (verifyCalls) {
    _verificationInProgress = false;
    DateTime dt = new DateTime.fromMillisecondsSinceEpoch(0);
    var tmpVerifyCalls = new List.from(_verifyCalls);
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
    matchedCalls.forEach((rc) {
      rc.verified = true;
    });
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

typedef PostExpectation Expectation(x);

Expectation get when {
  _whenInProgress = true;
  return (_) {
    _whenInProgress = false;
    return new PostExpectation();
  };
}

void logInvocations(List<Mock> mocks) {
  List<RealCall> allInvocations =
      mocks.expand((m) => m._realCalls).toList(growable: false);
  allInvocations.sort((inv1, inv2) => inv1.timeStamp.compareTo(inv2.timeStamp));
  allInvocations.forEach((inv) {
    print(inv.toString());
  });
}

/// Should only be used during Mockito testing.
void resetMockitoState() {
  _whenInProgress = false;
  _verificationInProgress = false;
  _whenCall = null;
  _verifyCalls.clear();
  _capturedArgs.clear();
  _typedArgs.clear();
  _typedNamedArgs.clear();
}
