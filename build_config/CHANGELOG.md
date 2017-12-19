## 0.2.0-dev

- Add `build_to` option to Builder configuration.
- Add `BuildConfig.fromBuildConfigDir` for cases where the package name and
  dependencies are already known.
- Add `TargetBuilderConfig` class to configure builders applied to specific
  targets.
- Add `TargetBuilderConfigDefaults` class for Builder authors to provide default
  configuration.
- Add `InputSet` and change `sources` and `generate_for` to use it.

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
