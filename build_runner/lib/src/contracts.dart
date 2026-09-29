// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Annotations for contract programming.
///
/// These annotations support an unpublished external contract weaver. Because
/// the weaver and annotations are not published as a package, this file is
/// copied into each codebase that uses them.
///
/// Each annotation holds one clause, a Dart expression written as a string.
/// Repeat the annotation for more clauses; every clause must hold, and they
/// are checked in order.
///
/// Clauses run only in a contracts build, where the weaver rewrites them into
/// executable checks in a staged copy of the package. In normal builds they
/// are inert `const` annotations, so a rename that invalidates a clause is not
/// a compile error until the weaver runs.
library;

/// A condition that must hold when a method is called.
///
/// The clause may use anything in scope where the method starts, including
/// its parameters and `this`.
class Requires {
  final String clause;

  const Requires(this.clause);
}

/// A condition that must hold when a method returns.
///
/// The clause is written as for [Requires], with `result` additionally in
/// scope for the returned value when there is one. `result` shadows any
/// instance member of the same name, which can still be referenced as
/// `this.result`. A value-returning function with [Ensures] must not declare a
/// parameter named `result`; the weaver will throw.
///
/// A method that throws checks nothing here, because there is no result to
/// describe.
class Ensures {
  final String clause;

  const Ensures(this.clause);
}

/// A condition that must hold when a method throws [type].
///
/// [type] is the exception class, written as a type literal so that the
/// analyzer checks it. The clause is written as for [Requires], with `signal`
/// in scope for the thrown exception. `signal` shadows any instance member of
/// the same name, which can still be referenced as `this.signal`. The
/// annotated function must not declare a parameter named `signal`; the weaver
/// will throw.
///
/// A method that throws something else, or that returns, checks nothing here.
class ThrowEnsures {
  final Type type;
  final String clause;

  const ThrowEnsures(this.type, this.clause);
}

/// A condition that must hold whenever an instance is at rest.
///
/// The clause is written as for [Requires]. It is checked on entry to and exit
/// from every public instance method, so it may be false while such a method
/// is running.
class Invariant {
  final String clause;

  const Invariant(this.clause);
}
