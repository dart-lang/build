# Customizing builds

Customizing the build behavior of a package is done  by creating a `build.yaml`
file, which describes your configuration.

## Dividing a package into Build targets
When a `Builder` should be applied to a subset of files in a package the package
can be broken up into multiple 'targets'. Targets are configured in the
`targets` section of the `build.yaml`. Each target may contain the following
keys.

- **name**: String, Required. The name of the target within the package. Targets
  can be referred to by `'$packageName:$targetName'` keys. If the target has the
  same name as the package it can also be referred to as `'$packageName'`, at
  least one target must use the package name so that other packages which depend
  on this one can pick it up as a dependency.
- **sources**: List of Strings or Map, Optional. The set of files within the
  package which make up this target. Files are specified using glob syntax. If a
  List of Strings is used they are considered the 'include' globs. If a Map is
  used can only have the keys `include` and `exclude`. Any file which matches
  any glob in `include` and no globs in `exclude` is considered a source of the
  target. When `include` is omitted every file is considered a match.
- **dependencies**: List of Strings, Optional. The targets that this target
  depends on. Strings in the format `'$packageName:$targetName'` to depend on a
  target within a package or `$packageName` to depend on a package's default
  target. By default this is all of the package names this package depends on
  (from the `pubspec.yaml`).
- **builders**: Map, Optional. See "configuring builders" below.

## Configuring `Builder`s applied to your package
Each target can specify a `builders` key which configures the builders which are
applied to that target. The value is a Map from builder to configuration for
that builder. The key is in the format `'$packageName|$builderName'`. The
configuration may have the following keys:

- **enabled**: Boolean, Optional: Whether to apply the builder to this target.
  Omit this key if you want the default behavior based on the builder's
  `auto_apply` configuration. Builders which are manually applied
  (`auto_apply: none`) are only ever used when there is a target specifying the
  builder with `enabled: True`.
- **generate_for**: List of String or Map, Optional:. The subset of files within
  the target's `sources` which should have this Builder applied. See `sources`
  configuration above for how to configure this.
- **options**: Map, Optional: A free-form map which will be passed to the
  `Builder` as a `BuilderOptions` when it is constructed. Usage varies depending
  on the particular builder.

## Defining `Builder`s to apply to dependents (similar to transformers)

If users of your package need to apply some code generation to their package,
then you can define `Builder`s and have those applied to packages with a
dependency on yours.

Exposed `Builder`s are configured in the `builders` section of the `build.yaml`.
This is a map of builder names to configuration. Each builder config may contain
the following keys:

- **target**: The name of the target which defines contains the `Builder` class
  definition.
- **import**: Required. The import uri that should be used to import the library
  containing the `Builder` class. This should always be a `package:` uri.
- **builder_factories**: A `List<String>` which contains the names of the
  top-level methods in the imported library which are a function fitting the
  typedef `Builder factoryName(List<String> args)`.
- **build_extensions**: Required. A map from input extension to the list of
  output extensions that may be created for that input. This must match the
  merged `buildExtensions` maps from each `Builder` in `builder_factories`.
- **auto_apply**: Optional. The packages which should have this builder
  automatically to applied. Defaults to `'none'` The possibilities are:
  - `"none"`: Never apply this Builder unless it is manually configured
  - `"dependents"`: Apply this Builder to the package with a direct dependency
    on the package exposing the builder.
  - `"all_packages"`: Apply this Builder to all packages in the transitive
    dependency graph.
  - `"root_package"`; Apply this Builder only to the top-level package.
- **required_inputs**: Optional, list of extensions. If a Builder must see every
  input with one or more file extensions they can be specified here and it will
  be guaranteed to run after any Builder which might produce an output of that
  type. For instance a compiler must run after any Builder which can produce
  `.dart` outputs or those libraries can't be compiled. This option should be
  rare. Defaults to an empty list.
- **is_optional**: Optional, boolean. Specifies whether a Builder can be run
  lazily, such that it won't execute until one of it's outputs is requested by a
  later Builder. This option should be rare. Defaults to `False`.
- **build_to**: Optional. The location that generated assets should be output
  to. The possibilities are:
  - `"source"`: Outputs go to the source tree next to their primary inputs.
  - `"cache"`: Outputs go to a hidden build cache and won't be published.
  Only builders which output to the build cache may run on primary inputs
  outside the root package. Defaults to `"source"`, unless `auto_apply` is set
  to either `"all_packages"` or `"dependents"` in which case it defaults to
  `"cache"`.
- **defaults**: Optional: Default values to apply when a user does not specify
  the corresponding key in their `builders` section. May contain the following
  keys:
  - **generate_for**: A list of globs that this Builder should run on as a
    subset of the corresponding target, or a map with `include` and `exclude`
    lists of globs.

Example `builders` config:

```yaml
targets:
  # The target containing the builder sources.
  _my_builder: # By convention, this is private
    sources:
      - "lib/src/builder/**/*.dart"
      - "lib/builder.dart"
    dependencies:
      - "build"
      - "source_gen"
builders:
  # The actual builder config.
  my_builder:
    target: ":_my_builder"
    import: "package:my_package/builder.dart"
    builder_factories: ["myBuilder"]
    build_extensions: {".dart": [".my_package.dart"]}
    auto_apply: dependents
```
