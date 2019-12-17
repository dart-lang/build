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

import 'package:mockito/src/invocation_matcher.dart';
import 'package:test/test.dart';

Invocation lastInvocation;

void main() {
  const stub = Stub();

  group('$isInvocation', () {
    test('positional arguments', () {
      stub.say('Hello');
      var call1 = Stub.lastInvocation;
      stub.say('Hello');
      var call2 = Stub.lastInvocation;
      stub.say('Guten Tag');
      var call3 = Stub.lastInvocation;
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
      stub.eat('Chicken', alsoDrink: true);
      var call1 = Stub.lastInvocation;
      stub.eat('Chicken', alsoDrink: true);
      var call2 = Stub.lastInvocation;
      stub.eat('Chicken', alsoDrink: false);
      var call3 = Stub.lastInvocation;
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
      stub.lie(true);
      var call1 = Stub.lastInvocation;
      stub.lie(true);
      var call2 = Stub.lastInvocation;
      stub.lie(false);
      var call3 = Stub.lastInvocation;
      shouldPass(call1, isInvocation(call2));
      shouldFail(
        call1,
        isInvocation(call3),
        'Expected: lie(<false>) '
        "Actual: <Instance of '${call3.runtimeType}'> "
        'Which: Does not match lie(<true>)',
      );
    });

    test('getter', () {
      stub.value;
      var call1 = Stub.lastInvocation;
      stub.value;
      var call2 = Stub.lastInvocation;
      stub.value = true;
      var call3 = Stub.lastInvocation;
      shouldPass(call1, isInvocation(call2));
      shouldFail(
        call1,
        isInvocation(call3),
        // RegExp needed because of https://github.com/dart-lang/sdk/issues/33565
        RegExp('Expected: set value=? <true> '
            "Actual: <Instance of '${call3.runtimeType}'> "
            'Which: Does not match get value'),
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
        // RegExp needed because of https://github.com/dart-lang/sdk/issues/33565
        RegExp('Expected: set value=? <false> '
            "Actual: <Instance of '${call3.runtimeType}'> "
            'Which: Does not match set value=? <true>'),
      );
    });
  });

  group('$invokes', () {
    test('positional arguments', () {
      stub.say('Hello');
      var call = Stub.lastInvocation;
      shouldPass(call, invokes(#say, positionalArguments: ['Hello']));
      shouldPass(call, invokes(#say, positionalArguments: [anything]));
      shouldFail(
        call,
        invokes(#say, positionalArguments: [isNull]),
        'Expected: say(null) '
        "Actual: <Instance of '${call.runtimeType}'> "
        "Which: Does not match say('Hello')",
      );
    });

    test('named arguments', () {
      stub.fly(miles: 10);
      var call = Stub.lastInvocation;
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
  void say(String text);
  void eat(String food, {bool alsoDrink});
  void lie([bool facingDown]);
  void fly({int miles});
}

/// An example of a class that captures Invocation objects.
///
/// Any call always returns an [Invocation].
class Stub implements Interface {
  static Invocation lastInvocation;

  const Stub();

  @override
  void noSuchMethod(Invocation invocation) {
    lastInvocation = invocation;
  }
}

// Inspired by shouldFail() from package:test, which doesn't expose it to users.
void shouldFail(value, Matcher matcher, expected) {
  const reason = 'Expected to fail.';
  try {
    expect(value, matcher);
    fail(reason);
  } on TestFailure catch (e) {
    final matcher = expected is String
        ? equalsIgnoringWhitespace(expected)
        : expected is RegExp ? contains(expected) : expected;
    expect(collapseWhitespace(e.message), matcher, reason: reason);
  }
}

void shouldPass(value, Matcher matcher) {
  expect(value, matcher);
}
