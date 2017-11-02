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
