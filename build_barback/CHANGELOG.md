## 0.1.1

- Support the global log from `build`

## 0.1.0

Updated to reflect the new support for reading/writing as bytes in the `build`
package, and the removal of the `Asset` class.

### New Features
- `BuilderTransformer` now supports wrapping transformers that read or write
  their inputs as bytes.
- The Resolver implementation now has `isLibrary` to check whether an Asset is a
  Library and throws an exception rather than returns null on `getLibrary` when
  it isn't

### Breaking Changes
- Stopped exporting `lib/src/util/barback.dart` which contains internal only
  utilities. Specifically, the following items are no longer public (some are
  deleted entirely or had breaking changes as well):
  - `toBarbackAsset`
  - `toBarbackAssetId`
  - `toBarbackTransform`
  - `toBuildAsset`
  - `toBuildAssetId`
  - `toTransformLogger`
  - `BuildStepTransform`

## 0.0.3

- Prevent asset writing from escaping beyond the `complete()` call in
  BuildStepImpl

## 0.0.2

- Fix a bug forwarding logs from a `BuilderTransformer`

## 0.0.1

- Initial separate release - split off from `build` package.
