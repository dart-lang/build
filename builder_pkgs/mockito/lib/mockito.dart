library mockito;

import 'dart:mirrors';

import 'package:test/test.dart';


bool _whenInProgress = false;
bool _verificationInProgress = false;
_WhenCall _whenCall = null;
final List<_VerifyCall> _verifyCalls = <_VerifyCall>[];
final _TimeStampProvider _timer = new _TimeStampProvider();
final List _capturedArgs = [];

class Mock {
  final List<RealCall> _realCalls = <RealCall>[];
  final List<CannedResponse> _responses = <CannedResponse>[];
  String _givenName = null;
  int _givenHashCode = null;
  var _defaultResponse = () => new CannedResponse(null, (_) => null);

  void _setExpected(CannedResponse cannedResponse) {
    _responses.add(cannedResponse);
  }

  dynamic noSuchMethod(Invocation invocation) {
    if (_whenInProgress) {
      _whenCall = new _WhenCall(this, invocation);
      return null;
    } else if (_verificationInProgress) {
      _verifyCalls.add(new _VerifyCall(this, invocation));
      return null;
    } else {
      _realCalls.add(new RealCall(this, invocation));
      var cannedResponse = _responses.lastWhere(
          (cr) => cr.matcher.matches(invocation), orElse: _defaultResponse);
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

dynamic spy(dynamic mock, dynamic spiedObject) {
  var mirror = reflect(spiedObject);
  mock._defaultResponse = () => new CannedResponse(
      null, (Invocation realInvocation) => mirror.delegate(realInvocation));
  return mock;
}

class PostExpectation {
  thenReturn(expected) {
    return _completeWhen((_) => expected);
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
      return roleArg._matcher == null || roleArg._matcher.matches(actArg, {});
//    } else if(roleArg is Mock){
//      return identical(roleArg, actArg);
    } else {
      return roleArg == actArg;
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
      return "${MirrorSystem.getName(key)}: ${invocation.namedArguments[key]}";
    }).toList(growable: false);
    if (mapArgList.isNotEmpty) {
      posArgs.add("{${mapArgList.join(", ")}}");
    }
    String args = posArgs.join(", ");
    String method = MirrorSystem.getName(invocation.memberName);
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

get any => new _ArgMatcher(null, false);
get captureAny => new _ArgMatcher(null, true);
captureThat(Matcher matcher) => new _ArgMatcher(matcher, true);
argThat(Matcher matcher) => new _ArgMatcher(matcher, false);

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
