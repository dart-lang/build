## 1.0.7+2

- Update `dart2js` snapshot arguments for upcoming SDK. 

## 1.0.7+1

- Fix broken release by updating `dart2js` worker and restricting sdk version. 

## 1.0.7

- Explicitly skip dart-ext uris during module creation.
  - Filed Issue #2047 to track real support for native extensions.
- Run workers with mode `detachedWithStdio` if no terminal is connected. 

## 1.0.6

- Improved the time tracking for kernel and analyzer actions by not reporting
  time spent waiting for a worker to be available.

## 1.0.5

- Increased the upper bound for `package:analyzer` to `<0.36.0`.

## 1.0.4

- Update to `package:graphs` version `0.2.0`.
- Use `dartdevc --kernel` instead of `dartdevk`.

## 1.0.3

- Increased the upper bound for `package:analyzer` to `<0.35.0`.

## 1.0.2

- Support the latest `package:json_annotation`.

## 1.0.1

- Increased the upper bound for `package:analyzer` to '<0.34.0'.

## 1.0.0

### Breaking Changes

- The `Module` constructor has an additional required parameter `isSupported`,
  which indicates if a module is supported on that module's platform.

## 0.4.0

### Improvements

- Modules are now platform specific, and config specific imports using
  `dart.library.*` constants are supported.

### Breaking Configuration Changes

- Module granularity now has to be configured per platform, so instead of
  configuring it using the `build_modules|modules` builder, you now need to
  configure the builder for each specific platform:

```yaml
targets:
  $default:
    build_modules|dartdevc:
      options:
        strategy: fine
```

  The supported platforms are currently `dart2js`, `dartdevc`, `flutter`, and
  `vm`.

### Breaking API Changes

- Output extensions of builders have changed to include the platform being built
  for.
  - All the top level file extension getters are now methods that take a
    platform and return the extension for that platform.
- Most builders are no longer applied by default, you must manually apply them
  using applies_builders in your builder.
- Most builder constructors now require a `platform` argument.

## 0.3.2

- Module strategies are now respected for all packages instead of just the root
  package.
- Can now mix and match fine and coarse strategies at will, even within package
  cycles (although this may cause larger modules).
- Removed analyzer dependency.

## 0.3.1+1

- Support `package:json_annotation` v1.

## 0.3.1

- Change the default module strategy for the root package to `coarse`.

## 0.3.0

### Improvements

- Updated dart2js support so that it can do multiple builds concurrently and
  will restart workers periodically to mitigate the effects of
  dart-lang/sdk#33708.
- Increased the upper bound for the sdk to `<3.0.0`.

### Breaking Changes

- Removed the `kernelSummaryExtension`, and renamed the `KernelSummaryBuilder`
  to `KernelBuilder`. The new builder can be used to create summaries or full
  kernel files, and requires users to give it a custom sdk.
- Changed `metaModuleCleanBuilder` to read `.module.library` files which are
  produced by the `moduleLibrayBuilder`. Clients using the automatically
  generated build script will get this automatically. Clients which have
  manually written build scripts will need to add it.

## 0.2.3

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
