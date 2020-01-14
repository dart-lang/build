## 0.0.4+3-dev

- Change returns from `Future<dynamic>` to `Future<void>`.

## 0.0.4+2

- Fix a race condition bug where `ensureAssets` would complete before all
  pending writes were completed. If the next build was scheduled before these
  writes finished then they would get the old result.

## 0.0.4+1

- Fix `ScratchSpace.fileFor` on windows to normalize the paths so they dont
  contain mixed separators.

## 0.0.4

- Add `requireContent` argument to `copyOutput` to allow asserting that a file
  produced in a scratch space is not empty.

## 0.0.3+2

- Declare support for `package:build` version `1.x.x`.

## 0.0.3+1

- Increased the upper bound for the sdk to `<3.0.0`.

## 0.0.3

- Use digests to improve `ensureAssets` performance.
  - Scratch spaces can now be used across builds without cleaning them up, and
    will check digests and update assets as needed.

## 0.0.2+1

- Fix a bug where failing to read an asset in serve mode could get the build
  stuck.

## 0.0.2

- Allow creating files at the root of the scratch space.

## 0.0.1+3

- Allow package:build 0.12.0

## 0.0.1+2

- Allow package:build 0.11.0

## 0.0.1+1

- Fix a deadlock issue around the file descriptor pool, only take control of a
  resource right before actually touching disk instead of also encapsulating
  the `readAsBytes` call from the wrapped `AssetReader`.

## 0.0.1

- Initial release, adds the `ScratchSpace` class.
