# Discovered Defects and Contract Findings

This document tracks real bugs, latent type mismatches, and structural state inconsistencies uncovered in `build_runner` through the introduction of executable Design by Contract annotations (`@Pre`, `@Post`, `@Invariant`).

---

## 1. [Invalidated / Tooling Defect] Downward Type Inference Lost in Contract Transformer IIFE

- **Location**: [`build_runner/lib/src/contracts/transform.dart`](file:///usr/local/google/home/davidmorgan/jj/build-contracts/build_runner/lib/src/contracts/transform.dart)
- **Component**: Contract Transformation Tooling
- **Status**: Resolved in transformer; not a defect in `build_runner` source code.

### Description
The method [`BuildFileIndex.findFiles`](file:///usr/local/google/home/davidmorgan/jj/build-contracts/build_runner/lib/src/build/build_file_index.dart#L28) declared a return type of `Iterable<AssetId>` and returned `return const [];`. In standard Dart code, downward type inference types `const []` as `List<AssetId>`.

However, the contract transformer wrapped method return expressions inside an untyped immediately-invoked function expression:
```dart
return ((result) { ... })($exprSource);
```
Because the closure parameter `result` was untyped, `$exprSource` was evaluated in a `dynamic` context rather than inheriting the method's declared return type, causing `const []` to evaluate to `List<dynamic>`. Subsequent `@Post` assertions then failed with:
```
type 'List<dynamic>' is not a subtype of type 'Iterable<AssetId>'
```

### Resolution
The contract transformer was fixed to preserve the enclosing method's declared return type on the generated closure parameter (`(($typePrefix result) { ... })($exprSource)`). Reverted `return const [];` in `build_file_index.dart`. Production code was unaffected.

---

## 2. Inconsistent `cleanBuild` Flag in `BuildPlan.withCompatiblePreviousBuild`

- **Location**: [`build_runner/lib/src/build_plan/build_plan.dart:138`](file:///usr/local/google/home/davidmorgan/jj/build-contracts/build_runner/lib/src/build_plan/build_plan.dart#L138)
- **Component**: `BuildPlan` and `BuildInputs`
- **Discovered Via**: `@Invariant('!cleanBuild || retainedOutputContents.isEmpty')` on `BuildInputs` during `test/build_plan/build_triggers_test.dart`.

### Description
`BuildPlan.withCompatiblePreviousBuild` is responsible for producing the updated build plan for subsequent incremental builds after a build completes. It copied retained output contents from the completed build into `buildInputs.retainedOutputContents`:
```dart
..buildInputs.retainedOutputContents.clear()
..buildInputs.retainedOutputContents.addEntries(previousBuildState.outputContents)
```
However, it omitted setting `cleanBuild = false` on `buildInputs`. When the initial build was clean, `cleanBuild` remained `true` on the resulting incremental `BuildPlan`.

This violated the documented class contract of `BuildInputs`:
> *"Output contents from the previous build that are retained for reuse... Empty if [cleanBuild]."*

### Potential Impact in Execution
If a build had run directly against the plan returned by `withCompatiblePreviousBuild`:
1. **Cache Purge**: `BuildSeries._writeBuildOutput` checks `if (_buildPlan.buildInputs.cleanBuild)`. If `true`, it invokes `deleteDirectory` on `.dart_tool/build/generated`, wiping out the newly generated and retained outputs on disk.
2. **De-optimization**: `Build._computeStepAction` returns `StepAction.run` unconditionally if `buildInputs.cleanBuild` is `true`, bypassing all incremental change detection.
3. **Analysis Cache Invalidation**: `AnalysisDriverFilesystem.startBuild` clears its internal AST and element caches if `buildInputs.cleanBuild` is `true`.

In standard `BuildSeries.run` execution, this bug was masked because the watcher loop called `updateForFileChanges`, which replaced `buildInputs` with a fresh instance where `cleanBuild` was set to `false`. Between builds, however, the plan sitting in memory was in an inconsistent state.

### Resolution
Added explicit assignment in `withCompatiblePreviousBuild`:
```dart
..buildInputs.cleanBuild = false
```

---

## 3. Inconsistent Test Fixtures Masking Invariant Violations

- **Locations**:
  - [`build_runner/test/build/resolver/analysis_driver_filesystem_test.dart`](file:///usr/local/google/home/davidmorgan/jj/build-contracts/build_runner/test/build/resolver/analysis_driver_filesystem_test.dart)
  - [`build_runner/test/commands/serve/asset_handler_test.dart`](file:///usr/local/google/home/davidmorgan/jj/build-contracts/build_runner/test/commands/serve/asset_handler_test.dart)
  - [`build_runner/test/commands/serve/serve_handler_test.dart`](file:///usr/local/google/home/davidmorgan/jj/build-contracts/build_runner/test/commands/serve/serve_handler_test.dart)
  - [`build_runner/test/build/build_test.dart`](file:///usr/local/google/home/davidmorgan/jj/build-contracts/build_runner/test/build/build_test.dart)
  - [`build_runner/test/build_plan/build_packages_test.dart`](file:///usr/local/google/home/davidmorgan/jj/build-contracts/build_runner/test/build_plan/build_packages_test.dart)
- **Component**: Test doubles for `BuildStepPlan`, `InBuildPhase`, `BuildPackages`, and `BuildInputs`.
- **Discovered Via**: Structural invariants on `BuildStepPlan`, `BuildPackages`, and `BuildInputs`.

### Description
Unit tests across several subsystems manually constructed mock configurations using builders with incomplete or contradictory data:
1. **Dangling Phase References**: `BuildStepPlan` instances were created with declared outputs and steps in phase 0 or 1, while providing an empty `BuildPhases([])` containing zero phases.
2. **Missing Source Registrations**: An incremental build test in `analysis_driver_filesystem_test.dart` registered an updated source under `updatedSources` without adding it to `sources`.
3. **Empty Builder Keys**: Numerous tests registered `BuilderDefinition('')` and `BuilderFactories({'': ...})`, violating the domain requirement that builder keys must identify a valid builder action.

### Significance
Unchecked test doubles decouple tests from real runtime invariants, allowing regressions to pass unnoticed. Hardening contracts forced all mock fixtures to conform to actual system constraints.

---

## 4. Stale/Failed Build Outputs Served by `BuildOutputReader.readAsBytes`

- **Location**: [`build_runner/lib/src/io/build_output_reader.dart:136`](file:///usr/local/google/home/davidmorgan/jj/build-contracts/build_runner/lib/src/io/build_output_reader.dart#L136)
- **Component**: `BuildOutputReader`
- **Discovered Via**: Precondition and visibility analysis on `BuildOutputReader` methods.

### Description
The documented contract of `BuildOutputReader` guarantees:
> *"Files are only visible if they were a required part of the build, even if they exist on disk from a previous build."*

In `readAsBytes`, the method checked:
```dart
final cached = buildState.contentOf(id);
if (cached != null) {
  _recordSourceConsumedOutsideBuild(id);
  return cached.bytes;
}

if (!_isFile(id)) {
  throw AssetNotFoundException(id);
}

final bytes = await readerWriter.readAsBytes(
  id,
  hidden: buildState.isHidden(id),
);
```

When an output step failed, was skipped due to build filters, or was never generated, `cached` was null. However, `_isFile(id)` calls `buildState.isFile(id)`, which returns `true` for all declared outputs in the build step plan.

Consequently, `readAsBytes` proceeded to read from `readerWriter.readAsBytes(id)`. If a stale file existed on disk from an earlier build, `readAsBytes` and `readAsString` succeeded and emitted the stale file contents rather than throwing `AssetNotFoundException`.

### Impact in Practice
In dev workflows (`build serve`, merged directory generation, or tool integrations), if a builder failed or an output was omitted, consumers calling `readAsBytes` or `readAsString` could silently receive obsolete build artifacts from disk without error. While `canRead` and `digest` checked `unreadableReason`, `readAsBytes` bypassed that check.

### Resolution
Updated `BuildOutputReader.readAsBytes` to check `unreadableReason(id)` first, throwing `AssetNotFoundException(id)` if the file is unreadable (failed, not output, deleted, or not found):
```dart
final unreadable = await unreadableReason(id);
if (unreadable != null) {
  throw AssetNotFoundException(id);
}
```
Added unit test `readAsString throws AssetNotFoundException for failed output with stale file on disk` in `test/io/build_output_reader_test.dart` to verify this behavior.

---

## 5. Retained Outputs of Deleted Sources and Unreset Change Tracking Sets

- **Location**: [`build_runner/lib/src/build_plan/build_plan.dart:154, 388`](file:///usr/local/google/home/davidmorgan/jj/build-contracts/build_runner/lib/src/build_plan/build_plan.dart#L154)
- **Component**: `BuildPlan` and `BuildInputs`
- **Discovered Via**: `@Invariant('invalidOutputs.every((id) => !retainedOutputContents.containsKey(id))')` on `BuildInputs`.

### Description
Two related defects in incremental build state tracking were uncovered by enforcing mutual exclusion between `invalidOutputs` and `retainedOutputContents`:

1. **Unpurged Retained Outputs of Deleted Inputs**:
   In `BuildPlan._createIncremental`, when an input was deleted, the build plan computed the transitive declared outputs of deleted sources and marked them as `invalidOutputs`:
   ```dart
   final invalidOutputs = previousBuildStepPlan
       .transitiveDeclaredOutputsOf(buildInputs.deletedSources.build())
       .toSet();
   buildInputs.invalidOutputs.addAll(invalidOutputs);
   ```
   However, it never removed those outputs from `buildInputs.retainedOutputContents`. If an output was not itself in `filesToCheck`, its bytes and digest remained cached in `retainedOutputContents` even though its generating primary input had been deleted and the output was classified as invalid.

2. **Unreset Change Tracking Sets Between Builds**:
   In `BuildPlan.withCompatiblePreviousBuild`, which prepares the in-memory plan for the next build after a build completes:
   ```dart
   ..buildInputs.cleanBuild = false
   ..buildInputs.sourceContents.clear()
   ..buildInputs.sourceContents.addEntries(previousBuildState.sourceContents)
   ..buildInputs.retainedOutputContents.clear()
   ..buildInputs.retainedOutputContents.addEntries(
     previousBuildState.outputContents,
   )
   ..conflictingOutputs.clear()
   ```
   It cleared `conflictingOutputs`, but omitted clearing `deletedSources`, `updatedSources`, and `invalidOutputs`. Consequently, the incremental plan between builds retained obsolete deletion and modification records from the previous build run, causing invariant collisions when fresh outputs were added to `retainedOutputContents`.

3. **Retained Outputs of Assets Displaced by Sources**:
   When a user creates a source file at the path of a previously-generated output, `_createIncremental` added the asset to `buildInputs.sources` without evicting it from `buildInputs.retainedOutputContents`. Enforcing `'retainedOutputContents.keys.every((id) => !sources.contains(id))'` surfaced that `finalSources` must be purged from `retainedOutputContents`.

### Impact in Practice
In multi-build watcher runs, leftover invalid outputs in `retainedOutputContents` could allow builders or downstream consumers relying on `buildInputs.retainedOutputContents` to access content from deleted sources or old generated outputs that have been replaced by real source files. Furthermore, stale `deletedSources` and `updatedSources` lingering across builds led to corrupted incremental plan states.

### Resolution
1. Added explicit eviction of `invalidOutputs` from `retainedOutputContents` in `BuildPlan._createIncremental`:
   ```dart
   for (final invalid in invalidOutputs) {
     buildInputs.retainedOutputContents.remove(invalid);
   }
   ```
2. Added eviction of `finalSources` from `retainedOutputContents` in `BuildPlan._createIncremental`:
   ```dart
   for (final id in finalSources) {
     buildInputs.retainedOutputContents.remove(id);
   }
   ```
3. Added reset calls in `BuildPlan.withCompatiblePreviousBuild`:
   ```dart
   ..buildInputs.deletedSources.clear()
   ..buildInputs.updatedSources.clear()
   ..buildInputs.invalidOutputs.clear()
   ```
4. Added class invariant on `BuildInputs`:
   ```dart
   @Invariant(
     'invalidOutputs.every((id) => !retainedOutputContents.containsKey(id))',
   )
   ```

---

## 6. Conflicting Artifact Tree Files Invalidate Retained Package Path Outputs Causing Unnecessary Step Reruns

- **Location**: [`build_runner/lib/src/build_plan/build_plan.dart:465`](file:///usr/local/google/home/davidmorgan/jj/build-contracts/build_runner/lib/src/build_plan/build_plan.dart#L465)
- **Component**: `BuildPlan` and `BuildInputs`
- **Discovered Via**: `@Invariant('invalidOutputs.every((id) => !retainedOutputContents.containsKey(id))')` on `BuildInputs`.

### Description
In `BuildPlan._createIncremental`, when conflicting artifact tree files appear, they are recorded in `newArtifactTreeFiles` and added to `buildInputs.invalidOutputs`:

```dart
for (final id in newArtifactTreeFiles) {
  if (!finalSources.contains(id)) {
    buildInputs.invalidOutputs.add(id);
  }
}
```

When an output was already generated at its package path in the previous build and remains unchanged on disk, `_createIncremental` retained its content in `buildInputs.retainedOutputContents`. If a conflicting stray file appeared in the artifact tree, `id` was added to `invalidOutputs` while remaining in `retainedOutputContents`.

This violated the class invariant:
```dart
invalidOutputs.every((id) => !retainedOutputContents.containsKey(id))
```

### Impact in Practice
Marking the asset as an invalid output caused `_computeStepAction` to force `StepAction.run` instead of `StepAction.skipReuse`. Even though the stray artifact tree file was deleted before build phases ran and the package path output was already valid, the builder was unnecessarily rerun to regenerate the package path output.

### Resolution
Only mark `newArtifactTreeFiles` as `invalidOutputs` if the output is not already a valid retained output:

```dart
for (final id in newArtifactTreeFiles) {
  if (!finalSources.contains(id) &&
      buildInputs.retainedOutputContents[id] == null) {
    buildInputs.invalidOutputs.add(id);
  }
}
```

This satisfies the mutual exclusion invariant and avoids the unnecessary build step rerun.




