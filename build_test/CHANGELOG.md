## 3.3.1-wip

- Use `build` 3.0.1.

## 3.3.0

- Read build configs using `AssetReader` so they're easier to test: you can now
  pass in `build.yaml` like any other asset.
- Bug fix: don't crash when a builder logs during a `testBuilder` or
  `resolveSource` call outside a test.
- Remove unused deps: `async`, `convert`.
- Remove unused dev_deps: `collection`.
- Files loaded from disk for `resolveSources` and `testBuilders` that are in
  the same package as explicitly-passed test inputs are now loaded if they
  match the default globs, such as `lib/**`, instead of ignored. This more
  closely matches version 2 behavior.
- Use `build` 3.0.0.
- Use `build_resolvers` 3.0.0.

## 3.3.0-dev.3

- Read build configs using `AssetReader` so they're easier to test: you can now
  pass in `build.yaml` like any other asset.
- Bug fix: don't crash when a builder logs during a `testBuilder` or
  `resolveSource` call outside a test.
- Remove unused deps: `async`, `convert`.
- Remove unused dev_deps: `collection`.

## 3.3.0-dev.2

- Files loaded from disk for `resolveSources` and `testBuilders` that are in
  the same package as explicitly-passed test inputs are now loaded if they
  match the default globs, such as `lib/**`, instead of ignored. This more
  closely matches version 2 behavior.

## 3.3.0-dev.1

- Use `build` 3.0.0-dev.1.
- Use `build_resolvers` 3.0.0-dev.1.

## 3.2.0

- Fixes when passing a `readerWriter` to `testBuilders`: don't count initial
  assets as outputs; do set up packages for initial assets; only apply builders
  to packages mentioned in `sourceAssets`.
- Add `readAllSourcesFromFilesystem` parameter to `resolveSources`. Set it to
  `true` to make the method behave as it did in `build_test` 2.2.0.
- Fix to `resolveSources` error handling.

## 3.1.0

- Add `inputsTrackedFor` and `resolverEntrypointsTrackedFor` to
  `ReaderWriterTesting`, so tests can determine what each build step
  read and resolved.
- Add `loadIsolateSources` to `ReaderWriterTesting`. It loads all real
  sources visible to the test into memory.
- `testBuilder` default `onLog` now works outside of tests: it falls
  back to `print` instead of crashing.
- Update `README.md`.

## 3.0.0

Breaking changes:

- Breaking change: removed `tearDown` parameter to `resolveSources` for
  keeping resolvers across multiple tests.
- Breaking change: tests must use new `TestReaderWriter` instead of
  `InMemoryAssetReader` and `InMemoryAssetWriter`.
- Breaking change: `testBuilder` no longer accepts a `reader` and a `writer`.
  Instead it returns a `TestBuilderResult` with the `TestReaderWriter`
  that was used.
- Breaking change: `resolveSources` no longer automatically reads non-input
  files from the filesystem; specify explicitly which non-input files the
  test should read in `nonInputsToReadFromFilesystem`.
- Breaking change: remove `MultiAssetReader`. Load the source into one
  `TestReaderWriter` instead.
- Breaking change: `TestReaderWriter.assetsRead` does not take into account
  details of the build, it's just what was actually read. Use
  `TestReaderWriter.inputsTracked` for what was recorded as an input. Note that
  resolver entrypoints are now tracked separately from inputs, see
  `TestReaderWriter.resolverEntrypointsTracked`.
- Breaking change: Remove `StubAssetReader`. Use `TestReaderWriter` instead.

Other user-visible changes:

- `resolveSources` and `testBuilder` now do a full `build_runner` build, with
  configuration as much as possible based on the some parameters.
- Add `testBuilders` to run a test build with multiple builders.
- Add `optionalBuilders` to `testBuilders` to have some builders be optional.
- Add `visibleOutputBuilders` to `testBuilders` to have some builders write
  their output next to their inputs.
- Add `testingBuilderConfig` to `testBuilders` to control builder config
  override.
- Add `resolvers` parameter to `testBuild` and `testBuilders`.
- Add `readerWriter` and `enableLowResourceMode` parameters to `testBuild`
  and `testBuilders`.
- `TestReaderWriter` writes and deletes are notified to `FakeWatcher`.
- `TestReaderWriter` tracks `assetsWritten`.
- Support checks on reader state after a build action in `resolveSources`.

Versions:

- Bump the min SDK to 3.7.0.
- Use `build_runner_core` 9.0.0.

