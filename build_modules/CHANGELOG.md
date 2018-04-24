# 0.2.2

- Add new `ModuleBuilder` strategies. By default the `coarse` strategy is used
  for all non-root packages and will create a minimum number of modules. This
  strategy can not be overridden. However, for the root package, the `fine`
  strategy will be used which creates a module for each strongly
  connected component. You can override this behavior by providing `coarse`
  to the `strategy` option.

  Example configuration:
  ```
  targets:
  $default:
    builders:
      build_modules|modules:
        options:
          strategy: coarse
  ```

# 0.2.1

- Give a guaranteed reverse dependency order for
  `Module.computeTransitiveDependencies`

# 0.2.0+2

- Fix use of `whereType` in `MissingModulesException`,
  https://github.com/dart-lang/build/issues/1123.

# 0.2.0+1

- Fix null pointer error in `MissingModulesException`,
  https://github.com/dart-lang/build/issues/1092.

# 0.2.0

- `computeTransitiveDependencies` now throws a `MissingModulesException` instead
  of logging a warning if it discovers a missing module.

# 0.1.0+2

- Fix a bug with the dart2js workers where the worker could hang if you try to
  re-use it after calling `terminateWorkers`. This only really surfaces in test
  environments.

# 0.1.0+1

- Fix a bug with imports to libraries that have names starting with `dart.`

# 0.1.0

- Split from `build_web_compilers`.
