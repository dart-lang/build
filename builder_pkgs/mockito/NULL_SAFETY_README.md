# Null Safety

Dart's new null safety type system allows method parameter types and method
return types to be non-nullable. For example:

```dart
class HttpServer {
  Uri start(int port)  {
    // ...
  }
}
```

The method, `start`, takes a _non_-nullable int argument, and returns a
_non_-nullable Uri. Under the null safety type system, it is illegal to pass
`null` to `start`, and it is illegal for `start` (or any overriding methods in
any sub-classes) to return `null`. This plays havoc with the mechanisms that
Mockito uses to stub methods.

<!-- TODO(srawlins): point to details somewhere. -->

Here is the standard way of defining a mock for the HttpServer class:

```dart
class MockHttpServer extends Mock implements HttpServer {}
```

And here is the standard way of stubbing the `start` method.

```dart
var server = MockHttpServer();
var uri = Uri.parse('http://localhost:8080');
when(server.start(any)).thenReturn(uri);
```

This code is, unfortunately, illegal under null safety in two ways. For details,
see the section at the bottom, **Problems with typical mocking and stubbing**.

There are two ways to write a mock class that supports non-nullable types: we
can use the [build_runner] package to _generate_ a mock class, or we can
manually implement it, overriding specific methods to handle non-nullability.

## Solution 1: code generation

Mockito provides a "one size fits all" code-generating solution for packages
that use null safety which can generate a mock for any class. To direct Mockito
to generate mock classes, use the new `@GenerateMocks` annotation, and import
the generated mocks library. Let's continue with the HTTP server example:

```dart
// http_server.dart:
class HttpServer {
  Uri start(int port)  {
    // ...
  }
}
```

```dart
// http_server_test.dart:
import 'package:test/test.dart';
import 'http_server.dart';

void main() {
  test('test', () {
    var httpServer = MockHttpServer();
    // We want to stub the `start` method.
  });
}
```

In order to generate a mock for the HttpServer class, we edit
`http_server_test.dart`:

1. import mockito's annotations library,
2. annotate a top-level library member (like an import, or the main function)
   with `@GenerateMocks`,
3. import the generated mocks library,
4. change `httpServer` from an HttpServer to the generated class,
   MockHttpServer.

```dart
// http_server_test.dart:
import 'package:mockito/annotations.dart';
import 'package:test/test.dart';
import 'http_server.dart';
import 'http_server_test.mocks.dart';

@GenerateMocks([HttpServer])
void main() {
  test('test', () {
    var httpServer = MockHttpServer();
    // We want to stub the `start` method.
  });
}
```

We need to depend on build_runner. Add a dependency in the `pubspec.yaml` file,
under `dev_dependencies`: something like `build_runner: ^1.10.0`.

The final step is to run build_runner in order to generate the new library:

```shell
pub run build_runner build
```

build_runner will generate the `http_server_test.mocks.dart` file which we
import in `http_server_test.dart`. The path is taken directly from the file in
which `@GenerateMocks` was found, changing the `.dart` suffix to `.mocks.dart`.
If we previously had a shared mocks file which declared mocks to be used by
multiple tests, for example named `shared_mocks.dart`, we can edit that file to
generate mocks, and then import `shared_mocks.mocks.dart` in the tests which
previously imported `shared_mocks.dart`.

### Custom generated mocks

Mockito might need some additional input in order to generate the right mock for
certain use cases. We can generate custom mock classes by passing MockSpec
objects to the `customMocks` list argument in `@GenerateMocks`.

#### Mock with a custom name

Use MockSpec's constructor's `as` named parameter to use a non-standard name for
the mock class. For example:

```dart
@GenerateMocks([], customMocks: [MockSpec<Foo>(as: #BaseMockFoo)])
```

Mockito will generate a mock class called `BaseMockFoo`, instead of the default,
`MockFoo`. This can help to work around name collisions or to give a more
specific name to a mock with type arguments (See below).

