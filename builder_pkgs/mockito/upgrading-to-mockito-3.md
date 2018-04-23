# Migrating to Mockito 3

Mockito 3 aims to provide a consistent, type-safe API that adheres to the new
type rules of Dart 2 (both in terms of type inference, and runtime rules).

In order to provide this API, Mockito's implementation had to be completely
changed. In the old days of Dart 1 (and before the Dart Dev Compiler), we could
pass any old object anywhere, and no one would complain. For example:

```dart
when(cat.eatFood(argThat(contains('mouse')), hungry: any))...
```

In this code, Mockito is not passing a String as the first argument to
`eatFood()`, nor a bool as `hungry:`, which is what the method expects.
Instead, Mockito passes an ArgumentMatcher, a completely different object from
a String or bool! This is no longer allowed in Dart 2.  As an interim solution,
Mockito 1.0.0 sports an awkward `typed` function, which wraps other Mockito
functions, in order to simulate using the Dart 2-safe implementation:

```dart
when(cat.eatFood(
    typed(argThat(contains('mouse'))), hungry: typed(any, named: 'hungry')))...
```

This code is safe to use with DDC and Dart 2, as it actually passes `null` for
both the positional and the named argument of `eatFood()`, which is legal.
However kludgy this API may seem, it actually laid the foundation for the
Mockito 3 implementation, which simplifies the upgrade path.

In Mockito 3, we've ripped out the old implementation, and upgraded all the
normal API calls (`any`, `argThat`, etc.) to use the new Dart 2-safe
implementation, and done away with the `typed` wrapper, allowing users to go
almost right back to the first API (just some modifications for named
arguments):

```dart
when(cat.eatFood(argThat(contains('mouse')), hungry: anyNamed('hungry')))...
```

## Mockito 3.0.0-alpha+4 - a backward-and-forward-compatible API

If you have a large codebase, it may be difficult to upgrade _all_ of your tests
to the Mockito 3 API all at once. To provide an incremental upgrade path, upgrade to
Mockito 3.0.0-alpha+4.

Mockito 3.0.0-alpha+4 is a very tiny release on top of Mockito 3.0.0-alpha+3,
which provides the Mockito 2.x API. In fact, here's the diff:

```dart
-argThat(Matcher matcher) => new ArgMatcher(matcher, false);
+argThat(Matcher matcher, {String named}) => new ArgMatcher(matcher, false);

-captureThat(Matcher matcher) => new ArgMatcher(matcher, true);
+captureThat(Matcher matcher, {String named}) => new ArgMatcher(matcher, true);

+anyNamed(String named) => typed(any, named: named);

+captureAnyNamed(String named) => typed(captureAny, named: named);
```

## Table

Here's a cheatsheet with examples of migrating different Mockito 2 API calls to
Mockito 3.0.0-alpha+4 API calls, and Mockito 3 API calls:

