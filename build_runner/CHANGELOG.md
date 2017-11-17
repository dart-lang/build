## 0.6.1-dev

### New Features

- Add an `enableLowResourcesMode` option to `build` and `watch`, which will
  consume less memory at the cost of slower builds. This is intended for use in
  resource constrained environments such as Travis.
- Add `createBuildActions`. After finding a list of Builders to run, and defining
  which packages need them applied, use this tool to apply them in the correct
  order across the package graph.

### Deprecations

- Deprecate `PackageGraph.orderedPackages` and `PackageGraph.dependentsOf`.

### Internal Improvements

- Outputs will no longer be rebuilt unless their inputs actually changed,
  previously if any transtive dependency changed they would be invalidated.
- Switched to using semantic analyzer summaries, this combined with the better
  input validation means that, ddc/summary builds are much faster on non-api
  affecting edits (dependent modules will no longer be rebuilt).
- Build script invalidation is now much faster, which speeds up all builds.

### Bug Fixes

- The build actions are now checked against the previous builds actions, and if
  they do not match then a full build is performed. Previously the behavior in
  this case was undefined.
- Fixed an issue where once an edge between an output and an input was created
  it was never removed, causing extra builds to happen that weren't necessary.
- Build actions are now checked for overlapping outputs in non-checked mode,
  previously this was only an assert.
- Fixed an issue where nodes could get in an inconsistent state for short
  periods of time, leading to various errors.

## 0.6.0+1

### Internal Improvements

- Now using `package:pool` to limit the number of open file handles.

### Bug fixes

- Fixed an issue where the asset graph could get in an invalid state if you
  aren't setting `writeToCache: true`.

## 0.6.0

### New features

- Added `orderedPackages` and `dependentsOf` utilities to `PackageGraph`.
- Added the `noPubspec` constructor to `PackageNode`.
- Added the `PackageBuilder` and `PackageBuildAction` classes. These builders
  only run once per package, and have no primary input. Outputs must be well
  known ahead of time and are declared with the `Iterable<String> get outputs`
  field, which returns relative paths under the current package.
- Added the `isOptional` field to `BuildAction`. Setting this to `true` means
  that the action will not run unless some other non-optional action tries to
  read one of the outputs of the action.
- **Breaking**: `PackageNode.location` has become `PackageNode.path`, and is
  now a `String` (absolute path) instead of a `Uri`; this prevents needing
  conversions to/from `Uri` across the package.
- **Breaking**: `RunnerAssetReader` interface requires you to implement
  `MultiPackageAssetReader` and `DigestAssetReader`. This means the
  `packageName` named argument has changed to `package`, and you have to add the
  `Future<Digest> digest(AssetId id)` method. While technically breaking most
  users do not rely on this interface explicitly.
  - You also no longer have to implement the
    `Future<DateTime> lastModified(AssetId id)` method, as it has been replaced
    with the `DigestAssetReader` interface.
- **Breaking**: `ServeHandler.handle` has been replaced with
  `Handler ServeHandler.handleFor(String rootDir)`. This allows you to create
  separate handlers per directory you want to serve, which maintains pub serve
  conventions and allows interoperation with `pub run test --pub-serve=$PORT`.

### Bug fixes

- **Breaking**: All `AssetReader#findAssets` implementations now return a
  `Stream<AssetId>` to match the latest `build` package. This should not affect
  most users unless you are extending the built in `AssetReader`s or using them
  in a custom way.
- Fixed an issue where `findAssets` could return declared outputs from previous
  phases that did not actually output the asset.
- Fixed two issues with `writeToCache`:
  - Over-declared outputs will no longer attempt to build on each startup.
  - Unrecognized files in the cache dir will no longer be treated as inputs.
- Asset invalidation has changed from using last modified timestamps to content
  hashes. This is generally much more reliable, and unblocks other desired
  features.

### Internal changes

- Added `PackageGraphWatcher` and `PackageNodeWatcher` as a wrapper API,
  including an `AssetChange` class that is now consistently used across the
  package.

## 0.5.0

- **Breaking**: Removed `buildType` field from `BuildResult`.
- **Breaking**: `watch` now returns a `ServeHandler` instead of a
  `Stream<BuildResult>`. Use `ServeHandler.buildResults` to get back to the
  original stream.
- **Breaking**: `serve` has been removed. Instead use `watch` and use the
  resulting `ServeHandler.handle` method along with a server created in the
  client script to start a server.
- Prevent reads into `.dart_tool` for more hermetic builds.
- Bug Fix: Rebuild entire asset graph if the build script changes.
- Add `writeToCache` argument to `build` and `watch` which separates generated
  files from the source directory and allows running builders against other
  packages.
- Allow the latest version of `package:shelf`.

## 0.4.0+3

- Bug fix: Don't try to delete files generated for other packages.

## 0.4.0+2

- Bug fix: Don't crash after a Builder reads a file from another package.

## 0.4.0+1

- Depend on `build` 0.10.x and `build_barback` 0.4.x

## 0.4.0

- **Breaking**: The `PhaseGroup` class has been replaced with a
  `List<BuildAction>` in `build`, `watch`, and `serve`. The `PhaseGroup` and
  `Phase` classes are removed.
  If your current build has multiple actions in a single phase which are
  depending on *not* seeing the outputs from other actions in the phase you will
  need to instead set up the `InputSet`s so that the outputs are filtered out.
- **Breaking**: The `resolvers` argument has been removed from `build`, `watch`,
  and `serve`.
- Allow `package:build` v0.10.x

## 0.3.4+1

- Support the latest release of `build_barback`.

## 0.3.4

- Support the latest release of `analyzer`.

## 0.3.2

- Support for build 0.9.0

## 0.3.1+1

- Bug Fix: Update AssetGraph version so builds can be run without manually
  deleting old build directory.
- Bug Fix: Check for unreadable assets in an async method rather than throw
  synchronously

## 0.3.1

- Internal refactoring of RunnerAssetReader.
- Support for build 0.8.0
- Add findAssets on AssetReader implementations
- Limit Asset reads to those which were available at the start of the phase.
  This might cause some reads which uses to succeed to fail.

## 0.3.0

### Bug Fixes

- Fixed a race condition bug [175](https://github.com/dart-lang/build/issues/175)
  that could cause invalid output errors.

### Breaking Changes

- `RunnerAssetWriter` now requires an additional field, `onDelete` which is a
  callback that must be called synchronously within `delete`.

## 0.2.0

Add support for the new bytes apis in `build`.

### New Features

- `FileBasedAssetReader` and `FileBasedAssetWriter` now support reading/writing
  as bytes.

### Breaking Changes

- Removed the `AssetCache`, `CachedAssetReader`, and `CachedAssetWriter`. These
  may come back at a later time if deemed necessary, but for now they just
  complicate things unnecessarily without proven benefits.
- `BuildResult#outputs` now has a type of `List<AssetId>` instead of
  `List<Asset>`, since the `Asset` class no longer exists. Additionally this was
  wasting memory by keeping all output contents around when it's not generally
  a very useful thing outside of tests (which retain this information in other
  ways).

## 0.0.1

- Initial separate release - split off from `build` package.
