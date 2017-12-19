# Customizing builds

Customizing the build behavior of a package is done  by creating a `build.yaml`
file, which describes your configuration.

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
    subset of the corresponding target.

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
