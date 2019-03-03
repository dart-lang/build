## 1.2.8

- Fix issue where daemon command wouldn't properly shutdown.
- Allow running when the root package, or a path dependency, is named `test`.

## 1.2.7

- Fix issue where daemon command would occasionally color a log.

## 1.2.6

- Prevent terminals being launched when running the daemon command on Windows.
- No longer assumeTty when logging through the daemon command.
- Update `build_daemon` to version `0.4.0`.
- Update `build_runner_core` to version `2.0.3`.
- Ensure the daemon command always exits.

## 1.2.5

- Fix a bug with the build daemon where the output options were ignored.

## 1.2.4

- Update `build_resolvers` to version `1.0.0`.

## 1.2.3

- Fix a bug where changing between `--live-reload` and `--hot-reload` might not
  work due to the etags for the injected JS not changing when they should.

## 1.2.2

- Change the format of Build Daemon messages.
- Build Daemon asset server now properly waits for build results.
- Build Daemon now properly signals the start of a build.
- Fix path issues with Daemon command under Windows.

## 1.2.1

- Update `package:build_runner_core` to version `2.0.1`.

## 1.2.0

- Support building through `package:build_daemon`.
- Update `package:build_runner_core` to version `2.0.0`.

## 1.1.3

- Update to `package:graphs` version `0.2.0`.
- Fix an issue where when running from source in watch mode the script would
  delete itself when it shouldn't.
- Add digest string to the asset graph visualization.
- Added a filter box to the asset graph visualization.
- Allow `build` version `1.1.x`.

## 1.1.2

- Improve error message when the generated build script cannot be parsed or
  compiled and exit with code `78` to indicate that there is a problem with
  configuration in the project or a dependency's `build.yaml`.

## 1.1.1

### Bug Fixes

- Handle re-snapshotting the build script on SDK updates.
- Suppress header for the `Bootstrap` logger.

## 1.1.0

### New Features

- The build script will now be ran from snapshot, which improves startup times.
- The build script will automatically re-run itself when the build script is
  changed, instead of requiring the user to re-run it manually.

## 1.0.0

### Breaking Changes

- Massive cleanup of the public api. The only thing exported from this package
  is now the `run` method. The goal is to reduce the surface area in order to
  stabilize this package, since it is directly depended on by all users.
  - Removed all exports from build_runner_core, if you are creating a custom
    build script you will need to import build_runner_core directly and add a
    dependency on it.
  - Stopped exporting the `build` and `watch` functions directly, as well as the
    `ServeHandler`.
  - If this has broken your use case please file an issue on the package and
    request that we export the api you were using previously. These will be
    considered on an individual basis but the bar for additional exports will be
    high.
- Removed support for the --[no-]assume-tty command line argument as it is no
  longer needed.

## 0.10.3

- Improve performance tracking and visualization using the `timing` package.
- Handle bad asset graph in the `clean` command.

## 0.10.2

- Added `--hot-reload` cli option and appropriate functionality.
  See [hot-module-reloading](../docs/hot_module_reloading.md) for more info.
- Removed dependency on cli_util.

## 0.10.1+1

- Added better error handling when a socket is already in use in `serve` mode.

## 0.10.1

- Added `--live-reload` cli option and appropriate functionality
- Migrated glob tracking to a specialized node type to fix dart-lang/build#1702.

## 0.10.0

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

## 0.9.2

- Changed the default file caching logic to use an LRU cache.

## 0.9.1+1

- Increased the upper bound for the sdk to `<3.0.0`.

## 0.9.1

- The hash dir for the asset graph under `.dart_tool/build` is now based on a
  relative path to the build script instead of the absolute path.
  - This enables `.dart_tool/build` directories to be reused across different
    computers and directories for the same project.

## 0.9.0

### New Features

- Added the `--log-performance <dir>` option which will dump performance
  information to `<dir>` after each build.
