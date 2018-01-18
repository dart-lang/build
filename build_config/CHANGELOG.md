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
