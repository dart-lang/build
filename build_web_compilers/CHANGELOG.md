## 2.2.0

- Make `librariesPath` configurable in `DevCompilerBuilder`.

## 2.1.5

- Add pre-emptive support for an upcoming breaking change in ddc
  around entrypoint naming.

## 2.1.4

- Allow analyzer version 0.37.0.

## 2.1.3

- Improve error message when `dart2js_args` is configured improperly.

## 2.1.2

- Fix hot restart bootstrapping logic for dart scripts that live in a
  different directory than the html file.

## 2.1.1

- Prepare for source map change from dartdevc, don't modify relative paths in
  source maps.
- Fix hot reload bootstrap logic for app entrypoints under lib.

## 2.1.0

- Make `platformSdk`, `sdkKernelPath`, and `platform` configurable in
  `DevCompilerBuilder`.

## 2.0.2

- Prepare for the next sdk release, which changes what the uris look like for
  non-package sources, and breaks our existing hot restart logic.

## 2.0.1

- Fix issue #2269, which could cause applications to fail to properly bootstrap.
- Skip compiling modules with ddc when the primary source isn't the primary
  input (only shows up in non-lazy builds - essentially just tests).

## 2.0.0

### Major Update - Switch to use the common front end.

In this release, the Dart front end for the `dev_compiler` is changing from the
[analyzer] to the common [front end][front_end]. This should unify error
messages and general consistency across platforms, as this was one of the last
compilers left still using the analyzer as a front end.

While this is intended to be a transparent change, it is likely that there will
be unintended differences. Please [file issues][issue tracker] if you experience
something that seems broken or not working as intended.

### Major Update - Auto-detection of web support for applications

Previously, all files with a `main` that were matched by the input globs would
attempt to compile for the web. This caused an issue when there were non-web
applications in the default directories, which specifically happens a lot in the
`test` directory. Resolving this required custom globs in `build.yaml` files.

Two changes were made to help handle this issue more gracefully, in a way that
often doesn't require custom `build.yaml` files any more.

- Before compiling any app, build_web_compilers will check that all its
  transitive modules are compatible with the web (based on their `dart:`
  imports).
  - Today we will log a warning message for any app that isn't compatible, as
    ultimately it is most efficient to exclude these using globs in your
    `build.yaml` than waiting for us to detect it. This may change based on
    feedback.
- Changed the default glob for the `test` directory to only include the
  `test/**.dart.browser_test.dart` files (other dirs remain unchanged).
  - Note that as a result of this, serving the `test` dir and running tests that
    way no longer works, as those entrypoints won't be compiled. You would need
    to configure the `generate_for` to explicitly include `test/**_test.dart`
    to restore that functionality (we will continue pushing on this in the
    future though to restore similar functionality).
  - Also note that the `build_test` package will now output
    `<platform>_test.dart` files based on your [TestOn] annotations, so using
    those where possible will help reduce build platform support warnings as
    well.

### Additional Notes

- Update to run DDC in kernel mode, and consume kernel outlines instead of
  analyzer summaries.
- Skip trying to compile apps that import known incompatible libraries.
- Increased the upper bound for `package:analyzer` to `<0.37.0`.
- Removed support for `build_root_app_summary` configuration option.
- Combine the `ddc_kernel` and `ddc` workers under a single name (`ddc`).
- By default only `.dart.browser_test.dart` files will be compiled under the
  `test` directory, instead of all `_test.dart` files.
  - If you used the previous test debugging workflow in the browser you can
    restore the old behavior with something like the following in your
    build.yaml:

```yaml
targets:
  $default:
    builders:
      build_web_compilers|entrypoint:
        generate_for:
        - test/**_test.dart
        - web/**.dart
```

- Added the `use-incremental-compiler` option for the `build_web_compilers:ddc`
  builder. This is enabled by default but can be disabled if running into build
  issues by setting it to `false` globally:

```yaml
global_options:
  build_web_compilers:ddc:
    options:
      use-incremental-compiler: false
```

- This package now makes its own copy of the `dart_sdk.js` and `require.js`
  files, which it deletes during production builds.
  - In a future build_runner release we will be deleting the entire `$sdk`
    package to resolve some issues with build output bloat.
  - If you are using `dartdevc` as your production compiler, you will need to
    disable the cleanup builder in `build.yaml` (globally) like this:

```yaml
global_options:
  build_web_compilers|sdk_js_cleanup:
    release_options:
      enabled: false
```

[analyzer]: https://pub.dev/packages/analyzer
[front_end]: https://pub.dev/packages/front_end
[issue tracker]: https://github.com/dart-lang/build/issues/new
[TestOn]: https://pub.dev/documentation/test/latest/#restricting-tests-to-certain-platforms

## 1.2.2

- Allow build_config 0.4.x.

## 1.2.1

- Allow analyzer version 0.36.x.

## 1.2.0

- Add a marker to inject code before the application main method is called.
- During a hot restart we will now clear all statics before re-invoking main.

## 1.1.0

- Output a `.digests` file which contains transitive digests for an entrypoint.

## 1.0.2

- Improved the time tracking for ddc actions by not reporting time spent waiting
  for a worker to be available.

## 1.0.1

- Increased the upper bound for `package:analyzer` to `<0.36.0`.

## 1.0.0

- Removed the `enable_sync_async` and `ignore_cast_failures` options for the
  `build_web_compilers|entrypoint` builder. These will no longer have any effect
  and will give a build time warning if you try to use them.

## 0.4.4+3

