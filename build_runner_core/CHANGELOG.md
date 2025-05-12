## 9.0.0-wip

- Breaking: refactor `OverridableEnvironment` and `IOEnvironment` into
  `BuildEnvironment`
- Breaking: add `deleteDirectory` to `RunnerAssetWriter`, make `delete`
  return `Future<void>`, remove deprecated `OnDelete`.
- Bump the min SDK to 3.7.0.
- Fix crash when running on assets ending in a dot.
- Start using `package:build/src/internal.dart'.
- Use `build_test` 3.0.0.
- Refactor `PathProvidingAssetReader` to `AssetPathProvider`.
- Refactor `MultiPackageAssetReader` to internal `AssetFinder`.
- `FinalizedReader` no longer implements `AssetReader`.
- Add internal `Filesystem` that backs `AssetReader` and `AssetWriter`
  implementations.
- Refactor `CachingAssetReader` to `FilesystemCache`.
- Refactor `BuildCacheReader` to `GeneratedAssetHider`.
- Refactor `FileBasedAssetReader` and `FileBasedAssetWriter` to `ReaderWriter`.
- Move `BuildStepImpl` to `build_runner_core`, use `SingleStepReader` directly.
- Remove `BuildCacheWriter`, functionality is handled by `AssetPathProvider`.
- Refactor `SingleStepReader` to `SingleStepReaderWriter`, incorporating
  `AssetWriterSpy` functionality.
- Add `NodeType` to `AssetNode`, remove subtypes. Make mutations explicit.
- Use `built_value` for `AssetNode` and related types, and for serialization.
- Add details of what changed and what is built to `--verbose` logging.
- New change detection algorithm.
- Add `reportUnusedAssetsForInput` to `BuildOptions`, to listen for when
  a builder notifies that an asset is unused.
- Use `LibraryCycleGraphLoader` to load transitive deps for analysis.
- Track post process builder outputs separately from the main graph Instead of
  in `postProcessAnchor` nodes.
- Compute outputs as needed instead of storing them in the asset graph.
- Check build options for changes in the phase setup instead of storing them
  in the asset graph.
- Refactor invalidation to track current build progress in `Build` instead of
  in the asset graph.
- Track resolver dependencies as library cycle graphs.
- Ignore deprecated analyzer API usages.

## 8.0.0

- __Breaking__: Add `completeBuild` to `RunnerAssetWriter`, a method expected
  to be called by the build system at the end of a completed build.
- Add `wrapInBatch` to obtain a reader/writer pair that will batch writes
  before flushing them at the end of a build.
- Bump the min sdk to 3.6.0.
- Require analyzer ^6.9.0, allow version 7.x.
- Fix analyzer deprecations.

## 7.3.2

- Additional fixes for pub workspace repos
- Migrate deprecates uses of `whereNotNull()` to `nonNulls`.
- Bump the min sdk to 3.5.0-259.0.dev.

## 7.3.1

- Support the upcoming pub workspaces feature.
- Bump the min sdk to 3.4.0.
- Remove some unnecessary casts and non-null assertions now that we have private
  field promotion.

## 7.3.0

- Bump the min sdk to 3.0.0.
- Add `integration_test` as a default top level directory for sources.

## 7.2.11

- Add better error messages for incomplete package configs when creating a
  package graph.
- Update to build_resolvers 2.4.0 and use the shared analyzer resolvers
  instance.

## 7.2.10

- Fix build script invalidation check for custom build scripts from other
  packages.

## 7.2.9

- Fix compatibility with `package:logging` version `1.2.0`.

## 7.2.8

- Raise the minimum SDK constraint to 2.18.
- Optimize `BuildStep.packageConfig`

## 7.2.7+1

- Backport the fix for package:logging version 1.2.0.

## 7.2.7

- Handle generation of hidden assets in a way consistent with the definition of
  public assets used in other parts of the build system.

## 7.2.6

- Add supported platforms to pubspec.

## 7.2.5

- Expand pubspec description.

## 7.2.4

- Fix some new lints.
- Fix a bug in the LRU cache.
- Fix a bug when manually deleting outputs of multiple output builders.

## 7.2.3

- Allow the latest analyzer.

## 7.2.2

- Fix a bug compilation bug on the 2.14 sdk.

## 7.2.1

- Drop package:pedantic dependency and replace it with package:lints.

## 7.2.0

- Deprecate the `pubBinary` variable.
- Add a `dartBinary` variable to be used instead of `pubBinary`.
- Update `pub run` references to `dart run`.

## 7.1.0

- Support capture groups, a feature introduced in `build`: `2.1.0`.

## 7.0.1

- Allow analyzer version 2.x.x.

## 7.0.0

- Migrate to null safety.
- Add an early error if any output extensions overlap with any input
  extensions to avoid infinite loops.

## 6.1.12

- Allow build_config `0.4.7`

## 6.1.11

- Update to graphs `1.x`.
- Update to build `2.x`.
- Update to build_resolvers `2.x`.

## 6.1.10

- Don't count packages in dependency_overrides as immediate dependencies when
  building package graphs. This allows you to override transitive builder deps
  without accidentally applying those builders to the root package.

## 6.1.9

- Allow the latest `build_config`.

## 6.1.8

- Update glob to `2.x`.

## 6.1.7

- Allow the null safe pre-release of `package_config` and `watcher`.

## 6.1.6

- Allow the null safe pre-releases of all migrated deps.

## 6.1.5

- Allow build version `1.6.x`.

## 6.1.4

- Allow build_config version `'>=0.4.1 <0.4.6'`.
- Allow yaml version `'>=2.1.11 <4.0.0'`.

## 6.1.3

- Allow `package:json_annotation` `v4.x`.

## 6.1.2

- Support the latest `package:build_config`.

## 6.1.1

- Fix a bug where `canRead` would throw if the `package` was unknown, instead
  of returning `false`.

## 6.1.0

- Require the latest build version (1.5.1).
- Support the `additional_public_assets` option in build configurations.
- Fix a bug where the server would respond with a 500 instead of a 404 for
  files that don't match any build filters but had previously failed.
- Fix the generated package config to include the full output directory
  for the root package.

## 6.0.3

- Fix https://github.com/dart-lang/build/issues/1804.

## 6.0.2

- Require the latest build version (1.5.x).

## 6.0.1

- Add back the `overrideGeneratedOutputDirectory` method.

## 6.0.0

-   Remove some constants and utilities which are implementation details.

## 5.2.0

- Dart language experiments are now tracked on the asset graph and will
  invalidate the build if they change.
  - Experiments are enabled for a zone by using the `withEnabledExperiments`
    function from `package:build/experiments.dart`.

## 5.1.0

- Add a warning if a package is missing some required placholder files,
  including `$package$` and `lib/$lib$`.
- Reduce chances for changing apparent build phases across machines with a
  different order of packages from `package_config.json`.

## 5.0.0

### Breaking changes

- `PackageGraph.forPath` and `PackageGraph.forThisPackage` are now static
  methods which return a `Future<PackageGraph>` instead of constructors.
- `PackageNode` now requires a `LanguageVersion`.

### Other changes

- Builds no longer depend on the contents of the package_config.json file,
  instead they depend only on the language versions inside of it.
  - This should help CI builds that want to share a cache across runs.
- Improve the error message for build.yaml parsing errors, suggesting a clean
  build if you believe the parse error is incorrect.
- Remove unused dev dependency on `package_resolver`.

## 4.5.3

- Don't throw a `BuildScriptInvalidated` exception on package_config.json
  updates unless running from snapshot.

## 4.5.2

- Don't assume the existence of a .dart_tool/package_config.json file when
  creating output directories.

## 4.5.1

- Don't fail if there is no .dart_tool/package_config.json file.

## 4.5.0

- Add the `package_config.json` file as an internal source, and invalidate
  builds when it changes.
- Avoid treating `AssetId` paths as URIs.

## 4.4.0

- Support the `auto_apply_builders` target configuration added in
  `build_config` version `0.4.2`.

## 4.3.0

- Add the `$package$` synthetic placeholder file and update the docs to prefer
  using only that or `lib/$lib$`.
- Add the `assets` directory and `$package$` placeholders to the default
  sources allow list.

## 4.2.1

- Bug fix: Changing the root package name will no longer cause subsequent
  builds to fail (Issue #2566).

## 4.2.0

### New Feature

- Allow reading assets created previously by the same `BuildStep`.

## 4.1.0

- Add support for trimming builds based on `BuildStep.reportUnusedAssets`
  calls. See the `build` package for more details.
- Include `node/**` in the default set of sources (when there is no target
  defined) for the root package.

## 4.0.0

### New Feature: Build Filters

- Added a new `BuildFilter` class which matches a set of assets with glob
  syntax support for both package and file names.
- Added `buildFilters` to `BuildOptions` which is a `Set<BuildFilter>` and
  is used to filter exactly which outputs will be generated.
  - Note that any inputs to the specified files will also necessarily be built.
- `BuildRunner.run` also now accepts an optional `Set<BuildFilter>` argument.
- `FinalizedReader` also  now accepts a `Set<BuildFilter>` optional parameter
  and will only allow reading matched files.
  - This means you can create output directories or servers that respect build
    filters.

### Breaking Changes

- `FinalizedReader.reset` now requires an additional `Set<BuildFilter>`
  argument.

## 3.1.1

- When skipping build script updates, don't check if the build script is a
  part of the asset graph either.

## 3.1.0

- Factor out the logic to do a manual file system scan for changes into a
  new `AssetTracker` class.
  - This is not exposed publicly and is only intended to be used from the
    `build_runner` package.

## 3.0.9

- Support the latest release of `package:json_annotation`.

## 3.0.8

- Fix --log-performance crash on windows by ensuring we use valid
  windows directory names.

## 3.0.7

- Support the latest `package:build_config`.

## 3.0.6

- Handle symlink creation failures and link to dev mode docs for windows.

## 3.0.5

- Explicitly require Dart SDK `>=2.2.0 <3.0.0`.
- Fix an error that could occur when serializing outdated glob nodes.

## 3.0.4

- Add additional error details and a fallback for
  https://github.com/dart-lang/build/issues/1804

## 3.0.3

- Share an asset graph when building regardless of whether the build script was
  started from a snapshot.

## 3.0.2

- Only track valid and readable assets as inputs to globs. Fixes a crash when
  attempting to check outputs from an invalid asset.

## 3.0.1

- Remove usage of set literals to fix errors on older sdks that don't support
  them.

## 3.0.0

- Fix an issue where `--symlink` was forcing outputs to not be hoisted.
- `BuildImpl` now takes an optional list of  `BuildTargets` instead of a list of
  `buildDirs`.
- Warn when there are no assets to write in a specified output directory.

## 2.0.3

- Handle asset graph decode failures.

## 2.0.2

- Update `build_resolvers` to version `1.0.0`.

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