Internal changes:

- Start using `package:build/src/internal.dart`.
- Refactor `BuildCacheReader` to `BuildCacheAssetPathProvider`.
- Refactor `FileBasedAssetReader` and `FileBasedAssetWriter` to `ReaderWriter`.

## 2.2.3

- Bump the min sdk to 3.6.0.
- Allow analyzer version 7.x.

## 2.2.2

- Bump the min sdk to 3.0.0.
- Support the latest version of `package:test_core`.

## 2.2.1

- Avoid passing a nullable value to `Future.value`.
- Update to build_resolvers 2.4.0, which resolves some race conditions when
  using multiple resolvers instances.

## 2.2.0

- Forward logs from `testBuilder` to `printOnFailure` by default.

## 2.1.7

- Allow the latest test_core (version 5.x).

## 2.1.6

- Fix bug in package config file loading.
- Raise the minimum SDK constraint to 2.18.

## 2.1.5

- Allow the latest analyzer.

## 2.1.4

- Update `pub run` references to `dart run`.
- Drop package:pedantic dependency and replace it with package:lints.

## 2.1.3

- Use `allowedOutputs` in `TestBuilder` instead of computing them again.

## 2.1.2

- Allow the latest `package:test_core`.

## 2.1.1

- Allow analyzer version 2.x.x.

## 2.1.0

- Migrate internal builders of this package to null safety
- Require build_config version 1.0.0.

## 2.0.0

- Migrate `package:build_test/build_test.dart` to null safety.
- Update to build `2.x`.
- Update to build_resolvers `2.x`.

## 1.3.7

- Update to analyzer `1.x`.
- Update to glob `2.x`.

## 1.3.6

- Allow the null safe pre-release version of `html`.

## 1.3.5

- Allow the null safe pre-release version of `package_config` and `watcher`.

## 1.3.4

- Allow the null safe pre-release version of `stream_transform`.

## 1.3.3

- Return an empty stream instead of throwing from
  `PackageAssetReader.findAssets` when passed a non-existing package name.
- Allow the null safe migration package versions for `crypto`, `glob`,
  `logging`, and `package_config`.

## 1.3.2

- Fix the `test/index.html` not generating by default.

## 1.3.1

- Allow build version `1.6.x`.

- Use `$package$` placeholder instead of `$test$`.

## 1.3.0

- Add support for running generated `.browser_test.dart` directly instead of
  expecting the test runner with the query string `directRun=true`. It is no
  longer necessary to create a build config which generates for `*_test.dart`
  files in `build_web_compilers`, the default config generates for
  `.browser_test.dart` files which are used by `debug.html`.

## 1.2.2

- Allow package:build versions through `1.5.x`.

## 1.2.1

- Improve/fix `testBuilder` documentation.
- Update test bootstrap builder to copy language version comments from the test
  file if present.

## 1.2.0

- Add support for recognizing custom platforms in TestOn annotations during
  bootstrapping.

## 1.1.0

- Add support for enabling experiments via `withEnabledExperiments` zones from
  package:build, as well as forwarding the `packageConfig` argument from
  `resolve*` apis through to the default `Resolver`.
  - **Note**: If passing your own `Resolver` these things are still your
    responsibility.
- Added the ability to pass a `PackageConfig` to `testBuilder`, which is used
  to set the language version of each package.
  - The resolver created from `testBuilder` will also now respect the
    `withEnabledExperiments` zone.

## 1.0.0

- Removed dependency on `package:package_resolver`, changed to
  `package:package_config`.
  - All apis which used to take a `PackageResolver` now take a `PackageConfig`.
- Require SDK version `2.7.0`.

## 0.10.12+1

- Allow the latest test_core package (`0.3.x`).

## 0.10.12

- Fix a bug with the `resolve*` apis where they would leak unhandled async
  errors to client code if the provided action callback threw an error.

## 0.10.11

- Add support for the new `$package$` placeholder.

### Potentially Breaking Change

- Only add the non-lib placeholders when a root package is specified
  - Infer the root package when there is only one package in the sources
  - This is being released as a non-breaking change because the only expected
    use cases already would have been broken - `findAssets` calls already
    required a root package.

## 0.10.10

- Allow reading of assets written from the same build step.
  - This mirrors the latest behavior in build_runner_core.
- Require SDK version `2.6.0` to enable extension methods.

## 0.10.9+1

- Fix the `DebugTestBuilder` on windows.
- Fix `PackageAssetReader` on windows.

