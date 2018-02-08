## 3.0.0

* `thenReturn` now throws an `ArgumentError` if either a `Future` or `Stream`
  is provided. `thenReturn` calls with futures and streams should be changed to
  `thenAnswer`. See the README for more information.
* Completely remove the mirrors implementation of Mockito (`mirrors.dart`).

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
