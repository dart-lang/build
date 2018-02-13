## 0.7.11-dev

- Performance tracking is now disabled by default, and you must pass the
  `--track-performance` flag to enable it.
- The heartbeat logger will now log the current number of completed versus
  scheduled actions, and it will log once a second instead of every 5 seconds.
- Builds will now be invalidated when the dart SDK is updated.

## 0.7.10+1

- Fix bug where relative imports in a dependencies build.yaml would break
  all downstream users, https://github.com/dart-lang/build/issues/995.

## 0.7.10

### New Features

- Added a basic performance visualization. When running with `serve` you can
  now navigate to `/$perf` and get a timeline of all actions. If you are
  experiencing slow builds (especially incremental ones), you can save the
  html of that page and attach it to bug reports!

### Bug Fixes

- When using `--output` we will only clean up files we know we previously output
  to the specified directory. This should allow running long lived processes
  such as servers in that directory (as long as they don't hold open file
  handles).

## 0.7.9+2

- Fixed a bug with build to source and watch mode that would result in an
  infinite build loop, [#962](https://github.com/dart-lang/build/issues/962).

## 0.7.9+1

- Support the latest `analyzer` package.

## 0.7.9

### New Features

- Added command line args to override config for builders globally. The format
  is `--define "<builder_key>=<option>=<value>"`. As an example, enabling the
  dart2js compiler for the `build_web_compilers|entrypoint` builder would look
  like this: `--define "build_web_compilers|entrypoint=compiler=dart2js"`.

### Bug Fixes

- Fixed an issue with mixed mode builds, see
  https://github.com/dart-lang/build/issues/924.
- Fixed some issues with exit codes and --fail-on-severe, although there are
  still some outstanding problems. See
  https://github.com/dart-lang/build/issues/910 for status updates.
- Fixed an issue where the process would hang on exceptions, see
  https://github.com/dart-lang/build/issues/883.
- Fixed an issue with etags not getting updated for source files that weren't
  inputs to any build actions, https://github.com/dart-lang/build/issues/894.
- Fixed an issue with hidden .DS_Store files on mac in the generated directory,
  https://github.com/dart-lang/build/issues/902.
- Fixed test output so it will use the compact reporter,
  https://github.com/dart-lang/build/issues/821.

## 0.7.8

- Add `--config` option to use a different `build.yaml` at build time.

## 0.7.7+1

- Avoid watching hosted dependencies for file changes.

## 0.7.7

- The top level `run` method now returns an `int` which represents an `exitCode`
  for the command that was executed.
  - For now we still set the exitCode manually as well but this will likely
    change in the next breaking release. In manual scripts you should `await`
    the call to `run` and assign that to `exitCode` to be future-proofed.

## 0.7.6

- Update to package:build version `0.12.0`.
- Removed the `DigestAssetReader` interface, the `digest` method has now moved
  to the core `AssetReader` interface. We are treating this as a non-breaking
  change because there are no known users of this interface.

## 0.7.5+1

- Bug fix for using the `--output` flag when you have no `test` directory.

## 0.7.5

- Add more human friendly duration printing.
- Added the `--output <dir>` (or `-o`) argument which will create a merged
  output directory after each build.
- Added the `--verbose` (or `-v`) flag which enables verbose logging.
  - Disables stack trace folding and terse stack traces.
  - Disables the overwriting of previous info logs.
  - Sets the default log level to `Level.ALL`.
- Added `pubspec.yaml` and `pubspec.lock` to the whitelist for the root package
  sources.

## 0.7.4

- Allows using files in any build targets in the root package as sources if they
  fall outside the hardcoded whitelist.
- Changes to the root `.packages` file during watch mode will now cause the
  build script to exit and prompt the user to restart the build.

## 0.7.3

- Added the flag `--low-resources-mode`, which defaults to `false`.

## 0.7.2

- Added the flag `--fail-on-severe`, which defaults to `false`. In a future
  version this will default to `true`, which means that logging a message via
  `log.severe` will fail the build instead of just printing to the terminal.
  This would match the current behavior in `bazel_codegen`.
- Added the `test` command to the `build_runner` binary.

## 0.7.1+1

- **BUG FIX**: Running the `build_runner` binary without arguments no longer
  causes a crash saying `Could not find an option named "assume-tty".`.

## 0.7.1

- Run Builders which write to the source tree before those which write to the
  build cache.

## 0.7.0

### New Features

- Added `toRoot` Package filter.
- Actions are now invalidated at a fine grained level when `BuilderOptions`
  change.
- Added magic placeholder files in all packages, which can be used when your
  builder doesn't have a clear primary input file.
  - For non-root packages the placeholder exists at `lib/$lib$`, you should
    declare your `buildExtensions` like this `{r'$lib$': 'my_output_file.txt'}`,
    which would result in an output file at `lib/my_output_file.txt` in the
    package.
  - For the root package there are also placeholders at `web/$web$` and
    `test/$test$` which should cover most use cases. Please file an issue if you
    need additional placeholders.
  - Note that these placeholders are not real assets and attempting to read them
    will result in an `AssetNotFoundException`.

### Breaking Changes

- Removed `BuildAction`. Changed `build` and `watch` to take a
  `List<BuilderApplication>`. See `apply` and `applyToRoot` to set these up.
- Changed `apply` to take a single String argument - a Builder key from
  `package:build_config` rather than a separate package and builder name.
- Changed the default value of `hideOutput` from `false` to `true` for `apply`.
  With `applyToRoot` the value remains `false`.
- There is now a whitelist of top level directories that will be used as a part
  of the build, and other files will be ignored. For now those directories
  include 'benchmark', 'bin', 'example', 'lib', 'test', 'tool', and 'web'.
  - If this breaks your workflow please file an issue and we can look at either
    adding additional directories or making the list configurable per project.
- Remove `PackageGraph.orderedPackages` and `PackageGraph.dependentsOf`.
- Remove `writeToCache` argument of `build` and `watch`. Each `apply` call
  should specify `hideOutput` to keep this behavior.
- Removed `PackageBuilder` and `PackageBuildActions` classes. Use the new
  magic placeholder files instead (see new features section for this release).

The following changes are technically breaking but should not impact most
clients:

- Upgrade to `build_barback` v0.5.0 which uses strong mode analysis and no
  longer analyzes method bodies.
- Removed `dependencyType`, `version`, `includes`, and `excludes` from
  `PackageNode`.
- Removed `PackageNode.noPubspec` constructor.
- Removed `InputSet`.
- PackageGraph instances enforce that the `root` node is the only node with
  `isRoot == true`.

## 0.6.1

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
- Fixed an issue on windows where incremental builds didn't work.

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
