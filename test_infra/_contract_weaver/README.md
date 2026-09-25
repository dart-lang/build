# _contract_weaver

Weaves contract programming checks into a copy of Dart source.

This is a Dart imitation of [Cofoja](https://github.com/nhatminhle/cofoja),
Contracts for Java, and follows its design closely enough that its documentation
is worth reading. Nothing here is original. Cofoja is LGPL-3.0; no Cofoja code or
text has been copied.

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
`@ThrowEnsures`. Clauses on one member are checked in order, and all must hold.

`@ThrowEnsures` names one exception type; repeat the annotation for more types.
Normal postconditions are **not** checked when a method throws, because there is
no result to talk about.

For a normal build and for published code, the annotations are inert: they are
`const` objects that nothing reads. For a contracts run, the tool weaves the
clauses into a throwaway copy of the package and runs the tests against that.

## Deliberate non-goals

The tool stays out of the way of the code it checks. In particular it does not:

- generate anything into your repository,
- add `part` directives to your sources,
- require a dependency on this package.

Annotations are matched **by name**, so a package under contract declares its
own `Requires`, `Ensures`, `ThrowEnsures` and `Invariant` classes and depends
on nothing. The weaver injects the runtime support classes `Contracts` and
`ContractViolation` into the library that declares those annotation classes, so
the source tree carries only `const` annotations. That also means the tool will
act on any annotation with a matching name, which is a deliberate trade: no
coupling, at the cost of no type identity.

Those declarations should import nothing at all. They end up in every contracted
library, so a single `dart:io` in them would shut out web and Flutter packages.
There is no switch to turn contracts on, which is what makes that possible: the
woven copy exists only to be checked, so it always checks.

## Usage

```
dart run _contract_weaver:run_with_contracts --package=my_package [test args]
```

Options:

| Option | Meaning |
|---|---|
| `--package=NAME` | Package in the workspace to weave contracts into. |
| `--stage-dir=PATH` | Where to build the woven copy. |
| `--clean` | Delete the stage directory first. |
| `--analyze-only` | Analyze the woven copy and skip the tests. |
| `--contract-import=M1,M2=URI` | Import `URI` into woven sources mentioning any marker. Repeatable. |

`--contract-import` exists because a clause may name something the library does
not import, typically an extension member. Cofoja solves this with
`@ContractImport` on the enclosing type; that is the intended replacement.

## The CI gate

Clause text is invisible to the analyzer, so a rebase that renames a parameter
breaks clauses silently. `tool/contract_check.sh` weaves the clauses and
analyzes the result, which turns a rotten clause into an undefined name. It runs
in the `analyze_and_format` stage and does not run the tests, so it costs a
staging pass and one analysis.

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
