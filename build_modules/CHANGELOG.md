## 5.1.6

- Allow `analyzer` 10.0.0.

## 5.1.5

- Add support for DDC's Library Bundle module system, which is compatible with web hot reload. This is not yet enabled by default.

## 5.1.4

- Fix module_builder reading DDC modules for non-primary dart libraries.
- Allow Dart SDK 3.11.x and 3.12 prerelease.

## 5.1.3

- Allow `analyzer` 9.0.0.

## 5.1.2

- Make compatible with `dart run build_runner build --force-aot`.

## 5.1.1

- Fix re-add `multiRootScheme` to build_modules exports.

## 5.1.0

- Add drivers and state resources required for DDC + Frontend Server compilation.
- Add an option to disable strongly connected components for determining module boundaries.

## 5.0.18

- Remove unused dev dependency: `build_runner_core`.
- Allow Dart SDK 3.10.x and 3.11 prerelease.

## 5.0.17

- Allow `build` 4.0.0.

## 5.0.16

- Remove unused dep: `build_config`.
- Allow `analyzer` 8.0.0.

## 5.0.15

- Allow `build` 3.0.0.

## 5.0.14

- Allow Dart SDK 3.9.x and 3.10 prerelease.

## 5.0.13

- Allow Dart SDK 3.8.x and 3.9 prerelease.

## 5.0.12

- Bump the min SDK to 3.7.0.
- Use `build_test` 3.0.0.
- Use AOT snapshot for kernel_worker.

## 5.0.11

- Support 3.8.0 pre-release sdks.

## 5.0.10

- Bump the min sdk to 3.6.0.
- Support analyzer version 7.x.

## 5.0.10-beta.0

- Bump the min sdk to 3.5.0.
- Support 3.7.0 pre-release sdks.

## 5.0.9

- Bump the min sdk to 3.5.0-259.0.dev.
- Allow version 3.6.x of the Dart SDK.

## 5.0.8

- Allow version 3.5.x of the Dart SDK.

## 5.0.7

- Fixes to support package:js version 0.7.0.

## 5.0.6

- Allow version 3.4.x of the Dart SDK.

## 5.0.5

- Allow version 3.3.x of the Dart SDK.

## 5.0.4

- Allow version 3.2.x of the Dart SDK.

## 5.0.3

- Allow the latest analyzer (6.x.x).

## 5.0.2

- Support Dart version 3.1.

## 5.0.1

- Delete the long deprecated `dart2JsWorkerResource` api and associated code.
  - This should have landed in 5.0.0 but in practice doesn't work in Dart 3 any
    longer anyways, and has been officially deprecated for a long time.

## 5.0.0

- Require Dart 3.0.
  - Drop support for unsound null safety.
  - Drop support for null asserts (irrelevant with sound null safety).

## 4.0.7

- Migrate off deprecated analyzer apis.
- Update min sdk constraint to 2.18.0.
- Expand pubspec description.

## 4.0.6

- Allow the latest `package:analyzer`.

## 4.0.5

* Allow analyzer verion 4.x.

## 4.0.4

- Allow the latest analyzer.

## 4.0.3

- Drop package:pedantic dependency and replace it with package:lints.

## 4.0.2

- Log a better and more consistent message when we encounter dart: uris in
  conditional imports.

## 4.0.1

- Allow analyzer version 2.x.x.

## 4.0.0

- Migrate to null safety.

## 3.0.6

- Update to graphs `1.x`
- Update to build `2.x`
- Update to scratch_space `1.x`

## 3.0.5

- Update to glob `2.x`.
- Update to analyzer `1.x`.

## 3.0.4

- Allow the null safe pre-releases of `bazel_worker`.

## 3.0.3

- Allow the null safe pre-releases of all migrated deps.

## 3.0.2

- Allow `package:json_annotation` `v4.x`.

## 3.0.1

- Allow the latest analyzer version `0.41.x`.

## 3.0.0

- Re-release of 2.11.2 but as a breaking change.

## 2.11.3

- Reverts back to the 2.10.1 release. The updates from 2.11 will be republished
  as a breaking change, in version 3.0.0.

## 2.11.2

- Re-release 2.11.0 with a min sdk constraint of `2.10.0-93.0.dev`

## 2.11.1

- Reverts 2.11.0 for older sdks than <2.10.0-93.0.dev.

## 2.11.0

- Add support for building null safe kernel modules to `KernelBuilder`.
- Allow the latest analyzer version `0.40.x`.
- Stop using deprecated analyzer apis.
- Stop passing the deprecated `--kernel` flag to the dev compiler.
- Update the package_config used in the shared compiler tmp dir to cover the
  non-lib dirs for the root package.
- Expose `maxWorkersPerTask` variable.

## 2.10.1

- Fix a bug where file names with spaces were not escaped before being passed
  to dart2js.

