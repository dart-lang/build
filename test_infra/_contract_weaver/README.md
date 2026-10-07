# _contract_weaver

Weaves contract programming checks into a copy of Dart source.

The shape closely follows [Cofoja](https://github.com/nhatminhle/cofoja),
Contracts for Java, also from Google. No major new ideas are introduced.

## What it does

Contracts are written as expression strings in annotations:

```dart
@Invariant('balance >= 0')
class Account {
  @Requires('amount > 0')
  @Ensures('balance >= amount')
  @ThrowEnsures(StateError, 'balance == 0')
  void deposit(int amount) { ... }
}
```

A clause is a Dart expression. It sees everything the annotated member sees,
plus `result` in `@Ensures` and `signal`, the thrown exception, in
`@ThrowEnsures`.

Each annotation holds exactly one clause; repeat the annotation for more. Passing
more than one clause to an annotation is an error. Clauses on one member are
checked in order, and all must hold.

`@ThrowEnsures` names one exception type and one clause. Repeat it with the same
type for more clauses on that type, or with other types for other exceptions.
Normal postconditions are **not** checked when a method throws, because there is
no result to talk about.

`@Invariant` clauses are checked, as in Cofoja, on entry to and exit from public
instance methods and setters, and on exit from generative constructors, but only
for the outermost such call on the object. Inside a call the object may be
between states, so public methods it calls on itself, directly or through other
objects, do not check; that includes superclass methods with invariants of their
own. A method's exit check runs however it exits, including by throwing; a
constructor that throws has no object to check. Getters, `==`, `hashCode`,
`toString`, private and static members, and generators are not checked.

A class that implements `Built`, or is annotated `@immutable` from
`package:meta`, is taken to be immutable as it declares, so its invariant is
checked only on construction. That is not sound: both kinds of immutability
are shallow, so an invariant over a field of mutable type can break unreported.

For a normal build and for published code, the annotations are inert. Like all
Dart annotations, they add no runtime cost. For a contracts run, the tool weaves
the clauses into a throwaway copy of the package and runs the tests against that.

## Deliberate non-goals

The tool stays out of the way of the code it checks. In particular it does not:

- generate anything into your repository,
- add `part` directives to your sources,
- need your code to import this package; it is only a dev dependency.

## Usage

### Add the dev dependency

The weaver is not published; depend on it from git:

```yaml
dev_dependencies:
  _contract_weaver:
    git:
      url: https://github.com/dart-lang/build.git
      path: test_infra/_contract_weaver
```

Add `ref:` with a commit to pin a version.

### Declare the annotations

Annotations are matched **by name**, so your package declares its own. Copy
these into a library of their own, for example `lib/src/contracts.dart`:

```dart
class Requires {
  final String clause;
  const Requires(this.clause);
}

class Ensures {
  final String clause;
  const Ensures(this.clause);
}

class ThrowEnsures {
  final Type type;
  final String clause;
  const ThrowEnsures(this.type, this.clause);
}

class Invariant {
  final String clause;
  const Invariant(this.clause);
}

class ContractImport {
  final String uri;
  const ContractImport(this.uri);
}
```

That library should import nothing. The weaver injects the runtime support
classes `Contracts` and `ContractViolation` into it, and every contracted library
imports it, so a single `dart:io` would shut out web and Flutter packages. There
is no switch to turn contracts on, which is what makes that possible: the woven
copy exists only to be checked, so it always checks.

Any annotation with a matching name is woven. That is a deliberate trade: no
coupling, at the cost of no type identity.

A clause may use a library that its own library does not import, typically for
an extension member; importing it there would be reported as unused, because
clauses are strings. Put `@ContractImport('package:p/src/x.dart')` on the
library directive or on any top level declaration, and the woven copy of the
library imports it. Cofoja has the same annotation.

### Run

```
dart run _contract_weaver [options] [-- test args]
```

Run it in your package. It weaves contracts into a copy of the package, runs
`dart test` on the copy with any test args you pass after `--`, and leaves your
files untouched.

In a pub workspace, run it in a member package, or at the workspace root with
`--package=DIR`.

Options:

| Option | Meaning |
|---|---|
| `--package=DIR` | In a pub workspace, the member directory to weave, relative to the workspace root. Defaults to the member containing the current directory. |
| `--stage-dir=PATH` | Where to build the woven copy. Defaults to a directory under the system temp directory. |
| `--clean` | Delete the stage directory first. |
| `--analyze-only` | Analyze the woven copy and skip the tests. |

## The CI gate

Clause text is invisible to the analyzer, so a rebase that renames a parameter
breaks clauses silently. `dart run _contract_weaver --analyze-only` weaves the
clauses and analyzes the result, which turns a rotten clause into an undefined
name. It does not run the tests, so it is cheap enough to run on every change.
In this repository, `tool/contract_check.sh` does that for `build_runner`.

Errors are reported; warnings and lints are not, because they describe generated
code that nobody reads.

## Known limitations

- Clauses are strings, so the analyzer does not see them until they are woven
  in. A clause naming a renamed parameter fails only during a contracts run.
  See the CI gate above.
- No `old()`, so postconditions can state shape but not transition.
- No `@ThrowEnsures` on constructors. Using it there is an error, not a silent
  omission.
- `@Ensures` cannot be used on a value-returning function with a parameter
  named `result`, and `@ThrowEnsures` cannot be used on a function with a
  parameter named `signal`. Both throw an error rather than shadowing the
  parameter. An instance member of the same name can still be referenced as
  `this.result` or `this.signal`.
- No contract inheritance. Cofoja weakens inherited preconditions and
  strengthens inherited postconditions and invariants; this does neither.
- An `async` method is a call on its object until its future completes. Other
  calls on the object in the meantime skip their invariant checks, and a future
  that never completes turns them off for good. A method that returns a
  `Future` without being `async` is a call only until it returns.
- A superclass constructor finishes, and checks its invariant, before the
  subclass constructor body runs.
- The woven copy lives outside your package, so relative `path:` dependencies
  in a standalone package do not resolve there. Hosted and git dependencies
  work, as do path dependencies between members of a pub workspace.