## 0.10.9

- Allow tracking of reported unused assets in `testBuilder` calls with the
  `reportUnusedAssetsForInput(AssetId input, Iterable<AssetId> unused)`
  callback.

## 0.10.8

- Allow a custom AssetReader to be passed to `testBuilder`. This will be used
  as a fallback for any sources that don't exist in the `sourceAssets` map.

## 0.10.7+3

- Handle the case where the root package in a `PackageAssetReader` is a fake
  package.

## 0.10.7+2

- Avoid throwing for missing files from `PackageAssetReader.canRead`.

## 0.10.7+1

- Allow `build_config` `0.4.x`.

## 0.10.7

- Support the latest version of `package:html`.
- Only generate bootstrap scripts for supported platforms based on `TestOn`
  annotations.

## 0.10.6

- Allow build_resolvers version `1.0.0`.

## 0.10.5

- Improve error messages for unresolvable URIs in the PackageAssetReader.

## 0.10.4

- Allow using `PackageAssetReader` when the current working directory is not the
  root package directory as long as it uses a pub layout.

## 0.10.3+4

- Increased the upper bound for `package:analyzer` to `<0.35.0`.

## 0.10.3+3

- Increased the upper bound for `package:analyzer` to '<0.34.0'.

## 0.10.3+2

- Declare support for `package:build` version 1.0.0.

## 0.10.3+1

- Increased the upper bound for the sdk to `<3.0.0`.

## 0.10.3

- Require test version ^0.12.42 and use `TypeMatcher`.
- Improve performance of test methods which use a `Resolver` by keeping a cached
  instance of `AnalyzerResolvers`.

## 0.10.2+4

- Allow the latest build_config.

## 0.10.2+3

- Remove package:build_barback dependency, and use public apis from package:test
  to directly do the bootstrapping instead of wrapping the transformer.

## 0.10.2+2

- Avoid looking for files from `Uri.path` paths.

## 0.10.2+1

- Add back an implementation of `findAssets` in `PackageAssetReader`.

## 0.10.2

- Added a `DebugIndexBuilder`, which by default generates a `test/index.html`
  with links to debug tests in your `test/**_test.dart` folder, linking to the
  generated `*_test.debug.html` files. **NOTE**: This only works for web-based
  tests.
- Fix `PackageAssetReader` when running with a package map pointing to a
  "packages" directory structure, as is generated by `build_runner`. Drop
  support for a broken `findAssets` implementation.

## 0.10.1+1

- Replace `BarbackResolvers` with `AnalyzerResolvers` from `build_resolvers` by
  default.

## 0.10.1

- Allow overriding the `Resolvers` used for `resolve*` utilities.
- Bug Fix: Don't call the `action` multiple times when there are multiple
  sources passed to `resolve*`.

## 0.10.0

- Added automatic generation of `.debug.html` files for all tests, which can
  be loaded in the browser to directly run tests and debug them without going
  through the package:test runner.
- Update to package:build version `0.12.0`.
- Removed `CopyBuilder` in favor of `TestBuilder` which takes closures to
  change behavior rather than adding configuration for every possible
  modification.
- Added support for the special placeholder `{$lib/$test/$web}` assets
  supported by the `build_runner` and `bazel_codegen` implementations of
  `package:build`. For an example see `test/test_builder_test.dart`. Note that
  this is technically a **BREAKING CHANGE**, as additional inputs will be
  matched for overzealous builders (like `TestBuilder`).
- Added `resolverFor` as an optional parameter to `resolveSources`. By default
  a `Resolver` is returned for the _first_ asset provided; to modify that the
  name of another asset may be provided. This is a **BREAKING CHANGE**, as
  previously the last asset was used.

## 0.9.4

- Added `InMemoryAssetReader.shareAssetCache` constructor. This is useful for the
  case where the reader should be kept up to date as assets are written through
  a writer.
- Added `buildInputs` stream to `CopyBuilder` which emits an event for each
  `BuildStep.inputId` at the top of the `build` method.
- `CopyBuilder` automatically skips the placeholder files (any file ending in
  `$`). This is technically breaking but should not affect any real users and is
  not being released as a breaking change.
- Changed `TestBootstrapBuilder` to only target `_test.dart` files.

## 0.9.3

- Added `resolveSources`, a way to resolve multiple libraries for testing,
  including any combination of fake files (in-memory, created in the test) and
  real ones (from on-disk packages):