| Version       |                                                                     |
| ------------- | ------------------------------------------------------------------- |
|               | **Using argument matchers as positional arguments**                 |
| 2.x           | `when(obj.fn(typed(any)))...`                                       |
| 3.0.0-alpha+4 | `when(obj.fn(typed(any)))`                                          |
| 3.0           | `when(obj.fn(any))...`                                              |
|               |                                                                     |
| 2.x           | `when(obj.fn(typed(argThat(equals(7)))))...`                        |
| 3.0.0-alpha+4 | `when(obj.fn(typed(argThat(equals(7)))))...`                        |
| 3.0           | `when(obj.fn(argThat(equals(7))))...`                               |
|               |                                                                     |
|               | **Using argument matchers as named arguments**                      |
| 2.x           | `when(obj.fn(foo: typed(any, named: 'foo')))...`                    |
| 3.0.0-alpha+4 | `when(obj.fn(foo: anyNamed('foo')))...`                             |
| 3.0           | `when(obj.fn(foo: anyNamed('foo')))...`                             |
|               |                                                                     |
| 2.x           | `when(obj.fn(foo: typed(argThat(equals(7)), named: 'foo')))...`     |
| 3.0.0-alpha+4 | `when(obj.fn(foo: typedArgThat(equals(7), named: 'foo')))...`       |
| 3.0           | `when(obj.fn(foo: argThat(equals(7), named: 'foo')))...`            |
|               |                                                                     |
| 2.x           | `when(obj.fn(foo: typed(null, named: 'foo')))...`                   |
| 3.0.0-alpha+4 | `when(obj.fn(foo: typedArgThat(isNull, named: 'foo')))...`          |
| 3.0           | `when(obj.fn(foo: argThat(isNull, named: 'foo')))...`               |
|               |                                                                     |
| 2.x           | `when(obj.fn(foo: typed(captureAny, named: 'foo')))...`             |
| 3.0.0-alpha+4 | `when(obj.fn(foo: captureAnyNamed('foo')))...`                      |
| 3.0           | `when(obj.fn(foo: captureAnyNamed('foo')))...`                      |
|               |                                                                     |
| 2.x           | `when(obj.fn(foo: typed(captureThat(equals(7)), named: 'foo')))...` |
| 3.0.0-alpha+4 | `when(obj.fn(foo: typedCaptureThat(equals(7), named: 'foo')))...`   |
| 3.0           | `when(obj.fn(foo: captureThat(equals(7), named: 'foo')))...`        |

## Upgrade process from 2.x to 3.

Because Mockito 3.0.0-alpha+4, the forward-and-backward-compatible release,
uses the Mockito 2.x implementation, it is not really compatible with Dart 2
runtime semantics. If you write:

```dart
when(cat.eatFood(argThat(contains('mouse')), hungry: any))...
```

then Mockito is still passing an ArgumentMatcher as each argument to
`eatFood()`, which only accepts a String and a bool argument.
However, this version lets you incrementally upgrade your tests to the
Mockito 3 API.  Here's the workflow:

1. **Upgrade to `mockito: '^3.0.0-alpha+4'` in your project's dependencies**, in
   `pubspec.yaml`. This should not cause any tests to break. Commit this change.

2. **Change your usage of Mockito from the old API to the new API**, in as many
   chunks as you like.

   In practice, this means searching for the different code patterns in the
   table, and replacing the old API calls with the new. You can typically just
   use your IDE's search, or `git grep`, and search for the following text:

   * `when(`
   * `verify(`
   * `verifyNever(`
   * `typed(`
   * `named:`

   The table above should be sufficient to see how to ugprade Mockito calls,
   but here's some more explanation:

   * Any use of `any`, `argThat`, `captureAny`, or `captureThat` that is passed
     in as a named argument needs to be appended with the argument name as a
     String:

     * `foo: any` &rarr; `foo: anyNamed('foo')`
     * `foo: argThat(...)` &rarr; `foo: argThat(..., named: 'foo')`
     * `foo: captureAny` &rarr; `foo: captureAnyNamed('foo')`
     * `foo: captureThat(...)` &rarr; `foo: captureThat(..., named: 'foo')`

   * Any bare `null` argument needs to rewritten as `argThat(isNull)`.

   * Any `typed` wrapper can be removed, sliding any `named` arguments to inner API call:

     * `typed(any)` &rarr; `any`
     * `foo: typed(any, named: 'foo')` &rarr; `foo: anyNamed('foo')`

   Make sure your tests still pass as you go.

   You can also temporarily bump your dependency on Mockito to `'^3.0.0'` and
   run your tests to see if you are making progress, and if the tests you are
   fixing actually _do continue to pass_ when using Mockito 3. (Of course:
   don't commit that bump to Mockito 3 until all tests pass.)

3. **Finally, upgrade to `mockito: '^3.0.0'`.** Make sure your tests all pass,
   and commit!

   In Mockito 3, `typed` still exists, but is deprecated, and a no-op, so
   remove at your leisure. Additionally, `typedArgThat` and `typedCaptureThat`
   still exist, but only redirect to `argThat` and `captureThat`, respectively.
