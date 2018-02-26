- Dart2JS now has minification (`--minify`) enabled by default, similar to how
  it worked in `pub build`. If you are adding custom `dart2js` options, make
  sure you still keep the `--minify` flag. Here is an example:

```yaml
targets:
  $default:
    builders:
      build_web_compilers|entrypoint:
        generate_for:
        - web/**.dart
        options:
          compiler: dart2js
          dart2js_args:
          - --fast-startup
          - --minify
          - --trust-type-annotations
          - --trust-primitives
```

# 0.3.1

- Cast failures will now be ignored in dartdevc by default (these were enabled
  in the latest sdk), and added an `ignore_cast_failures` option to the
  `build_web_compilers|entrypoint` builder which you can set to `true` to enable
  them.
  - At some point in the future it is expected that the default for this will
    flip.

# 0.3.0+1

- Fixed an issue with `dart2js` and the `--no-source-maps` flag.

# 0.3.0

## Breaking changes

- Split `ModuleBuilder`, `UnlinkedSummaryBuilder` and `LinkedSummaryBuilder`
  into a separate `build_modules` package.

# 0.2.1+1

- Support the latest `analyzer` package.

# 0.2.1

- All dart files under `test` are now compiled by default instead of only the
  `_browser_test.dart` files (minus vm/node test bootstrap files). This means
  the original tests can be debugged directly (prior to package:test
  bootstrapping).
- Updated to `package:build` version `0.12.0`.

# 0.2.0

## New Features

- Added support for `dart2js`. This can be configured using the top level
  `compiler` option for the `build_web_compilers|entrypoint` builder. The
  supported options are `dartdevc` (the default) and `dart2js`. Args can be
  passed to `dart2js` using the `dart2js_args` option. For example:

```yaml
targets:
  <my_package>:
    builders:
      build_web_compilers|entrypoint:
        options:
          compiler: dart2js
          dart2js_args:
          - --minify
```

## Breaking Changes

- Renamed `ddc_bootstrap` builder to `entrypoint`, the exposed class also
  changed from `DevCompilerBootstrapBuilder` to `WebEntrypointBuilder`.
- Renamed `jsBootstrapExtension` to `ddcBootstrapExtension` since it is only
  required when using the dev compiler.

# 0.1.1

- Mark `ddc_bootstrap` builder with `build_to: cache`.
- Publish as `build_web_compilers`

# 0.1.0

- Add builder factories.
- Fixed temp dir cleanup bug on windows.
- Enabled support for running tests in --precompiled mode.

# 0.0.1

- Initial release with support for building analyzer summaries and DDC modules.
