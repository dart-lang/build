## 1.1.1

### Bug Fix

Check the analyzer path before reading cached summaries in addition to the
SDK version.

## 1.1.0

### Bug Fix: #38499

Update the `AnalysisResolvers` class to no longer use the SDK summary that is
shipped with the SDK by default. This is not guaranteed compatible with
analyzer versions shipped on pub and should not be used by any non-sdk code.

In order to fix this the `AnalysisResolvers` class now takes an optional method
that returns the path to an arbitrary SDK summary. By default it will lazily
generate a summary under `.dart_tool/build_resolvers` which is invalidated
based on the `Platform.version` from `dart:io`.

## 1.0.8

- Allow `build` version 1.2.x.

## 1.0.7

- Allow analyzer version 0.38.0.

## 1.0.6

- Allow analyzer version 0.37.0.

## 1.0.5

- Fix a race condition where some assets may be resolved with missing
  dependencies. This was likely to have only manifested in tests using
  `resolveSource`.

## 1.0.4

- Increase lower bound sdk constraint to 2.1.0.
- Increased the upper bound for `package:analyzer` to `<0.37.0`.

## 1.0.3

- Fixes a bug where transitive `dart-ext:` imports would cause the resolver
  to fail. These uris will now be ignored.

## 1.0.2

- Ensure that `BuildAssetUriResolver.restoreAbsolute` never returns null.
  - Fixes a crash when a resolver is requested but not all transitive sources
    are available yet.

## 1.0.1

- Fix a bug causing crashes on windows.

## 1.0.0

- Migrate to `AnalysisDriver`. There are behavior changes which may be breaking.
  The `LibraryElement` instances returned by the resolver will now:
  - Have non-working `context` fields.
  - Have no source offsets for annotations or their errors.
  - Have working `session` fields.
  - Have `Source` instances with different URIs than before.
  - Not include missing libraries in the `importedLibraries` getter. You can
    instead use the `imports` getter to see all the imports.

## 0.2.3

- Update to `build` `1.1.0` and add `assetIdForElement`.

## 0.2.2+7

- Updated _AssetUriResolver to prepare for a future release of the analyzer.
- Increased the upper bound for `package:analyzer` to `<0.35.0`.

## 0.2.2+6

- Increased the upper bound for `package:analyzer` to `<0.34.0`.

## 0.2.2+5

- Increased the upper bound for the `build` to `<1.1.0`.

## 0.2.2+4

- Removed dependency on cli_util.
- Increased the upper bound for the `build` to `<0.12.9`.

## 0.2.2+3

- Don't log a severe message when a URI cannot be resolved. Just return `null`.

## 0.2.2+2

- Use sdk summaries for the analysis context, which makes getting the initial
  resolver faster (reapplied).

## 0.2.2+1

- Restore `new` keyword for a working release on Dart 1 VM.

## 0.2.2

- Use sdk summaries for the analysis context, which makes getting the initial
  resolver faster.
- Release broken on Dart 1 VM.

## 0.2.1+1

- Increased the upper bound for the sdk to `<3.0.0`.

## 0.2.1

- Allow passing in custom `AnalysisOptions`.

## 0.2.0+2

- Support `package:analyzer` `0.32.0`.

## 0.2.0+1

- Switch to `firstWhere(orElse)` for compatibility with the SDK dev.45

## 0.2.0

- Removed locking between uses of the Resolver and added a mandatory `reset`
  call to indicate that a complete build is finished.

## 0.1.1

- Support the latest `analyzer` package.

## 0.1.0

- Initial release as a migration from `code_transformers` with a near-identical
  implementation.
