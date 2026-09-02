# Contracts TODO

## Contract Integrity over Test Doubles
Contracts define the true specification of the system. Do not weaken or remove contracts to accommodate degenerate test doubles or placeholder mocks.
When applying contracts across the codebase, first verify that the contract expresses the true invariant. If it does, update any test fixtures that pass invalid placeholder values to provide valid data conforming to the contract specification. For example, in `test/build_plan/previous_build_test.dart`, `BuilderDefinition('')` should be updated to specify a valid non-empty builder key such as `'a:test_builder'` so `InBuildPhase` can retain its full invariant (`package.isNotEmpty`, `key.isNotEmpty`, `displayName.isNotEmpty`).

## Beyond Nullability
Many initial experimental contracts checked nullability. Dart features a sound null-safe type system, making redundant null checks unnecessary. Contracts should focus on domain constraints that cannot be expressed in Dart types alone, including:
- String and collection emptiness constraints (e.g. `path.isNotEmpty`, `key.isNotEmpty`)
- Numeric ranges and bounds
- Relational and cross-field correlations (e.g. status and failureType correspondence)
- State transition and behavioral invariants

## Transform Productization Topics for Discussion
- **Invariant boundaries and cooperating classes**: How to handle multi-step updates across coupled classes in the same library without false-positive invariant failures during intermediate states, such as library boundaries versus an invariant suspension scope.
- **Static methods and cross-instance mutation**: Whether to validate instances returned from static helpers or secondary instances mutated through library-private access.
- **Mutable public fields**: Public fields bypass method wrapping; whether to auto-synthesize validating setters or enforce `final` fields via a lint.
- **Inherited methods**: How to ensure subclass invariants run on inherited methods that are not overridden, such as virtual `checkInvariants()` dispatch or trampoline overrides.
- **Generators (`sync*`, `async*`)**: How contracts should behave for streams and iterables, such as validating per `yield` versus on completion.
- **Exceptional postconditions**: Look at Cofoja's `ThrowEnsures` for specifying constraints that must hold when a method exits by throwing an exception.