- The `BuildPerformance` class is now serializable, it has a `fromJson`
  constructor and a `toJson` instance method.
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
- The 'test' command through `run` will no longer set an exit code. All manual
  build scripts which call `run` should use the `Future<int>` return to set the
  exit code for the process.
- Dropped `failOnSevere` arguments and `--fail-on-severe` flag. Severe logs are
  always considered failing.
- Severe level logs now go to `stdout` along with other logs rather than
  `stderr`. Uncaught exceptions from the `build_runner` system itself still go
  to `stderr`.

## Other

- Updated to the latest camel case constants from the sdk.
- Minimum sdk version is now `>=2.0.0-dev.61`.

## 0.8.10

- All builders with `build_to: source` will now be ran regardless of which
  directory is currently being built, see
  https://github.com/dart-lang/build/issues/1454 for context.
- `build` will now throw instead of returning a failed build result if nothing
  was built.
- Improve error message when a dependency has a bad `build.yaml` with a missing
  dependency.
- Sources that are not a part of a `target` will no longer appear in the asset
  graph, so they will not be readable or globbable.
- Updated the generated build script to not rely on json encode/decode for the
  builder options object. Instead it now directly inlines a map literal.

## 0.8.9

- Added support for building only specified top level directories.
  - The `build`, `watch` commands support positional arguments which are the
    directories to build. For example, `pub run build_runner build web` will
    only build the `web` directory.
  - The `serve` command treats positional args as it did before, except it will
    only build the directories you ask it to serve.
  - The `test` command will automatically only build the `test` directory.
  - If using the `-o` option, with the `<dir-to-build>:<output-dir>` syntax,
    then the `<dir-to-build>` will be added to the list of directories to build.
    - If additional directories are supplied with positional arguments, then
      those will also be built.
- Update to latest analyzer and build packages.
- Updated the `serve` logic to only serve files which were part of the actual
  build, and not stale assets. This brings the semantics exactly in line with
  what would be copied to the `-o` output directory.

## 0.8.8

- Improve search behavior on the `/$graph` page. Users can now query for
  paths and `AssetID` values – `pkg_name|lib/pkg_name.dart`.
- Commands that don't support trailing args will now appropriately fail with a
  usage exception.
- Fix a bug where some rebuilds would not happen after adding a new file that
  has outputs which were missing during the previous build.
- Fix a bug where failing actions which are no longer required can still cause
  the overall build to fail.

## 0.8.7

- Improve error handling on the `/$graph` page.
- Support the latest `package:builde`

## 0.8.6

- Forward default options for `PostProcessBuilder`s in the generated build
  script.
- If a build appears to be not making progress (no actions completed for 15
  seconds), then a warning will now be logged with the pending actions.
- Now fail when a build is requested which does not build anything.
- Clean up some error messages.

## 0.8.5

- Add log message for merged output errors.

## 0.8.4

- Log the number of completed actions on successful builds.
- Support the new `isRoot` field for `BuilderOptions` so that builders can
  do different things for the root package.
- Deprecated `PostProcessBuilder` and `PostProcessBuildStep`. These should be
  imported from `package:build` instead.

## 0.8.3

- Clean and summarize stack traces printed with `--verbose`.
- Added a `clean` command which deletes generated to source files and the entire
  build cache directory.
- Bug Fix: Use the same order to compute the digest of input files to a build
  step when writing it as when comparing it. Previously builds would not be
  pruned as efficiently as they can be because the inputs erroneously looked
  different.

## 0.8.2+2

- The `.packages` file is now always created in the root of the output directory
  instead of under each top level directory.

## 0.8.2+1

- Bug Fix: Correctly parse Window's paths with new `--output` semantics.

## 0.8.2

- Allow passing multiple `--output` options. Each option will be split on
  `:`. The first value will be the root input directory, the second value will
  be the output directory. If no delimeter is provided, all resources
  will be copied to the output directory.
