Mock library for Dart inspired by [Mockito](https://github.com/mockito/mockito).

[![Pub](https://img.shields.io/pub/v/mockito.svg)](https://pub.dartlang.org/packages/mockito)
[![Build Status](https://travis-ci.org/dart-lang/mockito.svg?branch=master)](https://travis-ci.org/dart-lang/mockito)

## Let's create mocks

```dart
import 'package:mockito/mockito.dart';

// Real class
class Cat {
  String sound() => "Meow";
  bool eatFood(String food, {bool hungry}) => true;
  Future<void> chew() async => print("Chewing...");
  int walk(List<String> places) => 7;
  void sleep() {}
  void hunt(String place, String prey) {}
  int lives = 9;
}

// Mock class
class MockCat extends Mock implements Cat {}

// Create mock object.
var cat = MockCat();
```

## Let's verify some behaviour!

```dart
// Interact with the mock object.
cat.sound();
// Verify the interaction.
verify(cat.sound());
```

Once created, mock will remember all interactions. Then you can selectively
verify whatever interaction you are interested in.

## How about some stubbing?

```dart
// Unstubbed methods return null.
expect(cat.sound(), nullValue);

// Stub a mock method before interacting.
when(cat.sound()).thenReturn("Purr");
expect(cat.sound(), "Purr");

// You can call it again.
expect(cat.sound(), "Purr");

// Let's change the stub.
when(cat.sound()).thenReturn("Meow");
expect(cat.sound(), "Meow");

// You can stub getters.
when(cat.lives).thenReturn(9);
expect(cat.lives, 9);

// You can stub a method to throw.
when(cat.lives).thenThrow(RangeError('Boo'));
expect(() => cat.lives, throwsRangeError);

// We can calculate a response at call time.
var responses = ["Purr", "Meow"];
when(cat.sound()).thenAnswer((_) => responses.removeAt(0));
expect(cat.sound(), "Purr");
expect(cat.sound(), "Meow");
```

By default, for all methods that return a value, `mock` returns `null`.
Stubbing can be overridden: for example common stubbing can go to fixture setup
but the test methods can override it.  Please note that overridding stubbing is
a potential code smell that points out too much stubbing.  Once stubbed, the
method will always return stubbed value regardless of how many times it is
called.  Last stubbing is more important, when you stubbed the same method with
the same arguments many times. In other words: the order of stubbing matters,
but it is meaningful rarely, e.g. when stubbing exactly the same method calls
or sometimes when argument matchers are used, etc.

### A quick word on async stubbing

**Using `thenReturn` to return a `Future` or `Stream` will throw an
`ArgumentError`.** This is because it can lead to unexpected behaviors. For
example:

* If the method is stubbed in a different zone than the zone that consumes the
  `Future`, unexpected behavior could occur.
* If the method is stubbed to return a failed `Future` or `Stream` and it
  doesn't get consumed in the same run loop, it might get consumed by the
  global exception handler instead of an exception handler the consumer applies.

Instead, use `thenAnswer` to stub methods that return a `Future` or `Stream`.

```
// BAD
when(mock.methodThatReturnsAFuture())
    .thenReturn(Future.value('Stub'));
when(mock.methodThatReturnsAStream())
    .thenReturn(Stream.fromIterable(['Stub']));

// GOOD
when(mock.methodThatReturnsAFuture())
    .thenAnswer((_) => Future.value('Stub'));
when(mock.methodThatReturnsAStream())
    .thenAnswer((_) => Stream.fromIterable(['Stub']));

```

If, for some reason, you desire the behavior of `thenReturn`, you can return a
pre-defined instance.

```
// Use the above method unless you're sure you want to create the Future ahead
// of time.
final future = Future.value('Stub');
when(mock.methodThatReturnsAFuture()).thenAnswer((_) => future);
```


## Argument matchers

Mockito provides the concept of the "argument matcher" (using the class
ArgMatcher) to capture arguments and to track how named arguments are passed.
In most cases, both plain arguments and argument matchers can be passed into
mock methods:

```dart
// You can use plain arguments themselves
when(cat.eatFood("fish")).thenReturn(true);

// ... including collections
when(cat.walk(["roof","tree"])).thenReturn(2);

// ... or matchers
when(cat.eatFood(argThat(startsWith("dry")))).thenReturn(false);

// ... or mix aguments with matchers
when(cat.eatFood(argThat(startsWith("dry")), hungry: true)).thenReturn(true);
expect(cat.eatFood("fish"), isTrue);
expect(cat.walk(["roof","tree"]), equals(2));
expect(cat.eatFood("dry food"), isFalse);
expect(cat.eatFood("dry food", hungry: true), isTrue);

// You can also verify using an argument matcher.
verify(cat.eatFood("fish"));
verify(cat.walk(["roof","tree"]));
verify(cat.eatFood(argThat(contains("food"))));

// You can verify setters.
cat.lives = 9;
verify(cat.lives=9);
```

If an argument other than an ArgMatcher (like `any`, `anyNamed()`, `argThat`,
`captureArg`, etc.) is passed to a mock method, then the `equals` matcher is
used for argument matching. If you need more strict matching consider use
`argThat(identical(arg))`.

However, note that `null` cannot be used as an argument adjacent to ArgMatcher
arguments, nor as an un-wrapped value passed as a named argument. For example:

```dart
verify(cat.hunt("backyard", null)); // OK: no arg matchers.
verify(cat.hunt(argThat(contains("yard")), null)); // BAD: adjacent null.
verify(cat.hunt(argThat(contains("yard")), argThat(isNull))); // OK: wrapped in an arg matcher.
verify(cat.eatFood("Milk", hungry: null)); // BAD: null as a named argument.
verify(cat.eatFood("Milk", hungry: argThat(isNull))); // BAD: null as a named argument.
```

## Named arguments

Mockito currently has an awkward nuisance to its syntax: named arguments and
argument matchers require more specification than you might think: you must
declare the name of the argument in the argument matcher. This is because we
can't rely on the position of a named argument, and the language doesn't
provide a mechanism to answer "Is this element being used as a named element?"

```dart
// GOOD: argument matchers include their names.
when(cat.eatFood(any, hungry: anyNamed('hungry'))).thenReturn(true);
when(cat.eatFood(any, hungry: argThat(isNotNull, named: 'hungry'))).thenReturn(false);
when(cat.eatFood(any, hungry: captureAnyNamed('hungry'))).thenReturn(false);
when(cat.eatFood(any, hungry: captureThat(isNotNull, named: 'hungry'))).thenReturn(true);

// BAD: argument matchers do not include their names.
when(cat.eatFood(any, hungry: any)).thenReturn(true);
when(cat.eatFood(any, hungry: argThat(isNotNull))).thenReturn(false);
when(cat.eatFood(any, hungry: captureAny)).thenReturn(false);
when(cat.eatFood(any, hungry: captureThat(isNotNull))).thenReturn(true);
```

## Verifying exact number of invocations / at least x / never

```dart
cat.sound();
cat.sound();

// Exact number of invocations
verify(cat.sound()).called(2);

// Or using matcher
verify(cat.sound()).called(greaterThan(1));

// Or never called
verifyNever(cat.eatFood(any));
```

## Verification in order

```dart
cat.eatFood("Milk");
cat.sound();
cat.eatFood("Fish");
verifyInOrder([
  cat.eatFood("Milk"),
  cat.sound(),
  cat.eatFood("Fish")
]);
```

Verification in order is flexible - you don't have to verify all interactions
one-by-one but only those that you are interested in testing in order.

## Making sure interaction(s) never happened on mock

```dart
verifyZeroInteractions(cat);
```

## Finding redundant invocations

```dart
cat.sound();
verify(cat.sound());
verifyNoMoreInteractions(cat);
```

## Capturing arguments for further assertions

```dart
// Simple capture
cat.eatFood("Fish");
expect(verify(cat.eatFood(captureAny)).captured.single, ["Fish"]);

// Capture multiple calls
cat.eatFood("Milk");
cat.eatFood("Fish");
expect(verify(cat.eatFood(captureAny)).captured, ["Milk", "Fish"]);

// Conditional capture
cat.eatFood("Milk");
cat.eatFood("Fish");
expect(verify(cat.eatFood(captureThat(startsWith("F")))).captured, ["Fish"]);
```

## Waiting for an interaction

```dart
// Waiting for a call.
cat.eatFood("Fish");
await untilCalled(cat.chew()); // Completes when cat.chew() is called.

// Waiting for a call that has already happened.
cat.eatFood("Fish");
await untilCalled(cat.eatFood(any)); // Completes immediately.
```

## Writing a fake

You can also write a simple fake class that implements a real class, by
extending [Fake]. Fake allows your subclass to satisfy the implementation of
your real class, without overriding the methods that aren't used in your test;
the Fake class implements the default behavior of throwing [UnimplementedError]
(which you can override in your fake class):

```dart
// Fake class
class FakeCat extends Fake implements Cat {
  @override
  bool eatFood(String food, {bool hungry}) {
    print('Fake eat $food');
    return true;
  }
}

void main() {
  // Create a new fake Cat at runtime.
  var cat = FakeCat();

  cat.eatFood("Milk"); // Prints 'Fake eat Milk'.
  cat.sleep(); // Throws.
}
```

[Fake]: https://pub.dev/documentation/mockito/latest/mockito/Fake-class.html
[UnimplementedError]: https://api.dartlang.org/stable/dart-core/UnimplementedError-class.html

## Resetting mocks

```dart
// Clearing collected interactions:
cat.eatFood("Fish");
clearInteractions(cat);
cat.eatFood("Fish");
verify(cat.eatFood("Fish")).called(1);

// Resetting stubs and collected interactions:
when(cat.eatFood("Fish")).thenReturn(true);
cat.eatFood("Fish");
reset(cat);
when(cat.eatFood(any)).thenReturn(false);
expect(cat.eatFood("Fish"), false);
```

## Debugging

```dart
// Print all collected invocations of any mock methods of a list of mock objects:
logInvocations([catOne, catTwo]);

// Throw every time that a mock method is called without a stub being matched:
throwOnMissingStub(cat);
```

## Best Practices

Testing with real objects is preferred over testing with mocks - if you can
construct a real instance for your tests, you should! If there are no calls to
`verify` in your test, it is a strong signal that you may not need mocks at all,
though it's also OK to use a `Mock` like a stub. When it's not possible to use
the real object, a tested implementation of a fake is the next best thing - it's
more likely to behave similarly to the real class than responses stubbed out in
tests. Finally an object which `extends Fake` using manually overridden methods
is preferred over an object which `extends Mock` used as either a stub or a
mock.

A class which `extends Mock` should _never_ stub out it's own responses with
`when` in it's constructor or anywhere else. Stubbed responses should be defined
in the tests where they are used. For responses controlled outside of the test
use `@override` methods for either the entire interface, or with `extends Fake`
to skip some parts of the interface.

Similarly, a class which `extends Mock` should _never_ have any `@override`
methods. These can't be stubbed by tests and can't be tracked and verified by
Mockito. A mix of test defined stubbed responses and mock defined overrides will
lead to confusion. It is OK to define _static_ utilities on a class which
`extends Mock` if it helps with code structure.

## Frequently asked questions

Read more information about this package in the
[FAQ](https://github.com/dart-lang/mockito/blob/master/FAQ.md).

**NOTE:** This is not an official Google product
