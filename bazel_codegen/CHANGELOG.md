# 0.3.1+1

- Expand constraint on `package:build` to allow version `0.12.x`

# 0.3.1

- Correct expected outputs when running builders taking disjoint input
  extensions.

# 0.3.0

## Breaking Changes

- Drop `BuilderFactory` in favor of the typedef from `package:build`. The
  factories now take a `BuilderOptions` argument rather than `List<String>`.

# 0.2.1

- Update to build 0.11.0, update interface for `findAssets`.

# 0.2.0

- **Breaking**: CLI argument change: Replace `in-extension` and `out-extensions`
  with `build-extensions`.

# 0.1.7

- Upgrade to `package:build` v0.10

# 0.1.6

- Allow 'side' outputs from a builder. When multiple builders are chained the
  inputs to builders are no longer limited to only the outputs from the previous
  builder.

# 0.1.5

- Support for build 0.9.0

# 0.1.4

- Add a `toString()` on AssetSource.
- Run analysis in Strong mode when using summaries

# 0.1.3

- Upgrade to build 0.8.0, implement findAssets api

# 0.1.2

- Give priority to reading inputs directly rather than resolving through a
  summary if they are duplicated.

# 0.1.1

- Throw an exception when attempting to do resolution on an input file that is
  also included in a dependency when using summaries.

# 0.1.0

- Wrap generation in Chain.capture and print full asynchronous stack traces
- **BREAKING** `bazelGenerate` and `noArgs` have been dropped. These are unused
  from the template file in `rules_dart` which is the supported approach.

# 0.0.3

- Only read '.dart' files as sources for the Resolver. This avoids a problem
  trying to read binary assets as if they were strings. Poorly encoded .dart
  files can still cause an error - but this case we'd expect to fail.
- Fix a bug where failure to read an asset during the Resolvers.get call would
  cause the entire process to hang.
- Rely on the print capturing from package:build

# 0.0.2

- Bug fix: Correct the import after library was renamed with a leading
  underscore.