```dart
test('multiple assets, some mock, some on disk', () async {
  final real = 'build_test|test/_files/example_lib.dart';
  final mock = 'build_test|test/_files/not_really_here.dart';
  final library = await resolveSources(
    {
      real: useAssetReader,
      mock: r'''
        // This is a fake library that we're mocking.
        library example;

        // This is a real on-disk library we are using.
        import 'example_lib.dart';

        class ExamplePrime extends Example {}
      ''',
    },
    (resolver) => resolver.findLibraryByName('example'),
  );
  final type = library.getType('ExamplePrime');
  expect(type, isNotNull);
  expect(type.supertype.name, 'Example');
});
```

## 0.9.2

- Add `inputExtension` argument to `CopyBuilder`. When used the builder with
  throw if any assets are provided that don't match the input extension.

## 0.9.1

- Allow `build_barback` version `0.5.x`. The breaking behavior change should not
  impact test uses that don't already have a version constraint on that package.

## 0.9.0

- Added the `TestBootstrapBuilder` under the `builder.dart` library. This can
  be used to bootstrap tests similar to the `test/pub_serve` Transformer.
  - **Known Issue**: Custom html files are not supported.
- **Breaking**: All `AssetReader#findAssets` implementations now return a
  `Stream<AssetId>` to match the latest `build` package.
- **Breaking**: The `DatedValue`, `DatedString`, and `DatedBytes` apis are now
  gone, since timestamps are no longer used by package:build. Instead the
  `InMemoryAssetReader` and other apis take a `Map<AssetId, dynamic>`, and will
  automatically convert any `String` values into  `List<int>` values.
- **Breaking**: The `outputs` map of `testBuilder` works a little bit
  differently due to the removal of `DatedValue` and `DatedString`.
  * If a value provided is a `String`, then the asset is by default decoded
    using UTF8, and matched against the string.
  * If the value is a `matcher`, it will match againt the actual bytes of the
    asset (in `List<int>` form).
  * A new matcher was added, `decodedMatches`, which can be combined with other
    matchers to match against the string contents. For example, to match a
    string containing a substring, you would do
    `decodedMatches(contains('some substring'))`.

## 0.8.0

- `InMemoryAssetReader`, `MultiAssetReader`, `StubAssetReader` and
  `PackageAssetReader` now implement the `MultiPackageAssetReader` interface.
- `testBuilder` now supports `Builder`s that call `findAssets` in non-root
  packages.
- Added a `GlobbingBuilder` which globs files in a package.
- Added the `RecordingAssetReader` interface, which adds the
  `Iterable<AssetId> get assetsRead` getter.
- `InMemoryAssetReader` now implements `RecordingAssetReader`.
- **Breaking**: The `MultiAssetReader` now requires all its wrapped readers to
  implement the `MultiPackageAssetReader` interface.
  - This should not affect most users, since all readers provided by this
    package now implement that interface.

## 0.7.1

- Add `mapAssetIds` argument to `checkOutputs` for cases where the logical asset
  location recorded by the builder does not match the written location.

- Add `recordLogs`, a top-level function that invokes `scopeLog` and captures
  the resulting `Stream<LogRecord>` for testing. Can be used with the provided
  `anyLogOf`, `infoLogOf`, `warningLogOf`, `severeLogOf` matchers in order to
  test a build process:

```dart
test('should log "uh oh!"', () async {
  final logs = recordLogs(() => runBuilder());
  expect(logs, emitsInOrder([
    anyLogOf('uh oh!'),
  ]);
});
```

- Add the constructors `forPackages` and `forPackageRoot` to
  `PackageAssetReader` - these are convenience constructors for pointing to a
  small set of packages (fake or real) for testing purposes. For example:

```dart
test('should resolve multiple libraries', () async {
  reader = new PackageAssetReader.forPackages({
    'example_a': '_libs/example_a',
    'example_b': '_libs/example_b',
  });
  expect(await reader.canRead(fileFromExampleLibA), isTrue);
  expect(await reader.canRead(fileFromExampleLibB), isTrue);
  expect(await reader.canRead(fileFromExampleLibC), isFalse);
});
```

## 0.7.0+1

- Switch to a typedef from function type syntax for compatibility with older
  SDKs.

## 0.7.0

- **Breaking**: `resolveSource` and `resolveAsset` now take an `action` to
  perform with the Resolver instance.

## 0.6.4+1

- Allow `package:build_barback` v0.4.x

## 0.6.4

