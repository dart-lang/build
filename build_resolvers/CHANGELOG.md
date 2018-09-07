## 0.2.2+4-dev

- Removed dependency on cli_util.

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
