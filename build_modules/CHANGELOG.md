## 0.2.3-dev

- Update to the latest `package:scratch_space` and don't manually clear it out
  between builds. This provides significant speed improvements for large
  projects.

## 0.2.2+6

- Support the latest `package:build_config`.

## 0.2.2+5

- Updated the missing modules message to highlight that the error is likely due
  to a missing dependency.

## 0.2.2+4

- Support `package:analyzer` `0.32.0`.

## 0.2.2+3

- Fix a race condition where we could fail to find the modules for some
  dependencies.

## 0.2.2+2

- Fix an issue where modules were unnecessarily being built with DDC.
  [#1375](https://github.com/dart-lang/build/issues/1375).

## 0.2.2+1

- Fix an issue with new files causing subsequent build failures
  [#1358](https://github.com/dart-lang/build/issues/1358).
- Expose `MetaModuleCleanBuilder` and `metaModuleCleanExtension` publicly for
  usage in tests and manual build scripts.

## 0.2.2

- Clean up `.module` and summary files from the output and server.
- Add new `ModuleBuilder` strategies. By default the `coarse` strategy is used
  for all non-root packages and will create a minimum number of modules. This
  strategy can not be overridden. However, for the root package, the `fine`
  strategy will be used which creates a module for each strongly
  connected component. You can override this behavior by providing `coarse`
  to the `strategy` option.

  Example configuration:

  ```yaml
  targets:
    $default:
      builders:
        build_modules|modules:
          options:
            strategy: coarse
  ```

## 0.2.1

- Give a guaranteed reverse dependency order for
  `Module.computeTransitiveDependencies`

## 0.2.0+2

- Fix use of `whereType` in `MissingModulesException`,
  https://github.com/dart-lang/build/issues/1123.

## 0.2.0+1

- Fix null pointer error in `MissingModulesException`,
  https://github.com/dart-lang/build/issues/1092.

## 0.2.0

- `computeTransitiveDependencies` now throws a `MissingModulesException` instead
  of logging a warning if it discovers a missing module.

## 0.1.0+2

- Fix a bug with the dart2js workers where the worker could hang if you try to
  re-use it after calling `terminateWorkers`. This only really surfaces in test
  environments.

## 0.1.0+1

- Fix a bug with imports to libraries that have names starting with `dart.`

## 0.1.0

- Split from `build_web_compilers`.
