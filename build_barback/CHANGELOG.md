## 0.1.0-dev

Updated to reflect the new support for reading/writing as bytes in the `build`
package, and the removal of the `Asset` class.

### New Features
- `BuilderTransformer` now supports wrapping transformers that read or write
  their inputs as bytes.
- Added `barbackAssetFromBytes` and `backbackAssetFromString` methods to replace
  `toBarbackAsset`.

### Breaking Changes
- `toBuildAsset` and `toBarbackAsset` no longer exists since there is no `Asset`
  class any longer in the `build` package.

## 0.0.3

- Prevent asset writing from escaping beyond the `complete()` call in
  BuildStepImpl

## 0.0.2

- Fix a bug forwarding logs from a `BuilderTransformer`

## 0.0.1

- Initial separate release - split off from `build` package.
