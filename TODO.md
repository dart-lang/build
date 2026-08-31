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
