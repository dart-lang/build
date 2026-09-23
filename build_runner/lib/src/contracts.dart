// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Annotations for Design by Contract.
///
/// These annotations support an unpublished external contract weaver. Because
/// the weaver and annotations are not published as a package, this file is
/// copied into each codebase that uses them.
///
/// Clauses are Dart expressions written as strings. They run only in a
/// contracts build, where the weaver rewrites them into executable checks in a
/// staged copy of the package. In normal builds they are inert `const`
/// annotations, so a rename that invalidates a clause is not a compile error
/// until the weaver runs.
library;

/// Conditions that must hold when a method is called.
///
/// A clause may use anything in scope where the method starts, including its
/// parameters and `this`. Every clause must hold, so the list reads as "and".
class Requires {
  final String c1;
  final String? c2;
  final String? c3;
  final String? c4;
  final String? c5;
  final String? c6;
  final String? c7;
  final String? c8;
  final String? c9;
  final String? c10;

  const Requires(
    this.c1, [
    this.c2,
    this.c3,
    this.c4,
    this.c5,
    this.c6,
    this.c7,
    this.c8,
    this.c9,
    this.c10,
  ]);
}

/// Conditions that must hold when a method returns.
///
/// Clauses are written as for [Requires], with `result` additionally in scope
/// for the returned value.
///
/// A method that throws checks nothing here, because there is no result to
/// describe.
class Ensures {
  final String c1;
  final String? c2;
  final String? c3;
  final String? c4;
  final String? c5;
  final String? c6;
  final String? c7;
  final String? c8;
  final String? c9;
  final String? c10;

  const Ensures(
    this.c1, [
    this.c2,
    this.c3,
    this.c4,
    this.c5,
    this.c6,
    this.c7,
    this.c8,
    this.c9,
    this.c10,
  ]);
}

/// Conditions that must hold when a method throws.
///
/// [type] is the exception class, written as a type literal so that the
/// analyzer checks it. Clauses are written as for [Requires], with `signal` in
/// scope for the thrown exception.
///
/// A method that throws something else, or that returns, checks nothing here.
/// Use one annotation per exception type.
class ThrowEnsures {
  final Type type;
  final String c1;
  final String? c2;
  final String? c3;
  final String? c4;
  final String? c5;
  final String? c6;
  final String? c7;
  final String? c8;
  final String? c9;

  const ThrowEnsures(
    this.type,
    this.c1, [
    this.c2,
    this.c3,
    this.c4,
    this.c5,
    this.c6,
    this.c7,
    this.c8,
    this.c9,
  ]);
}

/// Conditions that must hold whenever an instance is at rest.
///
/// Clauses are written as for [Requires]. They are checked on entry to and
/// exit from every public instance method, so they may be false while such a
/// method is running.
class Invariant {
  final String c1;
  final String? c2;
  final String? c3;
  final String? c4;
  final String? c5;
  final String? c6;
  final String? c7;
  final String? c8;
  final String? c9;
  final String? c10;

  const Invariant(
    this.c1, [
    this.c2,
    this.c3,
    this.c4,
    this.c5,
    this.c6,
    this.c7,
    this.c8,
    this.c9,
    this.c10,
  ]);
}
