## 5.0.0-nullsafety.0

* Migrate the core libraries and tests to null safety. The builder at
  `lib/src/builder.dart` opts out of null safety.
* Add `http` back to `dev_dependencies`. It's used by the example.

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
