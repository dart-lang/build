# Frequently asked questions

#### How do I mock a static method, constructor, or top-level function?

Mockito provides its stubbing and verification features by overriding class
instance methods. Since there is no mechanism for overriding static methods,
constructors, or top-level functions, mockito cannot mock them. They are what
they are.

One idea to consider is "Do I need to use mocks to test this code?" For
example, the [test_descriptor package] allows testing file system concepts using
real files, and the [test_process package] supports testing subprocesses using
real subprocesses. `dart:io` also includes an [IOOVerides] class and a
[runWithIOOverrides] function that can be used to mock out the filesystem.

[IOOverrides]: https://api.dart.dev/stable/2.7.2/dart-io/IOOverrides-class.html
[runWithIOOverrides]: https://api.dart.dev/stable/2.7.2/dart-io/IOOverrides/runWithIOOverrides.html

If mocking is still desired, the underlying code may be refactored in order to
enable mocking. One way to get around un-mockable constructors is to change the
function in which the constructor is being called. Instead of constructing an
object, accept one.

```dart
// BEFORE:
void f() {
  var foo = Foo();
  // ...
}

// AFTER
void f(Foo foo) {
  // ...
}
```

In tests, you can declare a MockFoo class which implements Foo, and pass such
an object to `f`.

You can also refactor code which makes much use of such constructors or static
methods to use a wrapper system. For example, instead of calling
`Directory.current` or `new File` throughout your code, use the
[file package]. You can start with a [FileSystem] object (a [LocalFileSystem]
for production and a [MemoryFileSystem] for tests), and use its wrapper methods
([`currentDirectory`] replaces `Directory.current`, [`file()`] replaces
`File()`). Another example of this pattern is the [io package] and its
[ProcessManager] class.


[test_descriptor package]: https://pub.dev/documentation/test_descriptor
[test_process package]: https://pub.dev/packages/test_process
[file package]: https://pub.dev/packages/file
[FileSystem]: https://pub.dev/documentation/file/latest/file/FileSystem-class.html
[LocalFileSystem]: https://pub.dev/documentation/file/latest/local/LocalFileSystem-class.html
[MemoryFileSystem]: https://pub.dev/documentation/file/latest/memory/MemoryFileSystem-class.html
[`currentDirectory`]: https://pub.dev/documentation/file/latest/file/FileSystem/currentDirectory.html
[`file()`]: https://pub.dev/documentation/file/latest/file/FileSystem/file.html
[io package]: https://pub.dev/packages/io
[ProcessManager]: https://pub.dev/documentation/io/latest/io/ProcessManager-class.html

#### How do I mock an extension method?

If there is no way to override some kind of function, then mockito cannot mock
it. See the above answer for further explanation, and alternatives.

#### Why can a method call not be verified multiple times?

When mockito verifies a method call (via [`verify`] or [`verifyInOrder`]), it
marks the call as "verified", which excludes the call from further
verifications. For example:

```dart
cat.eatFood("fish");
verify(cat.eatFood("fish"));  // This call succeeds.
verify(cat.eatFood(any));  // This call fails.
```

In order to make multiple reasonings about a call, for example to assert on the
arguments, make one verification call, and save the captured arguments:

```dart
cat.hunt("home", "birds");
var captured = verify(cat.hunt(captureAny, captureAny)).captured.single;
expect(captured[0], equals("home"));
expect(captured[1], equals("birds"));
```

If you need to verify the number of types a method was called, _and_ capture the
arguments, save the verification object:

```dart
cat.hunt("home", "birds");
cat.hunt("home", "lizards");
var verification = verify(cat.hunt("home", captureAny));
verification.called(greaterThan(2));
var firstCall = verification.captured[0];
var secondCall = verification.captured[1];

expect(firstCall, equals(["birds"]));
expect(secondCall, equals(["lizards"]));
```

#### How does mockito work?

The basics of the `Mock` class are nothing special: It uses `noSuchMethod` to
catch all method invocations, and returns the value that you have configured
beforehand with `when()` calls.

The implementation of `when()` is a bit more tricky. Take this example:

```dart
// Unstubbed methods return null:
expect(cat.sound(), nullValue);

// Stubbing - before execution:
when(cat.sound()).thenReturn("Purr");
```

Since `cat.sound()` returns `null`, how can the `when()` call configure it?

It works, because `when` is not a function, but a top level getter that
_returns_ a function.  Before returning the function, it sets a flag
(`_whenInProgress`), so that all `Mock` objects know to return a "matcher"
(internally `_WhenCall`) instead of the expected value. As soon as the function
has been invoked `_whenInProgress` is set back to `false` and Mock objects
behave as normal.

Argument matchers work by storing the wrapped arguments, one after another,
until the `when` (or `verify`) call gathers everything that has been stored,
and creates an InvocationMatcher with the arguments. This is a simple process
for positional arguments: the order in which the arguments has been stored
should be preserved for matching an invocation. Named arguments are trickier:
their evaluation order is not specified, so if Mockito blindly stored them in
the order of their evaluation, it wouldn't be able to match up each argument
matcher with the correct name. This is why each named argument matcher must
repeat its own name. `foo: anyNamed('foo')` tells Mockito to store an argument
matcher for an invocation under the name 'foo'.

> **Be careful** never to write `when;` (without the function call) anywhere.
> This would set `_whenInProgress` to `true`, and the next mock invocation will
> return an unexpected value.

The same goes for "chaining" mock objects in a test call. This will fail:

```dart
var mockUtils = MockUtils();
var mockStringUtils = MockStringUtils();

// Setting up mockUtils.stringUtils to return a mock StringUtils implementation
when(mockUtils.stringUtils).thenReturn(mockStringUtils);

// Some tests

// FAILS!
verify(mockUtils.stringUtils.uppercase()).called(1);
// Instead use this:
verify(mockStringUtils.uppercase()).called(1);
```

This fails, because `verify` sets an internal flag, so mock objects don't
return their mocked values anymore but their matchers. So
`mockUtils.stringUtils` will *not* return the mocked `stringUtils` object you
put inside.

You can look at the `when` and `Mock.noSuchMethod` implementations to see how
it's done.  It's very straightforward.

[`verify`]: https://pub.dev/documentation/mockito/latest/mockito/verify.html
[`verifyInOrder`]: https://pub.dev/documentation/mockito/latest/mockito/verifyInOrder.html
