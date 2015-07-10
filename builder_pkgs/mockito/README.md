Mock library for Dart inspired by [Mockito](https://code.google.com/p/mockito/).

[![Pub](https://img.shields.io/pub/v/mockito.svg)]()
[![Build Status](https://travis-ci.org/fibulwinter/dart-mockito.svg?branch=master)](https://travis-ci.org/fibulwinter/dart-mockito)

Current mock libraries suffer from specifying method names as strings, which cause a lot of problems:
  * Poor refactoring support: rename method and you need manually search/replace it's usage in when/verify clauses.
  * Poor support from IDE: no code-completion, no hints on argument types, can't jump to definition

Dart-mockito fixes it - stubbing and verifying are first-class citizens.

## Let's create mocks
```dart
import 'package:mockito/mockito.dart';

//Real class
class Cat {
  String sound() => "Meow";
  bool eatFood(String food, {bool hungry}) => true;
  void sleep(){}
  int lives = 9;
}

//Mock class
class MockCat extends Mock implements Cat{
  //this tells Dart analyzer you meant not to implement all methods, and not to hint/warn that methods are missing 
  noSuchMethod(i) => super.noSuchMethod(i);
}

//mock creation
var cat = new MockCat();
```

## Let's verify some behaviour!
```dart
//using mock object
cat.sound();
//verify interaction
verify(cat.sound());
```
Once created, mock will remember all interactions. Then you can selectively verify whatever interaction you are interested in.

## How about some stubbing?
```dart
//unstubbed methods return null
expect(cat.sound(), nullValue);
//stubbing - before execution
when(cat.sound()).thenReturn("Purr");
expect(cat.sound(), "Purr");
//you can call it again
expect(cat.sound(), "Purr");
//let's change stub
when(cat.sound()).thenReturn("Meow");
expect(cat.sound(), "Meow");
//you can stub getters
when(cat.lives).thenReturn(9);
expect(cat.lives, 9);
```

By default, for all methods that return value, mock returns null.
Stubbing can be overridden: for example common stubbing can go to fixture setup but the test methods can override it. Please note that overridding stubbing is a potential code smell that points out too much stubbing.
Once stubbed, the method will always return stubbed value regardless of how many times it is called.
Last stubbing is more important - when you stubbed the same method with the same arguments many times. Other words: the order of stubbing matters but it is only meaningful rarely, e.g. when stubbing exactly the same method calls or sometimes when argument matchers are used, etc.

## Argument matchers
```dart
//you can use arguments itself...
when(cat.eatFood("fish")).thenReturn(true);
//..or matchers
when(cat.eatFood(argThat(startsWith("dry"))).thenReturn(false);
//..or mix aguments with matchers
when(cat.eatFood(argThat(startsWith("dry")), true).thenReturn(true);
expect(cat.eatFood("fish"), isTrue);
expect(cat.eatFood("dry food"), isFalse);
expect(cat.eatFood("dry food", hungry: true), isTrue);
//you can also verify using an argument matcher
verify(cat.eatFood("fish"));
verify(cat.eatFood(argThat(contains("food"))));
//you can verify setters
cat.lives = 9;
verify(cat.lives=9);
```
Argument matchers allow flexible verification or stubbing

## Verifying exact number of invocations / at least x / never
```dart
cat.sound();
cat.sound();
//exact number of invocations
verify(cat.sound()).called(2);
//or using matcher
verify(cat.sound()).called(greaterThan(1));
//or never called
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
Verification in order is flexible - you don't have to verify all interactions one-by-one but only those that you are interested in testing in order.

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
//simple capture
cat.eatFood("Fish");
expect(verify(cat.eatFood(capture)).captured.single, "Fish");
//capture multiple calls
cat.eatFood("Milk");
cat.eatFood("Fish");
expect(verify(cat.eatFood(capture)).captured, ["Milk", "Fish"]);
//conditional capture
cat.eatFood("Milk");
cat.eatFood("Fish");
expect(verify(cat.eatFood(captureThat(startsWith("F")).captured, ["Fish"]);
```
## Spy
```dart
//spy creation
var cat = spy(new MockCat(), new Cat());
//stubbing - before execution
when(cat.sound()).thenReturn("Purr");
//using mocked interaction
expect(cat.sound(), "Purr");  
//using real object
expect(cat.lives, 9);   
```
## How it works
The basics of the `Mock` class are nothing special: It uses `noSuchMethod` to catch
all method invocations, and returns the value that you have configured beforehand with
`when()` calls.

The implementation of `when()` is a bit more tricky. Take this example:

```dart
//unstubbed methods return null
expect(cat.sound(), nullValue);
//stubbing - before execution
when(cat.sound()).thenReturn("Purr");
```

Since `cat.sound()` returns `null`, how can the `when()` call configure it?

It works, because `when` is not a function, but a top level getter that _returns_ a function.
Before returning the function, it sets a flag (`_whenInProgress`), so that all `Mock` objects
know to return a "matcher" (internally `_WhenCall`) instead of the expected value. As soon as
the function has been invoked `_whenInProgress` is set back to `false` and Mock objects behave
as normal.

> Be careful never to write `when;` (without the function call) anywhere. This would set
> `_whenInProgress` to `true`, and the next mock invocation will return an unexpected value.

You can look at the `when` and `Mock.noSuchMethod` implementations to see how it's done.
It's very straightforward.