- Allow deleting files in the post process build step.
- Bug Fix: Correctly include the default whitelist when multiple targets
  without include are provided.
- Allow logging from within a build factory.
- Allow serving assets from successful build steps if the overall build fails.
- Add a `--release` flag to choose the options from `release_options` in
  `build.yaml`. This should replace the need to use `--config` pointing to a
  release version of `build.yaml`.

## 0.8.1

- Improved the layout of `/$perf`, especially after browser window resize.
- `pub run build_runner` exits with a error when invoked with an unsupported
  command.
- Bug Fix: Update outputs in merged directory for sources which are not used
  during the build. For example if `web/index.html` is not read to produce any
  generated outputs changes to this file will now get picked up during `pub run
  build_runner watch --output build`.
- Don't allow a thrown exception from a Builder to take down the entire build
  process - instead record it as a failed action. The overall build will still
  be marked as a failure, but it won't crash the process.

## 0.8.0

### New Features

- Added the new `PostProcessBuilder` class. These are not supported in bazel,
  and are different than a normal `Builder` in some fundamental ways:
  - They don't have to declare output extensions, and can output any file as
    long as it doesn't conflict with an existing one. This is only checked at
    build time.
  - They can only read their primary input.
  - They will not cause optional actions to run - they will only run on assets
    that were built as a part of the normal build.
  - They can not be optional themselves, and can only output to cache.
  - Because they all run in a single phase, after other builders, none of their
    outputs can be used as inputs to any actions.
- Added `applyPostProccess` method which takes `PostProcessBuilderFactory`s
  instead of `BuilderFactory`s.

### Breaking Changes

- `BuilderApplication` now has a `builderActionFactories` getter instead of a
  `builderFactories` getter.
- The default constructor for `BuilderApplication` has been replaced with
  `BuilderApplication.forBuilder` and
  `BuilderApplication.forPostProcessBuilder`.

## 0.7.14

- Warn when using `--define` or `build.yaml` configuration for invalid builders.

## 0.7.13+1

- Fix a concurrent modification error when using `listAssets` when an asset
  could be written.

## 0.7.13

- Fix a bug where a chain of `Builder`s would fail to run on some outputs from
  previous steps when the generated asset did not match the target's `sources`.
- Added support for serving on IPv4 loopback when the server hostname is
  'localhost' (the default).
- Added support for serving on any connection (both IPv4 and IPv6) when the
  hostname is 'any'.
- Improved stdout output.

## 0.7.12

- Added the `--log-requests` flag to the `serve` command, which will log all
  requests to the server.
- Build actions using `findAssets` will be more smartly invalidated.
- Added a warning if using `serve` mode but no directories were found to serve.
- The `--output` option now only outputs files that were required for the latest
  build. Previously when switching js compilers you could end up with ddc
  modules in your dart2js output, even though they weren't required. See
  https://github.com/dart-lang/build/issues/1033.
- The experimental `create_merged_dir` binary is now removed, it can't be easily
  supported any more and has been replaced by the `--output` option.
- Builders which write to `source` are no longer guaranteed to run before
  builders which write to `cache`.
- Honors `runs_before` configuration from Builder definitions.
- Honors `applies_builders` configuration from Builder definitions.

## 0.7.11+1

- Switch to use a `PollingDirectoryWatcher` on windows, which should fix file
  watching with the `--output` option. Follow along at
  https://github.com/dart-lang/watcher/issues/52 for more details.

## 0.7.11

- Performance tracking is now disabled by default, and you must pass the
  `--track-performance` flag to enable it.
- The heartbeat logger will now log the current number of completed versus
  scheduled actions, and it will log once a second instead of every 5 seconds.
- Builds will now be invalidated when the dart SDK is updated.
- Fixed the error message when missing a build_test dependency but trying to run
  the `test` command.
- The build script will now exit on changes to `build.yaml` files.

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
