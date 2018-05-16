## 3.0.0-beta

* This release is the first 3.0.0 release featuring the new Mockito 3 API. The
  README has been updated, and an [upgrading-to-mockito-3] doc has been added
  to help users upgrade. Here's a quick rundown:

  ```dart
  // Old API:
  when(obj.fn(typed(any)))...
  // New API:
  when(obj.fn(any))...

  // Old API:
  when(obj.fn(foo: typed(any, named: 'foo')))...
  // New API:
  when(obj.fn(foo: anyNamed('foo')))...

  // Old API:
  when(obj.fn(foo: typed(null, named: 'foo')))...
  // New API:
  when(obj.fn(foo: argThat(isNull, named: 'foo')))...
  ```

## 3.0.0-alpha+5

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

[noSuchMethod Forwarding]: https://github.com/dart-lang/sdk/blob/master/docs/language/informal/nosuchmethod-forwarding.md

## 3.0.0-alpha+4

* Introduce a backward-and-forward compatible API to help users migrate to
  Mockito 3. See more details in the [upgrading-to-mockito-3] doc.

[upgrading-to-mockito-3]: https://github.com/dart-lang/mockito/blob/master/upgrading-to-mockito-3.md

## 3.0.0-alpha+3

* `thenReturn` and `thenAnswer` now support generics and infer the correct
  types from the `when` call.
* Completely remove the mirrors implementation of Mockito (`mirrors.dart`).

## 3.0.0-alpha+2

* Support stubbing of void methods in Dart 2.

## 3.0.0-alpha

* `thenReturn` now throws an `ArgumentError` if either a `Future` or `Stream`
  is provided. `thenReturn` calls with futures and streams should be changed to
  `thenAnswer`. See the README for more information.

## 2.2.0

* Add new feature to wait for an interaction: `untilCalled`. See the README for
  documentation.

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