#### Non-generic mock of a generic class

To generate a mock class which extends a class with type arguments, specify
them on MockSpec's type argument:

```dart
@GenerateMocks([], customMocks: [MockSpec<Foo<int>>(as: #MockFooOfInt)])
```

Mockito will generate `class MockFooOfInt extends Mock implements Foo<int>`.

#### Old "missing stub" behavior

When a method of a generated mock class is called, which does not match any
method stub created with the `when` API, the call will throw an exception. To
use the old default behavior of returning null (which doesn't make a lot of
sense in the Null safety type system), for legacy code, use
`returnNullOnMissingStub`:

```dart
@GenerateMocks([], customMocks: [MockSpec<Foo>(returnNullOnMissingStub: true)])
```

#### Mocking members with non-nullable type variable return types

If a class has a member with a type variable as a return type (for example,
`T get<T>();`), mockito cannot generate code which will internally return a
valid value. For example, given this class and test:

```dart
abstract class Foo {
  T m<T>(T a, int b);
}

@GenerateMocks([], customMocks: [MockSpec<Foo>(as: #MockFoo)])
void testFoo(Foo foo) {
  when(foo.m(7)).thenReturn(42);
}
```

Mockito needs a valid _value_ which the above call, `foo.m(7)`, will return.

##### Overriding unsupported members

One way to generate a mock class with such members is to use
`unsupportedMembers`:

```dart
@GenerateMocks([], customMocks: [
  MockSpec<Foo>(unsupportedMembers: {#method}),
])
```

Mockito uses this instruction to generate an override, which simply throws an
UnsupportedError, for each specified unsupported member. Such overrides are not
useful at runtime, but their presence makes the mock class a valid
implementation of the class-to-mock.

##### Fallback generators

In order to generate a mock class with a more useful implementation of a member
which returns a non-nullable type variable, use MockSpec's `fallbackGenerators`
parameter. Specify a mapping from the member to a top level function with
_almost_ the same signature as the member. The function must have the same
return type as the member, and it must have the same positional and named
parameters as the member, except that each parameter must be made nullable:

```dart
abstract class Foo {
  T m<T>(T a, int b);
}

T mShim<T>(T a, int? b) {
  if (a is int) return 1;
  throw 'unknown';
}

@GenerateMocks([], customMocks: [
  MockSpec<Foo>(as: #MockFoo, fallbackGenerators: {#m: mShim})
])
```

The fallback values will never be returned from a real member call; these are
not stub return values. They are only used internally by mockito as valid return
values.

## Solution 2: manual mock implementation

**In the general case, we strongly recommend generating mocks with the above
method.** However, there may be cases where a manual mock implementation is more
desirable.

Perhaps code generation with [build_runner] is not a good route for our package.
Perhaps we wish to mock just one class which has mostly nullable parameter types
and return types. In this case, it may not be too onerous to implement the mock
class manually.

### The general process

Only public methods (including getters, setters, and operators) which either
have a non-nullable return type, or a parameter with a non-nullable type, need
to be overridden. For each such method:

1. Override the method with a new declaration inside the mock class.
2. For each non-nullable parameter, expand its type to be nullable.
3. Call `super.noSuchMethod`, passing in an Invocation object which includes
   all of the values passed to the override.
4. If the return type is non-nullable, pass a second argument to
   `super.noSuchMethod`, a value which can function as a return value.

Let's look at an example HttpServer class again:

```dart
class HttpServer {
  void start(int port) { ... }

  Uri get uri { ... }
}
```

Before null safety, implementing a mock class was a simple one-liner:

```dart
class MockHttpServer extends Mock implements HttpServer {}
```

This class implements each of the methods in HttpServer's public interface via
the `noSuchMethod` method found in the Mock class. Under null safety, we need to
override that implementation for every method which has one or more non-nullable
parameters, or which has a non-nullable return type.