- Allow `package:build` v0.10.x
- `AssetReader` implementations always return `Future` from `canRead`

## 0.6.3

- Added `resolveAsset`, which is similar to `resolveSource` but specifies a
  real asset that lives on the file system. For example, to resolve the main
  library of `package:collection`:

```dart
var pkgCollection = new AssetId('collection', 'lib/collection.dart');
var resolver = await resolveAsset(pkgCollection);
// ...
```

- Supports `package:build_barback >=0.2.0 <0.4.0`.

## 0.6.2

- Internal version bump.

## 0.6.1

- Declare an output extension in `_ResolveSourceBuilder` so it is not skipped

## 0.6.0

- Support build 0.9.0
  - Rename `hasInput` to `canRead` in `AssetReader` implementations
  - Replace `declareOutputs` with `buildExtensions` in `Builder` implementations
- **Breaking** `CopyBuilder` no longer has an `outputPackage` field since outputs
  can only ever be in the same package as inputs.

## 0.5.2

- Add `MultiAssetReader` to the public API.

## 0.5.1

- Add `PackageAssetReader`, a standalone asset reader that uses a
  `PackageResolver` to map an `AssetId` to a location on disk.
- Add `resolveSource`, a top-level function that can resolve arbitrary Dart
  source code. This can be useful in testing your own code that uses a
  `Resolver` to do type checks.

## 0.5.0

- Add `findAssets` implementations to StubAssetReader an InMemoryAssetReader
- **BREAKING**: InMemoryAssetReader constructor uses named optional parameters

## 0.4.1

- Make `scopeLog` visible so tests can be run with an available `log` without
  going through runBuilder.

## 0.4.0+1

- Bug Fix: Correctly identify missing outputs in testBuilder

## 0.4.0

Updates to work with `build` version 0.7.0.

### New Features
- The `testBuilder` method now accepts `List<int>` values for both
  `sourceAssets` and `outputs`.
- The `checkOutputs` method is now public.

### Breaking Changes
- The `testBuilder` method now requires a `RecordingAssetWriter` instead of
  just an `AssetWriter` for the `writer` parameter.
- If a `Matcher` is provided as a value in `outputs`, then it will match against
  the same value that was written. For example if your builder uses
  `writeAsString` then it will match against that string. If you use
  `writeAsBytes` then it will match against those bytes. It will not
  automatically convert to/from bytes and strings.
- Deleted the `makeAsset` and `makeAssets` methods. There is no more `Asset`
  class so these don't really have any value any more.
- The signature of `addAssets` has changed to
  `void addAssets(Map<AssetId, dynamic> assets, InMemoryAssetWriter writer)`.
  Values of the map may be either `String` or `List<int>`.
- `InMemoryAssetReader#assets` and `InMemoryAssetWriter#assets` have changed to
  a type of `Map<AssetId, DatedValue>` from a type of
  `Map<AssetId, DatedString>`. `DatedValue` has both a `stringValue` and
  `bytesValue` getter.
- `InMemoryAssetReader` and `InMemoryAssetWriter` have been updated to implement
  the new `AssetReader` and `AssetWriter` interfaces (see the `build` package
  CHANGELOG for more details).
- `InMemoryAssetReader#cacheAsset` has been changed to two separate methods,
  `void cacheStringAsset(AssetId id, String contents)` and
  `void cacheBytesAsset(AssetId id, List<int> bytes)`.
- The `equalsAsset` matcher has been removed, since there is no more `Asset`
  class.

## 0.3.1

- Additional capabilities in testBuilder:
  - Filter sourceAssets to inputs with `isInput`
  - Get log records
  - Ignore output expectations when `outputs` is null
  - Use a custom `writer`

## 0.3.0

- **BREAKING** removed testPhases utility. Tests should be using testBuilder
- Drop dependency on build_runner package

## 0.2.1

- Support the package split into build/build_runner/build_barback
- Expose additional test utilities that used to be internal to build

## 0.2.0

- Upgrade build package to 0.4.0
- Delete now unnecessary `GenericBuilderTransformer` and use
  `BuilderTransformer` in the tests.

## 0.1.2

- Add `logLevel` and `onLog` named args to `testPhases`. These can be used
  to test your log messages, see `test/utils_test.dart` for an example.

## 0.1.1

- Allow String or Matcher for expected output values in `testPhases`.

## 0.1.0

- Initial version, exposes many basic utilities for testing `Builder`s using in
  memory data structures. Most notably, the `testPhases` method.
