## 2.0.1

- Fix an issue where the `finalizedReader` was not `reset` prior to build.

## 2.0.0

- The `build` method now requires a list of `buildDirs`.
- Remove `buildDirs` from `BuildOptions`.
- Added the `overrideGeneratedDirectory` method which overrides the directory
  for generated outputs.
  - Must be invoked before creating a `BuildRunner` instance.

## 1.1.3

- Update to `package:graphs` version `0.2.0`.
- Allow `build` version `1.1.x`.
- Update the way combined input hashes are computed to not rely on ordering.
  - Digest implementations must now include the AssetId, not just the contents.
- Require package:build version 1.1.0, which meets the new requirements for
  digests.

## 1.1.2

- Fix a `NoSuchMethodError` that the user could get when adding new
  dependencies.

## 1.1.1

- Fix a bug where adding new dependencies or removing dependencies could cause
  subsequent build errors, requiring a `pub run build_runner clean` to fix.

## 1.1.0

- Support running the build script as a snapshot.
- Added new exceptions, `BuildScriptChangedException` and
  `BuildConfigChangedException`. These should be handled by scripts as described
  in the documentation.
- Added new `FailureType`s of `buildScriptChanged` and `buildConfigChanged`.

## 1.0.2

- Support the latest `package:json_annotation`.

## 1.0.1

- Update `package:build` version constraint to `>1.0.0 <1.0.1`.

## 1.0.0

### Breaking Changes

- The performance tracking apis have changed significantly, and performance
  tracking now uses the `timing` package.
- The `BuildOptions` static factory now takes a `LogSubscription` instead of a
  `BuildEnvironment`. Logging should be start as early as possible to catch logs
  emitted during setup.

### New Features

- Use the `timing` package for performance tracking.
- Added support for `BuildStep.trackStage` to track performance of custom build
  stages within your builder.

### Bug Fixes

- Fixed a node invalidation issue when fixing build errors that could cause a
  situation which was only resolvable with a full rebuild.

## 0.3.1+5

- Fixed an issue where builders that didn't read their primary input would get
  invalidated on fresh builds when they shouldn't.

## 0.3.1+4

- Removed the constraint on reading files that output to cache from files that
  output to source.

## 0.3.1+3

- Bug Fix: Don't output a `packages` symlink within the `packages` directory.

## 0.3.1+2

- Restore `new` keyword for a working release on Dart 1 VM.
- Bug Fix: Don't include any non-lib assets from dependencies in the build, even
  if they are a source in a target.

## 0.3.1+1

- Bug Fix: Don't include any non-lib assets from dependencies in the build, even
  if they are a source in a target.
- Release broken on Dart 1 VM.

## 0.3.1

- Migrated glob tracking to a specialized node type to fix dart-lang/build#1702.

## 0.3.0

### Breaking Changes

- Implementations of `BuildEnvironment` must now implement the `finalizeBuild`
  method. There is a default implementation if you extend `BuildEnvironment`
  that is a no-op.
  - This method is invoked at the end of the build that allows you to do
    arbitrary additional work, such as creating merged output directories.
- The `assumeTty` argument on `IOEnvironment` has moved to a named argument
  since `null` is an accepted value.
- The `outputMap` field on `BuildOptions` has moved to the `IOEnvironment`
  class.

### New Features/Updates

- Added a `outputSymlinksOnly` option to `IOEnvironment` constructor, that
  causes the merged output directories to contain only symlinks, which is much
  faster than copying files.
- Added the `FinalizedAssetView` class which provides a list of all available
  assets to the `BuildEnvironment` during the build finalization phase.
  - `outputMap` has moved from `BuildOptions` to this constructor, as a named
    argument.
- The `OverridableEnvironment` now supports overriding the new `finalizeBuild`
  api.
- The number of concurrent actions per phase is now limited (currently to 16),
  which should help with memory and cpu usage for large builds.

## 0.2.2+2

- Support `package:json_annotation` v1.

## 0.2.2+1

- Tag errors from cached actions when they are printed.

## 0.2.2

- Changed the default file caching logic to use an LRU cache.

## 0.2.1+2

- Clarify wording for conflicting output directory options. No behavioral
  differences.
- Reduce the memory consumption required to create an output dir significantly.
- Increased the upper bound for the sdk to `<3.0.0`.

## 0.2.1+1

- Allow reuse cache between machines with different OS

## 0.2.1

- The hash dir for the asset graph under `.dart_tool/build` is now based on a
  relative path to the build script instead of the absolute path.
  - This enables `.dart_tool/build` directories to be reused across different
    computers and directories for the same project.

## 0.2.0

### New Features

- The `BuildPerformance` class is now serializable, it has a `fromJson`
  constructor and a `toJson` instance method.
- Added `BuildOptions.logPerformanceDir`, performance logs will be continuously
  written to that directory if provided.
- Added support for `global_options` in `build.yaml` of the root package.
- Allow overriding the default `Resolvers` implementation.
- Allows building with symlinked files. Note that changes to the linked files
  will not trigger rebuilds in watch or serve mode.

### Breaking changes

- `BuildPhasePerformance.action` has been replaced with
  `BuildPhasePerformance.builderKeys`.
- `BuilderActionPerformance.builder` has been replaced with
  `BuilderActionPerformance.builderKey`.
- `BuildResult` no longer has an `exception` or `stackTrace` field.
- Dropped `failOnSevere` arguments. Severe logs are always considered failing.

### Internal changes

- Remove dependency on package:cli_util.

## 0.1.0

Initial release, migrating the core functionality of package:build_runner to
this package.
