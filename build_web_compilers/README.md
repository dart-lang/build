<p align="center">
  Web compilers for users of <a href="https://pub.dev/packages/build"><code>package:build</code></a>.
  <br>
  <a href="https://github.com/dart-lang/build/labels/package%3Abuild_web_compilers">
    <img src="https://img.shields.io/github/issues-raw/dart-lang/build/package%3Abuild_web_compilers.svg" alt="Issues related to build_web_compilers" />
  </a>
  <a href="https://pub.dev/packages/build_web_compilers">
    <img src="https://img.shields.io/pub/v/build_web_compilers.svg" alt="Pub Package Version" />
  </a>
  <a href="https://pub.dev/documentation/build_web_compilers/latest">
    <img src="https://img.shields.io/badge/dartdocs-latest-blue.svg" alt="Latest Dartdocs" />
  </a>
  <a href="https://gitter.im/dart-lang/build">
    <img src="https://badges.gitter.im/dart-lang/build.svg" alt="Join the chat on Gitter" />
  </a>
</p>

* [Installation](#installation)
* [Usage](#usage)
* [Configuration](#configuration)
* [Manual Usage](#manual-usage)

## Installation

This package is intended to be used as a [development dependency][] for users
of [`package:build`][] who want to run code in a browser. Simply add the
following to your `pubspec.yaml`:

```yaml
dev_dependencies:
  build_web_compilers:
```

## Usage

If you are using the autogenerated build script (going through
`dart run build_runner <command>` instead of handwriting a `build.dart` file),
then all you need is the `dev_dependency` listed above.

## Configuration

By default, this package uses the [Dart development compiler][] (_dartdevc_,
also known as _DDC_) to compile Dart to JavaScript. In release builds (running
the build tool with `--release`), `dart2js` is used as a compiler.

In addition to compiling to JavaScript, this package also supports compiling to
WebAssembly. Currently, `dart2wasm` needs to be enabled with builder options.
To understand the impact of these options, be aware of differences between
compiling to JavaScript and compiling to WebAssembly:

1. Dart has two compilers emitting JavaScript: `dart2js` and `dartdevc` (which
  supports incremental rebuilds but is typically only used for development).
  For both JavaScript compilers, `build_web_compilers` generates a primary
  entrypoint script and additional module files or source maps depending on
  compiler options.
2. Compiling with `dart2wasm` generates a WebAssembly module (a `.wasm` file)
   and a JavaScript module (a `.mjs` file) exporting functions to instantiate
   that module. `dart2wasm` alone generates no entrypoint file that could be
   added as a `<script>` tag.

In addition to invoking compilers, `build_web_compilers` can emit an entrypoint
file suitable for `dart2wasm`. When both `dart2wasm` and a JavaScript compiler
are enabled, the entrypoint file runs a feature detection for WasmGC and loads
either the WebAssembly module or the JavaScript file depending on what the
browser supports.

### Compiler arguments

To customize compilers, you will need to add a `build.yaml` file configuring
the `build_web_compilers:entrypoint` builder, similar to the following:

```yaml
targets:
  $default:
    builders:
      build_web_compilers:entrypoint:
        # These are globs for the entrypoints you want to compile.
        generate_for:
        - test/**.browser_test.dart
        - web/**.dart
        options:
          compilers:
            # All compilers listed here are enabled:
            dart2js:
              # List any dart2js specific args here, or omit it.
              args:
                - O2
            dart2wasm:
              args:
                - O3
```

`build_runner` runs development builds by default, but can use builders with a
different configuration for `--release` builds. For instance, if you wanted to
compile with `dartdevc` only on development and `dart2js` + `dart2wasm` for
release builds, you can use this configuration as a starting point:

```yaml
targets:
  $default:
    builders:
      build_web_compilers:entrypoint:
        generate_for:
        - test/**.browser_test.dart
        - web/**.dart
        dev_options:
          compilers:
            dartdevc:
        release_options:
          compilers:
            dart2js:
              args:
                - O2
            dart2wasm:
              args:
                - O3
```

### Customizing emitted file names

The file names emitted by `build_web_compilers` can be changed. The default
names depend on which compilers are enabled:

1. When only `dart2js` or `dartdevc` is enabled, a single `.dart.js` entrypoint
   is emitted.
2. When only `dart2wasm` is enabled, a single `.dart.js` entrypoint (loading
   a generated `.wasm` module through a `.mjs` helper file) is generated.
3. When both `dart2wasm` and a JavaScript compiler are enabled, then:
   - The output of the JavaScript compiler is named `.dart2js.js` or `.ddc.js`
     depending on the compiler.
   - `dart2wasm` continues to emit a `.wasm` and a `.mjs` file.
   - An entrypoint loader named `.dart.js` that loads the appropriate output
     depending on browser features is generated.

All names can be overridden by using the `loader` option or the `extension`
flag in compiler options:

```yaml
targets:
  $default:
    builders:
      build_web_compilers:entrypoint:
        options:
          loader: .load.js
          compilers:
            dart2js:
              extension: .old.js
            dart2wasm:
              extension: .new.mjs
```

This configuration uses both `dart2js` and `dart2wasm`, but names the final
entrypoint for a `main.dart` file `main.load.js`. That loader will either load
a `.new.mjs` file for WebAssembly or a `.old.js` for pure JavaScript.

Note that the `loader` option is ignored when `dart2wasm` is not enabled, as
it's the compiler requiring an additional loader to be emitted.

### Customizing the WebAssembly loader

In some cases, for instance when targeting Node.JS, the generated loader for
`dart2wasm` may be unsuitable. The builtin loader can be disabled by setting
the option to null:

```yaml
targets:
  $default:
    builders:
      build_web_compilers:entrypoint:
        options:
          loader: null
          compilers:
            dart2js:
            dart2wasm:
```

In this case, you need to use another builder or a predefined loader instead.

### Configuring -D environment variables

dartdevc is a modular compiler, so in order to ensure consistent builds
in every module environment variables must be configured globally. Configure
with a mapping in YAML. Environment defined variables can be read with
`const String.fromEnvironment` and `const bool.fromEnvironment`. For example:

```yaml
global_options:
  build_web_compilers:ddc:
    options:
      environment:
        SOME_VAR: some value
        ANOTHER_VAR: false
```

These may also be specified on the command line with a `--define` argument.

```sh
webdev serve -- '--define=build_web_compilers:ddc=environment={"SOME_VAR":"changed"}'
```

For dart2js, use the `args` option within the `dart2js` compiler entry. This
may be configured globally, or per target.

```yaml
targets:
  $default:
    builders:
      build_web_compilers:entrypoint:
        options:
          compilers:
            dart2js:
              args:
                - -DSOME_VAR=some value
                - -DANOTHER_VAR=true
```

To apply variables across multiple compilers, they have to be added to each
one:

```yaml
targets:
  $default:
    builders:
      build_web_compilers:entrypoint:
        options:
          compilers:
            dart2js:
              args:
                - -DSOME_VAR=some value
                - -DANOTHER_VAR=true
            dart2wasm:
              args:
                - -DSOME_VAR=some value
                - -DANOTHER_VAR=true
```

### Legacy builder options

Previous versions of `build_web_compilers` only supported a single enabled
compiler that would be enabled with the `compiler` option.
If you only want to use `dart2js` for all builds, you can use that option:

```yaml
targets:
  $default:
    builders:
      build_web_compilers:entrypoint:
        # These are globs for the entrypoints you want to compile.
        generate_for:
        - test/**.browser_test.dart
        - web/**.dart
        options:
          compiler: dart2js
          # List any dart2js specific args here, or omit it.
          dart2js_args:
          - -O2
```

Similarly, only compiling with `dart2wasm`:

```yaml
targets:
  $default:
    builders:
      build_web_compilers:entrypoint:
        options:
          compiler: dart2wasm
          # List flags that should be forwarded to `dart compile wasm`
          dart2wasm_args:
          - -O2
```

When no option is set, the `compiler` option is implicitly set to `dart2js` on
release builds and to `dartdevc` otherwise.
Note that the `compilers` option takes precedence over the `compiler` option
when set.

## Manual Usage

If you are using a custom build script, you will need to add the following
builder applications to what you already have, almost certainly at the end of
the list (unless you need to post-process the js files).

```dart
[
    apply(
        'build_web_compilers:ddc',
        [
        (_) => new ModuleBuilder(),
        (_) => new UnlinkedSummaryBuilder(),
        (_) => new LinkedSummaryBuilder(),
        (_) => new DevCompilerBuilder()
        ],
        toAllPackages(),
        // Recommended, but not required. This makes it so only modules that are
        // imported by entrypoints get compiled.
        isOptional: true,
        hideOutput: true),
    apply('build_web_compilers:entrypoint',
        // You can also use `WebCompiler.Dart2Js`. If you don't care about
        // dartdevc at all you may also omit the previous builder application
        // entirely.
        [(_) => new WebEntrypointBuilder(WebCompiler.DartDevc)], toRoot(),
        hideOutput: true,
        // These globs should match your entrypoints only.
        defaultGenerateFor: const InputSet(
            include: const ['web/**', 'test/**.browser_test.dart'])),
]
```

[development dependency]: https://dart.dev/tools/pub/dependencies#dev-dependencies
[Dart development compiler]: https://dart.dev/tools/dartdevc
[`package:build`]: https://pub.dev/packages/build
