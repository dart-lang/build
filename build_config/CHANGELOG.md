## 0.3.1+4

- Support the latest `package:json_annotation`.

## 0.3.1+3

- Support `package:build` version `1.x.x`.

## 0.3.1+2

- Support `package:json_annotation` v1.

## 0.3.1+1

- Increased the upper bound for the sdk to `<3.0.0`.

## 0.3.1

- Improve validation and errors when parsing `build.yaml`.
- Add `BuildConfig.globalOptions` support.

## 0.3.0

- Parsing of `build.yaml` files is now done with the `json_serializable` package
  and is Dart 2 compatible.

  - The error reporting will be a bit different, but generally should be better,
    and will include the yaml spans of the problem sections.

### Breaking Changes

There are no changes to the `build.yaml` format, the following changes only
affect the imperative apis of this package.

- The Constructors for most of the build config classes other than `BuildConfig`
  itself now have to be ran inside a build config zone, which can be done using
  the `runInBuildConfigZone` function. This gives the context about what package
  is currently being parsed, as well as what the default dependencies should be
  for targets.
- Many constructor signatures have changed, for the most part removing the
  `package` parameter (it is now read off the zone).

## 0.2.6+2

- Restore error for missing default target.

## 0.2.6+1

- Restore error for missing build extensions.

## 0.2.6

- The `target` and `build_extensions` keys for builder definitions are now
  optional and should be omitted in most cases since they are currently unused.
- Support options based on mode, add `devOptions` and `releaseOptions` on
  `TargetBuilderConfig`.
- Support applying default options based on builder definitions, add `option`,
  `devOptions`, and `releaseOptions` to `TargetBuilderConfigDefaults`.
- Ensure that `defaults` and `generateFor` fields are never null.
- Add `InputSet.anything` to name the input sets that don't filter out any
  assets.

## 0.2.5

- Added `post_process_builders` section to `build.yaml`. See README.md for more
  information.-dev
- Adds support for `$default` as a _dependency_, i.e.:

```yaml
targets:
  $default:
    ...
  foo:
    dependencies:
      - $default
```

## 0.2.4

- Add support for `runs_before` in `BuilderDefinition`.

## 0.2.3

- Expose key normalization methods publicly, these include:
  - `normalizeBuilderKeyUsage`
  - `normalizeTargetKeyUsage`

## 0.2.2+1

- Expand support for `package:build` to include version `0.12.0`.

## 0.2.2

- **Bug fix**: Empty build.yaml files no longer fail to parse.
- Allow `$default` as a target name to get he package name automatically filled
  in.

## 0.2.1

- Change the default for `BuilderDefinition.buildTo` to `BuildTo.cache`.
  Builders which want to operate on the source tree will need to explicitly opt
  in. Allow this regardless of the value of `autoApply` and the build system
  will need to filter out the builders that can't run.
- By default including any configuration for a Builder within a BuildTarget will
  enabled that builder.

## 0.2.0

- Add `build_to` option to Builder configuration.
- Add `BuildConfig.fromBuildConfigDir` for cases where the package name and
  dependencies are already known.
- Add `TargetBuilderConfig` class to configure builders applied to specific
  targets.
- Add `TargetBuilderConfigDefaults` class for Builder authors to provide default
  configuration.
- Add `InputSet` and change `sources` and `generate_for` to use it.
- Remove `BuildTarget.isDefault` and related config parsing. The default will be
  determined by the target which matches the package name.
- Normalize Target and Builder names so they are scoped to the package they are
  defined in.

### Breaking

- Remove `BuildConfigSet` class. This was unused.
- Hide `Pubspec` class. Construct `BuildConfig` instances with a package path
  rather than an already created `Pubspec` instance.

## 0.1.1

- Add `auto_apply` option to Builder configuration.
- Add `required_inputs` option to Builder configuration.
- Add `is_optional` option to Builder configuration.

## 0.1.0

- Initial release - pulled from `package:dazel`. Updated to support
  `build_extensions` instead of `input_extension` and `output_extensions`.