- Increased the upper bound for `package:analyzer` to `<0.35.0`.

## 0.4.4+2

- Support `package:analyzer` version `0.33.x`.

## 0.4.4+1

- Support `package:build_modules` version `1.x.x`.

## 0.4.4

- Track performance of different builder stages.

## 0.4.3+1

- Removed dependency on cli_util.
- Fix error in require.js error handling code

## 0.4.3

- Only call `window.postMessage` during initialization if the current context
  is a `Window`.
- Fixed an error while showing stack traces for DDC generated scripts
  when `<base>` tag is used.
- Value of `<base href="/.../">` tag should start and end with a `/` to be
  used as the base url for require js.
- Added more javascript code to dev bootstrap for hot-reloading support
- Support the latest build_modules.

## 0.4.2+2

- Add magic comment marker for build_runner to know where to inject
  live-reloading client code. This is only present when using the `dartdevc`
  compiler. (reapplied)

## 0.4.2+1

- Restore `new` keyword for a working release on Dart 1 VM.

## 0.4.2

- Add magic comment marker for build_runner to know where to inject
  live-reloading client code. This is only present when using the `dartdevc`
  compiler.
- Release broken on Dart 1 VM.

## 0.4.1

- Support the latest build_modules, with updated dart2js support so that it can
  do multiple builds concurrently and will restart workers periodically to
  mitigate the effects of dart-lang/sdk#33708.
- Improvements to reduce the memory usage of the dart2js builder, so that
  transitive dependency information can be garbage collected before the dart2js
  compile is completed.
- Increased the upper bound for the sdk to `<3.0.0`.

## 0.4.0+5

- Fixed an issue where subdirectories with hyphens in the name weren't
  bootstrapped properly in dartdevc.

## 0.4.0+4

- Expand support for `package:build_config` to include version `0.3.x`.

## 0.4.0+3

- Expand support for `package:archive` to include version `2.x.x`.

## 0.4.0+2

- Fix a dart2 error.

## 0.4.0+1

- Support `package:analyzer` `0.32.0`.

## 0.4.0

- Changed the default for `enable_sync_async` to `true` for the
  `build_web_compilers|entrypoint` builder.
- Changed the default for `ignore_cast_failures` to `false` for the
  `build_web_compilers|entrypoint` builder.

## 0.3.8

- Remove `.dart` sources and `.js.map` files from the output directory in
  release mode.
- Clean up `.tar.gz` outputs produced by `Dart2Js.`
- Don't output extra `Dart2Js` outputs other than deferred part files.
- Fixed a logical error in `dartdevc` compiler to detect correct base url for
  require js.
- Added a `enable_sync_async` option to the `build_web_compilers|entrypoint`
  builder, which defaults to `false`.

## 0.3.7+3

- The `dartdevc` compiler now respects the `<base href="/....">` tags and will
  set them as the base url for require js.

## 0.3.7+2

- Fix sdk stack trace folding in the browser console and package:test.

## 0.3.7+1

- Add missing dependency on the `pool` package.

## 0.3.7

- Reduce memory usage by requesting (and lazily building) lower level modules
  first when building for an entrypoint.

## 0.3.6

- Add support for compiling with `dart2js` by default in release mode.

## 0.3.5

- Don't ignore cast failures by default. We expect most code to be clean with
  cast failures, and the option can be manually enabled with config.

## 0.3.4+2

- Create `.packages` file and use the new frontend with `dart2js`.

## 0.3.4+1

- Use `--use-old-frontend` with `dart2js` as a stopgap until we can add support
  for `.packages` files.

## 0.3.4

- Added support for dart2js deferred loading.
- Added support for bootstrapping code in web workers with `dartdevc`.

## 0.3.3

- Added support for `--dump-info` and the `dart2js` compiler. If you pass that
  argument with `dart2js_args` the `.info.json` file will be copied the output.

## 0.3.2

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

## 0.3.1

- Cast failures will now be ignored in dartdevc by default (these were enabled
  in the latest sdk), and added an `ignore_cast_failures` option to the
  `build_web_compilers|entrypoint` builder which you can set to `true` to enable
  them.
  - At some point in the future it is expected that the default for this will
    flip.

## 0.3.0+1

- Fixed an issue with `dart2js` and the `--no-source-maps` flag.

## 0.3.0

### Breaking changes

- Split `ModuleBuilder`, `UnlinkedSummaryBuilder` and `LinkedSummaryBuilder`
  into a separate `build_modules` package.

## 0.2.1+1

- Support the latest `analyzer` package.

## 0.2.1

- All dart files under `test` are now compiled by default instead of only the
  `_browser_test.dart` files (minus vm/node test bootstrap files). This means
  the original tests can be debugged directly (prior to package:test
  bootstrapping).
- Updated to `package:build` version `0.12.0`.

## 0.2.0

### New Features

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

### Breaking Changes

- Renamed `ddc_bootstrap` builder to `entrypoint`, the exposed class also
  changed from `DevCompilerBootstrapBuilder` to `WebEntrypointBuilder`.
- Renamed `jsBootstrapExtension` to `ddcBootstrapExtension` since it is only
  required when using the dev compiler.

## 0.1.1

- Mark `ddc_bootstrap` builder with `build_to: cache`.
- Publish as `build_web_compilers`

## 0.1.0

- Add builder factories.
- Fixed temp dir cleanup bug on windows.
- Enabled support for running tests in --precompiled mode.

## 0.0.1

- Initial release with support for building analyzer summaries and DDC modules.
