## 5.3.0-dev

* Introduce a new `MockSpec` parameter, `onMissingStub`, which allows
  specifying three actions to take when a real call is made to a mock method
  with no matching stub. The two existing behaviors are the default
  behavior of throwing an exception, and the legacy behavior of returning
  `null`. A new behavior is also introduced: returning a legal default value.
  With this behavior, legal default values are returned for any given type.
* Deprecate the `MockSpec` `returnNullOnMissingStub` parameter in favor of the
  new `onMissingStub` parameter.
* Introduce a new `@GenerateNiceMocks` annotation, that uses the new
  "return a legal value" behavior for missing stubs.

## 5.2.0

* Fix generation of methods with return type of `FutureOr<T>` for generic,
  potentially nullable `T`.
* Support `@GenerateMocks` annotations on `import` and `export` directives.
* Support analyzer 4.x.

## 5.1.0

* In creating mocks for a pre-null-safe library, opt out of null safety in the
  generated code.
* Properly generate method overrides for methods with covariant parameters.
  [#506](https://github.com/dart-lang/mockito/issues/506)
* Correctly generate a `toString` override method for pre-null safe libraries,
  for which the class-to-mock implements `toString` with additional parameters.
* Improve messaging in a MissingStubError, directing to the docs for MockSpec.
* Fix incorrect error when trying to mock a method with a parameter with inner
  function types (like in type arguments) which are potentially non-nullable.
  [#476](https://github.com/dart-lang/mockito/issues/476)
* Allow fallback generators to be applied for getters.
* Support generating a mock class for a class with members with non-nullable
  unknown return types via a new parameter on `MockSpec` called
  `unsupportedMembers`. See [NULL_SAFETY_README][] for details.

## 5.0.17

* Report when a class cannot be mocked because an inherited method or property
  accessor requires a private type.
  [#446](https://github.com/dart-lang/mockito/issues/446)
* Do not needlessly implement `toString` unless the class-to-mock implements
  `toString` with additional parameters.
  [#461](https://github.com/dart-lang/mockito/issues/461)
* Support analyzer 3.x.

## 5.0.16

* Fix type reference for nested, imported types found in type arguments on a
  custom class-to-mock.
  [#469](https://github.com/dart-lang/mockito/issues/469)
* Bump minimum analyzer dependency to version 2.1.0.
* Ignore `camel_case_types` lint in generated code.

## 5.0.15

* Fix an issue generating the correct parameter default value given a
  constructor which redirects to a constructor declared in a separate library.
  [#459](https://github.com/dart-lang/mockito/issues/459)

## 5.0.14

* Generate Fake classes with unique names.
  [#441](https://github.com/dart-lang/mockito/issues/441)

## 5.0.13

* Implement methods which have been overridden in the mixin hierarchy properly.
  Previously, mixins were being applied in the wrong order, which could skip
  over one method that overrides another with a different signature.
  [#456](https://github.com/dart-lang/mockito/issues/456)

## 5.0.12

* Use an empty list with a correct type argument for a fallback value for a
  method which returns Iterable.
  [#445](https://github.com/dart-lang/mockito/issues/445)
* When selecting the library that should be imported in order to reference a
  type, prefer a library which exports the library in which the type is
  declared. This avoids some confusion with conditional exports.
  [#443](https://github.com/dart-lang/mockito/issues/443)
* Properly reference types in overridden `toString` implementations.
  [#438](https://github.com/dart-lang/mockito/issues/438)
* Override `toString` in a Fake implementation when the class-to-be-faked has
  a superclass which overrides `toString` with additional parameters.
  [#371](https://github.com/dart-lang/mockito/issues/371)
* Support analyzer 2.x.

## 5.0.11

* Allow two mocks of the same class (with different type arguments) to be
  specified with different fallback generators.
* Allow fallback generators on super types of a mocked class.
* Avoid `inference_failure_on_instance_creation` errors in generated code.
* Ignore `implementation_imports` lint in generated code.
* Support methods with `Function` and `Future<Function>` return types.

## 5.0.10

* Generate a proper mock class when the mocked class overrides `toString`,
  `hashCode`, or `operator==`.
  [#420](https://github.com/dart-lang/mockito/issues/420)
* Override `toString` implementation on generated Fakes in order to match the
  signature of an overriding method which adds optional parameters.
  [#371](https://github.com/dart-lang/mockito/issues/371)
  Properly type methods in a generated mock class which comes from a "custom
  mock" annotation referencing an implicit type. Given a method which references
  type variables defined on their enclosing class (for example, `T` in
  `class Foo<T>`), mockito will now correctly reference `T` in generated code.
  [#422](https://github.com/dart-lang/mockito/issues/422)

## 5.0.9

* Mock classes now implement a type's nested type arguments properly.
  [#410](https://github.com/dart-lang/mockito/issues/410)
* Mock classes now implement API from a class's interface(s) (in addition to
  superclasses and mix ins). Thanks @markgravity.
  [#404](https://github.com/dart-lang/mockito/pull/404)
* A MockSpec passed into a `@GenerateMocks` annotation's `customMocks` list can
  now specify "fallback generators." These are functions which can be used to
  generate fake responses that mockito's code generation needs in order to
  return a value for a method with a generic return type. See
  [NULL_SAFETY_README][] for details.

[NULL_SAFETY_README]: https://github.com/dart-lang/mockito/blob/master/NULL_SAFETY_README.md

## 5.0.8

* Migrate Mockito codegen to null safety.
* Support mocking methods with typed_data List return types.
* Support mocking methods with return types declared in private SDK libraries
  (such as HttpClient and WebSocket, declared in `dart:_http`).
* Do not generate a fake for a class which is only used as a nullable type in a
  Future. [#409](https://github.com/dart-lang/mockito/issues/409)

## 5.0.7

* Properly refer to type parameter bounds with import prefixes.
  [#389](https://github.com/dart-lang/mockito/issues/389)
* Stop referring to private typedefs in generated code.
  [#396](https://github.com/dart-lang/mockito/issues/396)
* Ignore `prefer_const_constructors` and `avoid_redundant_argument_values` lint
  rule violations in generated code.

## 5.0.6

* Support the 0.4.x releases of `test_api`.

## 5.0.5

* Support 4.x releases of code_builder.

## 5.0.4

* Allow calling methods with void return types w/o stubbing.
  [#367](https://github.com/dart-lang/mockito/issues/367)
* Add type argument to dummy `Future` return value.
  [#380](https://github.com/dart-lang/mockito/issues/380)

## 5.0.3

* Support 1.x releases of source_gen.

## 5.0.2

* Support the latest build packages and dart_style.

## 5.0.1

* Update to the latest test_api.
* Fix mock generation of type which has a supertype which mixes in a mixin.
* Fix mock generation of method which returns a non-nullable generic function
  type.

## 5.0.0

* `verifyInOrder` now returns a `List<VerificationResult>` which stores
  arguments which were captured in a call to `verifiyInOrder`.
* **Breaking change:** Remove the public constructor for `VerificationResult`.
* Doesn't allow `verify` been used inside the `verifyInOrder`.

## 5.0.0-nullsafety.7

* Fix generation of duplicate mock getters and setters from inherited classes.

## 5.0.0-nullsafety.6

* Fix generation of method with a parameter with a default value which includes
  a top-level function.
* Migrate example code to null safety.
* **Breaking change:** Change the error which is thrown if a method is called
  and no method stub was found, from NoSuchMethodError to MissingStubError.
* **Breaking change**: `Mock.noSuchMethod`'s optional positional parameter,
  "returnValue" is changed to a named parameter, and a second named parameter is
  added. Any manual mocks which call `Mock.noSuchMethod` with a second
  positional argument will need to instead use the named parameter.
* Allow real calls to mock methods which return `void` (like setters) or
  `Future<void>`, even if unstubbed.

## 5.0.0-nullsafety.5

* Fix `noSuchMethod` invocation of setters in generated mocks.

## 5.0.0-nullsafety.4

* Annotate overridden getters and setters with `@override`.

## 5.0.0-nullsafety.3

* Improve static analysis of generated code.
* Make implicit casts from dynamic in getters explicit.

## 5.0.0-nullsafety.2

* Fix issue with generated code which references a class declared in a part
  ([#310](https://github.com/dart-lang/mockito/issues/310)).

## 5.0.0-nullsafety.1

* Fix an issue with generated mocks overriding methods from Object, such as
  `operator ==` ([#306](https://github.com/dart-lang/mockito/issues/306)).
* Fix an issue with relative imports in generated mocks.

## 5.0.0-nullsafety.0

* Migrate the core libraries and tests to null safety. The builder at
  `lib/src/builder.dart` opts out of null safety.
* Add `http` back to `dev_dependencies`. It's used by the example.
* Remove deprecated `typed`, `typedArgThat`, and `typedCaptureThat` APIs.

## 4.1.3

* Allow using analyzer 0.40.
* `throwOnMissingStub` accepts an optional argument, `exceptionBuilder`, which
  will be called to build and throw a custom exception when a missing stub is
  called.

## 4.1.2

* Introduce experimental code-generated mocks. This is primarily to support
  the new "Non-nullable by default" (NNBD) type system coming soon to Dart.
* Add an optional second parameter to `Mock.noSuchMethod`. This may break
  clients who use the Mock class in unconventional ways, such as overriding
  `noSuchMethod` on a class which extends Mock. To fix, or prepare such code,
  add a second parameter to such overriding `noSuchMethod` declaration.
* Increase minimum Dart SDK to `2.7.0`.
* Remove Fake class; export identical Fake class from the test_api package.

## 4.1.1

* Mark the unexported and accidentally public `setDefaultResponse` as
  deprecated.
* Mark the not useful, and not generally used, `named` function as deprecated.
* Produce a meaningful error message if an argument matcher is used outside of
  stubbing (`when`) or verification (`verify` and `untilCalled`).

## 4.1.0

* Add a `Fake` class for implementing a subset of a class API as overrides
  without misusing the `Mock` class.

## 4.0.0

* Replace the dependency on the
  _[test](https://pub.dev/packages/test)_ package with a dependency on the new
  _[test_api](https://pub.dev/packages/test_api)_ package. This dramatically
  reduces mockito's transitive dependencies.

  This bump can result in runtime errors when coupled with a version of the
  test package older than 1.4.0.

## 3.0.2

* Rollback the _[test_api](https://pub.dev/packages/test_api)_ part of the 3.0.1
  release. This was breaking tests that use Flutter's current test tools, and
  will instead be released as part of Mockito 4.0.0.

## 3.0.1

* Replace the dependency on the
  _[test](https://pub.dev/packages/test)_ package with a dependency on the new
  _[test_api](https://pub.dev/packages/test_api)_ package. This dramatically
  reduces mockito's transitive dependencies.
* Internal improvements to tests and examples.

## 3.0.0

* Deprecate the `typed` API; instead of wrapping other Mockito API calls, like
  `any`, `argThat`, `captureAny`, and `captureArgThat`, with a call to `typed`,
  the regular API calls are to be used by themselves. Passing `any` and
  `captureAny` as named arguments must be replaced with `anyNamed()` and
  `captureAnyNamed`, respectively. Passing `argThat` and `captureThat` as named
  arguments must include the `named` parameter.
* Introduce a backward-and-forward compatible API to help users migrate to
  Mockito 3. See more details in the [upgrading-to-mockito-3] doc.
* `thenReturn` now throws an `ArgumentError` if either a `Future` or `Stream`
  is provided. `thenReturn` calls with futures and streams should be changed to
  `thenAnswer`. See the README for more information.
* Support stubbing of void methods in Dart 2.
* `thenReturn` and `thenAnswer` now support generics and infer the correct
  types from the `when` call.
* Completely remove the mirrors implementation of Mockito (`mirrors.dart`).
* Fix compatibility with new [noSuchMethod Forwarding] feature of Dart 2. This
  is thankfully a mostly backwards-compatible change. This means that this
  version of Mockito should continue to work:

  * with Dart `>=2.0.0-dev.16.0`,
  * with Dart 2 runtime semantics (i.e. with `dart --preview-dart-2`, or with
    Flutter Beta 3), and
  * with the new noSuchMethod Forwarding feature, when it lands in CFE, and when
    it lands in DDC.

  This change, when combined with noSuchMethod Forwarding, will break a few
  code paths which do not seem to be frequently used. Two examples:

  ```dart
  class A {
    int fn(int a, [int b]) => 7;
  }
  class MockA extends Mock implements A {}

  var a = new MockA();
  when(a.fn(typed(any), typed(any))).thenReturn(0);
  print(a.fn(1));
  ```

  This used to print `null`, because only one argument was passed, which did
  not match the two-argument stub. Now it will print `0`, as the real call
  contains a value for both the required argument, and the optional argument.

  ```dart
  a.fn(1);
  a.fn(2, 3);
  print(verify(a.fn(typed(captureAny), typed(captureAny))).captured);
  ```

  This used to print `[2, 3]`, because only the second call matched the `verify`
  call. Now, it will print `[1, null, 2, 3]`, as both real calls contain a value
  for both the required argument, and the optional argument.
* Upgrade package dependencies.
* Throw an exception when attempting to stub a method on a Mock object that
  already exists.

[upgrading-to-mockito-3]: https://github.com/dart-lang/mockito/blob/master/upgrading-to-mockito-3.md
[noSuchMethod Forwarding]: https://github.com/dart-lang/sdk/blob/master/docs/language/informal/nosuchmethod-forwarding.md

## 2.2.0

* Add new feature to wait for an interaction: `untilCalled`. See the README for
  documentation.
* `capture*` calls outside of a `verify*` call no longer capture arguments.
* Some collections require stricter argument matching. For example, a stub like:
  `mock.methodWithListArgs([1,2,3].map((e) => e*2))` (note the _`Iterable`_
  argument) will no longer match the following stub:
  `when(mock.methodWithListArgs([42])).thenReturn(7);`.

## 2.1.0

* Add documentation for `when`, `verify`, `verifyNever`, `resetMockitoState`.
* Expose `throwOnMissingStub`, `resetMockitoState`.
* Improve failure message for `verify`.
* SDK version ceiling bumped to `<2.0.0-dev.infinity` to support Dart 2.0
  development testing.
* Add a Mockito + test package example at `test/example/iss`.

## 2.0.2

* Start using the new `InvocationMatcher` instead of the old matcher.
* Change `throwOnMissingStub` back to invoking `Object.noSuchMethod`:
  * It was never documented what the thrown type should be expected as.
  * You can now just rely on `throwsNoSuchMethodError` if you want to catch it.

## 2.0.1

* Add a new `throwOnMissingStub` method to the API.

## 2.0.0

* Removed `mockito_no_mirrors.dart`

## 2.0.0-dev

* Remove export of `spy` and any `dart:mirrors` based API from
  `mockito.dart`. Users may import as `package:mockito/mirrors.dart`
  going forward.
* Deprecated `mockito_no_mirrors.dart`; replace with `mockito.dart`.
* Require Dart SDK `>=1.21.0 <2.0.0` to use generic methods.

## 1.0.1

* Add a new `thenThrow` method to the API.
* Document `thenAnswer` in the README.
* Add more dartdoc.

## 1.0.0

* Add a new `typed` API that is compatible with Dart Dev Compiler; documented in
  README.md.

## 0.11.1

* Move the reflection-based `spy` code into a private source file. Now
  `package:mockito/mockito.dart` includes this reflection-based API, and a new
  `package:mockito/mockito_no_mirrors.dart` doesn't require mirrors.

## 0.11.0

* Equality matcher used by default to simplify matching collections as arguments. Should be non-breaking change in most cases, otherwise consider using `argThat(identical(arg))`.

## 0.10.0

* Added support for spy.

## 0.9.0

* Migrate from the unittest package to use the new test package.
* Format code using dartformat