## 2.10.0

- Deprecated the `experiments` argument to `KernelBuilder` and default it to
  use the value from the current zone.

## 2.9.0

- Copy the `package_config.json` file to the scratch space directory, which
  allows us to respect language versions properly during compilation.
  - Also removes the custom `.packages` files that were previously created for
    each action.

## 2.8.1

- Avoid waiting for `exitCode` from detached worker processes. In previous SDKs
  this was `null` but it was changed to throw.

## 2.8.0

- Add the ability to pass a list of experiments to enable to the KernelBuilder.

## 2.7.0

- Add support for an environment variable `BUILD_DART2JS_VM_ARGS` which can
  be used to supply Dart vm arguments for the dart2js processes.

## 2.6.3

- Keep cached deserialized module instances in more cases. This may improve
  performance of incremental builds in watch mode.
- **Deprecated**: The package specific unsupported module allow list option
  provided by `computeTransitiveDependencies`. The only known uses are being
  removed.
- Allow analyzer version `0.39.x`.

## 2.6.2

Republish of `2.6.0` with the proper min sdk contraint.

## 2.6.1

### Bug fix for issue #2464

Ignore the `trackUnusedInputs` option that was added in `2.6.0`.

This option will be respected again in the next release which will have the
proper minimum sdk constraint.

## 2.6.0

Add support for dependency pruning to the `KernelBuilder`. This should greatly
improve the invalidation semantics for builds, meaning that less code will be
recompiled for each edit you make.

This is not enabled by default but can be enabled by passing
`trackUnusedInputs: true` to the `KernelBuilder` constructor.

## 2.5.0

- Add an option to skip the unsupported module check for modules in specified
  packages.

## 2.4.3

- Allow analyzer version 0.38.0.

## 2.4.2

- Support the latest release of `package:json_annotation`.

## 2.4.1

- Require non-empty output from kernel build steps.

## 2.4.0

- Allow overriding the target name passed to the kernel worker.

## 2.3.1

- Allow analyzer version 0.37.0.

## 2.3.0

- Add a `hasMain` boolean to the `ModuleLibrary` class.
  - This is now used instead of `isEntrypoint` for determining whether or not
    to copy module files for application discovery.
- Fix `computeTransitiveDeps` to do error checking for the root module as well
  as transitive modules.

## 2.2.0

- Make the `librariesPath` in the `KernelBuilder` configurable.
- Fixed bug where the configured dart SDK was ignored.

## 2.1.3

- Skip compiling modules with kernel when the primary source isn't the primary
  input (only shows up in non-lazy builds - essentially just tests).

## 2.1.2

- Output additional `.module` files for all entrypoints to ease discovery of
  modules for compilers.

## 2.1.1

- Allow `build_config` `0.4.x`.

## 2.1.0

- Make using the incremental compiler in the `KernelBuilder` configurable.

## 2.0.0

### Breaking Changes

- Remove the `merge` method from `Module` and replace with a static
  `Module.merge`. Module instances are now immutable.
- Remove `jsId`, and `jsSourceMapId` from `Module`.
- `DartPlatform` no longer has hard coded platforms, and its constructor is now
  public. Anybody is now free to create their own `platform`.
- Removed the platform specific builder factories from the `builders.dart` file.
  - Packages that want to target compilation for a platform should create their
    own builder factories.
- Removed completely the analyzer based builders - `UnlinkedSummaryBuilder` and
  `LinkedSummaryBuilder`.
  - All backends should now be using the `KernelBuilder` instead.
- Removed the default module builders for each supported platform. These
  must now be created by the packages that want to add compilation targeting a
  specific platform.
  - This will help reduce asset graph bloat caused by platforms that you weren't
    actually targeting.

### Improvements

- Update the kernel worker to pass input digests, along with
  `--reuse-compiler-result` and `--use-incremental-compiler`.
- Increased the upper bound for `package:analyzer` to `<0.37.0`.

## 1.0.11

- Allow build_config 0.4.x.

## 1.0.10

- Fix a performance issue in the kernel_builder, especially for larger projects.

## 1.0.9

- Allow configuring the platform SDK directory in the `KernelBuilder` builder.

## 1.0.8

- Don't follow `dart.library.isolate` conditional imports for the DDC
  platform.

## 1.0.7+2

- Update `dart2js` snapshot arguments for upcoming SDK.

## 1.0.7+1

- Fix broken release by updating `dart2js` worker and restricting sdk version.

## 1.0.7

- Explicitly skip dart-ext uris during module creation.
  - Filed Issue #2047 to track real support for native extensions.
- Run workers with mode `detachedWithStdio` if no terminal is connected.

## 1.0.6

- Improved the time tracking for kernel and analyzer actions by not reporting
  time spent waiting for a worker to be available.

## 1.0.5

