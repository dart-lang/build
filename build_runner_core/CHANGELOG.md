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
