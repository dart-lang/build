import 'package:mockito/src/invocation_matcher.dart';
import 'package:test/test.dart';

Invocation lastInvocation;

void main() {
  const stub = const Stub();

  group('$isInvocation', () {
    test('positional arguments', () {
      var call1 = stub.say('Hello');
      var call2 = stub.say('Hello');
      var call3 = stub.say('Guten Tag');
      shouldPass(call1, isInvocation(call2));
      shouldFail(
        call1,
        isInvocation(call3),
        "Expected: say('Guten Tag') "
            "Actual: <Instance of '${call3.runtimeType}'> "
            "Which: Does not match say('Hello')",
      );
    });

    test('named arguments', () {
      var call1 = stub.eat('Chicken', alsoDrink: true);
      var call2 = stub.eat('Chicken', alsoDrink: true);
      var call3 = stub.eat('Chicken', alsoDrink: false);
      shouldPass(call1, isInvocation(call2));
      shouldFail(
        call1,
        isInvocation(call3),
        "Expected: eat('Chicken', 'alsoDrink: false') "
            "Actual: <Instance of '${call3.runtimeType}'> "
            "Which: Does not match eat('Chicken', 'alsoDrink: true')",
      );
    });

    test('optional arguments', () {
      var call1 = stub.lie(true);
      var call2 = stub.lie(true);
      var call3 = stub.lie(false);
      shouldPass(call1, isInvocation(call2));
      shouldFail(
        call1,
        isInvocation(call3),
        "Expected: lie(<false>) "
            "Actual: <Instance of '${call3.runtimeType}'> "
            "Which: Does not match lie(<true>)",
      );
    });

    test('getter', () {
      var call1 = stub.value;
      var call2 = stub.value;
      stub.value = true;
      var call3 = Stub.lastInvocation;
      shouldPass(call1, isInvocation(call2));
      shouldFail(
        call1,
        isInvocation(call3),
        "Expected: set value= <true> "
            "Actual: <Instance of '${call3.runtimeType}'> "
            "Which: Does not match get value",
      );
    });

    test('setter', () {
      stub.value = true;
      var call1 = Stub.lastInvocation;
      stub.value = true;
      var call2 = Stub.lastInvocation;
      stub.value = false;
      var call3 = Stub.lastInvocation;
      shouldPass(call1, isInvocation(call2));
      shouldFail(
        call1,
        isInvocation(call3),
        "Expected: set value= <false> "
            "Actual: <Instance of '${call3.runtimeType}'> "
            "Which: Does not match set value= <true>",
      );
    });
  });

  group('$invokes', () {
    test('positional arguments', () {
      var call = stub.say('Hello');
      shouldPass(call, invokes(#say, positionalArguments: ['Hello']));
      shouldPass(call, invokes(#say, positionalArguments: [anything]));
      shouldFail(
        call,
        invokes(#say, positionalArguments: [isNull]),
        "Expected: say(null) "
            "Actual: <Instance of '${call.runtimeType}'> "
            "Which: Does not match say('Hello')",
      );
    });

    test('named arguments', () {
      var call = stub.fly(miles: 10);
      shouldPass(call, invokes(#fly, namedArguments: {#miles: 10}));
      shouldPass(call, invokes(#fly, namedArguments: {#miles: greaterThan(5)}));
      shouldFail(
        call,
        invokes(#fly, namedArguments: {#miles: 11}),
        "Expected: fly('miles: 11') "
            "Actual: <Instance of '${call.runtimeType}'> "
            "Which: Does not match fly('miles: 10')",
      );
    });
  });
}

abstract class Interface {
  bool get value;
  set value(value);
  say(String text);
  eat(String food, {bool alsoDrink});
  lie([bool facingDown]);
  fly({int miles});
}

/// An example of a class that captures Invocation objects.
///
/// Any call always returns an [Invocation].
class Stub implements Interface {
  static Invocation lastInvocation;

  const Stub();

  @override
  noSuchMethod(Invocation invocation) => lastInvocation = invocation;
}

// Copied from package:test, which doesn't expose it to users.
// https://github.com/dart-lang/matcher/issues/39
void shouldFail(value, Matcher matcher, expected) {
  var failed = false;
  try {
    expect(value, matcher);
  } on TestFailure catch (err) {
    failed = true;

    var _errorString = err.message;

    if (expected is String) {
      expect(_errorString, equalsIgnoringWhitespace(expected));
    } else {
      expect(_errorString.replaceAll('\n', ''), expected);
    }
  }

  expect(failed, isTrue, reason: 'Expected to fail.');
}

void shouldPass(value, Matcher matcher) {
  expect(value, matcher);
}