- Increased the upper bound for `package:analyzer` to `<0.36.0`.

## 1.0.4

- Update to `package:graphs` version `0.2.0`.
- Use `dartdevc --kernel` instead of `dartdevk`.

## 1.0.3

- Increased the upper bound for `package:analyzer` to `<0.35.0`.

## 1.0.2

- Support the latest `package:json_annotation`.

## 1.0.1

- Increased the upper bound for `package:analyzer` to '<0.34.0'.

## 1.0.0

### Breaking Changes

- The `Module` constructor has an additional required parameter `isSupported`,
  which indicates if a module is supported on that module's platform.

## 0.4.0

### Improvements

- Modules are now platform specific, and config specific imports using
  `dart.library.*` constants are supported.

### Breaking Configuration Changes

- Module granularity now has to be configured per platform, so instead of
  configuring it using the `build_modules|modules` builder, you now need to
  configure the builder for each specific platform:

```yaml
targets:
  $default:
    build_modules|dartdevc:
      options:
        strategy: fine
```

  The supported platforms are currently `dart2js`, `dartdevc`, `flutter`, and
  `vm`.

### Breaking API Changes

- Output extensions of builders have changed to include the platform being built
  for.
  - All the top level file extension getters are now methods that take a
    platform and return the extension for that platform.
- Most builders are no longer applied by default, you must manually apply them
  using applies_builders in your builder.
- Most builder constructors now require a `platform` argument.

## 0.3.2

- Module strategies are now respected for all packages instead of just the root
  package.
- Can now mix and match fine and coarse strategies at will, even within package
  cycles (although this may cause larger modules).
- Removed analyzer dependency.

## 0.3.1+1

- Support `package:json_annotation` v1.

## 0.3.1

- Change the default module strategy for the root package to `coarse`.

## 0.3.0

### Improvements

- Updated dart2js support so that it can do multiple builds concurrently and
  will restart workers periodically to mitigate the effects of
  dart-lang/sdk#33708.
- Increased the upper bound for the sdk to `<3.0.0`.

### Breaking Changes

- Removed the `kernelSummaryExtension`, and renamed the `KernelSummaryBuilder`
  to `KernelBuilder`. The new builder can be used to create summaries or full
  kernel files, and requires users to give it a custom sdk.
- Changed `metaModuleCleanBuilder` to read `.module.library` files which are
  produced by the `moduleLibrayBuilder`. Clients using the automatically
  generated build script will get this automatically. Clients which have
  manually written build scripts will need to add it.

## 0.2.3

- Update to the latest `package:scratch_space` and don't manually clear it out
  between builds. This provides significant speed improvements for large
  projects.

## 0.2.2+6

- Support the latest `package:build_config`.

## 0.2.2+5

- Updated the missing modules message to highlight that the error is likely due
  to a missing dependency.

## 0.2.2+4

- Support `package:analyzer` `0.32.0`.

## 0.2.2+3

- Fix a race condition where we could fail to find the modules for some
  dependencies.

## 0.2.2+2

- Fix an issue where modules were unnecessarily being built with DDC.
  [#1375](https://github.com/dart-lang/build/issues/1375).

## 0.2.2+1

- Fix an issue with new files causing subsequent build failures
  [#1358](https://github.com/dart-lang/build/issues/1358).
- Expose `MetaModuleCleanBuilder` and `metaModuleCleanExtension` publicly for
  usage in tests and manual build scripts.

## 0.2.2

- Clean up `.module` and summary files from the output and server.
- Add new `ModuleBuilder` strategies. By default the `coarse` strategy is used
  for all non-root packages and will create a minimum number of modules. This
  strategy can not be overridden. However, for the root package, the `fine`
  strategy will be used which creates a module for each strongly
  connected component. You can override this behavior by providing `coarse`
  to the `strategy` option.

  Example configuration:

  ```yaml
  targets:
    $default:
      builders:
        build_modules|modules:
          options:
            strategy: coarse
  ```

## 0.2.1

- Give a guaranteed reverse dependency order for
  `Module.computeTransitiveDependencies`

## 0.2.0+2

- Fix use of `whereType` in `MissingModulesException`,
  https://github.com/dart-lang/build/issues/1123.

## 0.2.0+1

- Fix null pointer error in `MissingModulesException`,
  https://github.com/dart-lang/build/issues/1092.

## 0.2.0

- `computeTransitiveDependencies` now throws a `MissingModulesException` instead
  of logging a warning if it discovers a missing module.

## 0.1.0+2

- Fix a bug with the dart2js workers where the worker could hang if you try to
  re-use it after calling `terminateWorkers`. This only really surfaces in test
  environments.

## 0.1.0+1

- Fix a bug with imports to libraries that have names starting with `dart.`

## 0.1.0

- Split from `build_web_compilers`.
