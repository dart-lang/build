# Changelog

## 0.2.0
- Updated the top level classes to take a `PhaseGroup` instead of a
  `List<List<Phase>>`.
- Added logic to handle nested package directories.
- Basic windows support added, although it may still be unstable.
- Significantly increased the resolving speed by using the same sources cache.
- Added a basic README.
- Moved the `.build` folder to `.dart_tool/build`. Other packages in the future
  may also use this folder.

## 0.1.4
- Added top level `serve` function.
  - Just like `watch`, but it provides a server which blocks on any ongoing
    builds before responding to requests.
- Minor bug fixes.

## 0.1.3
- Builds are now fully incremental, even on startup.
  - Builds will be invalidated if the build script or any of its dependencies
    are updated since there is no way of knowing how that would affect things.
- Added `lastModified` to `AssetReader` (only matters if you implement it).

## 0.1.2
- Exposed the top level `watch` function. This can be used to watch the file
  system and run incremental rebuilds on changes.
  - Initial build is still non-incremental.

## 0.1.1

- Exposed the top level `build` function. This can be used to run builds.
  - For this release all builds are non-incremental, and delete all previous
    build outputs when they start up.
  - Creates a `.build` directory which should be added to your `.gitignore`.
- Added `resolve` method to `BuildStep` which can give you a `Resolver` for an
  `AssetId`.
  - This is experimental and may get moved out to a separate package.
  - Resolves the full dart sdk so this is slow, first call will take multiple
    seconds. Subsequent calls are much faster though.
  - Will end up marking all transitive deps as dependencies, so your files may
    end up being recompiled often when not entirely necessary (once we have
    incremental builds).
- Added `listAssetIds` to `AssetReader` (only matters if you implement it).
- Added `delete` to `AssetWriter` (also only matters if you implement it).

## 0.1.0

- Initial version