### Manually override a method with a non-nullable parameter type.

First let's override `start` with an implementation that expands the single
parameter's type to be nullable, and call `super.noSuchMethod` to handle the
stubbing and verifying:

```dart
class MockHttpServer extends Mock implements HttpServer {
  @override
  void start(int? port) =>
      super.noSuchMethod(Invocation.method(#start, [port]));
}
```

There is a lot going on in this snippet. Let's examine it carefully:

1. We expand every non-nullable parameter to be nullable. `HttpServer.start`'s
   `port` parameter is a non-nullable int, so our override expands this to
   parameter to be a nullable int. This is done by adding a `?` after the
   parameter type.
2. We just write a simple arrow function which calls `super.noSuchMethod`,
   passing in the contents of the current call to `MockHttpServer.start`. In
   this case, the single argument is an [Invocation].
3. Since `start` is a method, we use the [`Invocation.method`] constructor.
4. The first argument to `Invocation.method` is the name of the method, as a
   Symbol: `#start`.
5. The second argument to `Invocation.method` is the exact list of positional
   arguments, unchanged, which was passed to `MockHttpServer.start`: `[port]`.

That's it! The override implementation is all boilerplate. See the API for
[`Invocation.method`] to see how named parameters are passed. See the other
[Invocation] constructors to see how to implement an override for an operator or
a setter.

### Manually override a method with a non-nullable return type.

Next let's override `get uri`. It would be illegal to override a getter which
returns a non-nullable Uri with a getter which returns a _nullable_ Uri.
Instead, the override must use an actual Uri object to satisfy the type
contract; this getter will also just call `super.noSuchMethod`, but will pass an
additional argument:

```dart
class MockHttpServer extends Mock implements HttpServer {
  @override
  Uri get uri =>
      super.noSuchMethod(
          Invocation.getter(#uri), returnValue: Uri.http('example.org', '/'));
}
```

This looks quite similar to the override which expands non-nullable parameters.
The key difference is the second argument passed to `super.noSuchMethod`: the
real Uri object. During stubbing and verification, `Mock.noSuchMethod` will
return this value from its own implementation of `get uri`, to avoid any runtime
error.

This return value is specified for exactly one purpose: _to satisfy the
non-nullable return type_. This return value must not be confused with the stub
return values used in `thenReturn` or `thenAnswer`. Let's look at some examples:

```dart
var httpServer = MockHttpServer();
when(httpServer.uri).thenReturn(Uri.http('dart.dev', '/'));
httpServer.uri;
verify(httpServer.uri).called(1);
```

During stubbing (`when`) and verification (`verify`), the value returned by
`httpServer.uri` is immediately dropped and never used. In a real call, like the
middle line, `Mock.noSuchMethod` searches for a matching stubbed call and
returns the associated return value. Our override of `get uri` then returns that
value as well.

## Problems with typical mocking and stubbing

Why does mocking have to change under null safety? What about mockito's regular
mocking depends so much on `null`?

### Argument matchers

Mockito's helpful argument matchers like `any`, `argThat`, `captureAny`, etc.
all return `null`. In the code above, `null` is being passed to `start`. `null`
is used because, _before_ null safety, it is the only value that is legally
assignable to any type. Under null safety, however, it is illegal to pass `null`
where a non-nullable int is expected.

### Return types

MockHttpServer's implementation of `start` is inherited from mockito's `Mock`.
`Mock` implements `start` by declaring a `noSuchMethod` override. During a
`when` call, or a `verify` call, the `noSuchMethod` implementation always
returns `null`. Again, prior to null safety, `null` is the only value that fits
any return type, but under null safety, the `start` method must not return
`null`.

[build_runner]: https://pub.dev/packages/build_runner

[Invocation]: https://api.dart.dev/stable/dart-core/Invocation-class.html
[`Invocation.method`]: https://api.dart.dev/stable/dart-core/Invocation/Invocation.method.html
