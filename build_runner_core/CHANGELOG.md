## 0.3.0-dev

### Breaking Changes

- The `RunnerAssetReader` interface now requires that you implement the new
  `PathProvidingAssetReader` interface, in order to support creating symlinks
  to the original files.

### New Features/Updates

- Reduce the memory consumption required to create an output dir significantly.
- Added a `outputSymlinksOnly` option to `BuildOptions`, that causes the merged
  output directories to contain only symlinks, which is much faster than copying
  files.
- Added the `PathProvidingAssetReader` interface, which requires a
  `String pathTo(AssetId id)` method that returns the underlying path to a
  given file.
- Added the `DelegatingAssetReader` interface, which allows an `AssetReader` to
  indicate it is wrapping another `AssetReader`, and provide public access to
  it.
- Clarify wording for conflicting output directory options. No behavioral
  differences.

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
