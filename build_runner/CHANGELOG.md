## 0.2.0-dev

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
