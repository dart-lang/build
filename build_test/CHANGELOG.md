## 0.6.0-dev

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
