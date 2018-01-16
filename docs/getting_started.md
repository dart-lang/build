# Getting started with `build_runner`

`build_runner` can be used as a development server.

1. Add a `dev_dependency` on `build_runner: ^0.7.0`
2. Add a `dev_dependency` on `build_web_compilers: ^0.2.0`
3. Run `pub get`
4. To start the server run `pub run build_runner serve`

The first build will be the slowest. After that assets are cached on disk and
incremental builds will be faster. While the `serve` command is running any
changes you save to files will trigger rebuilds automatically.

## Available commands

In addition to `serve` you can use:

- `build` - run a single build and exit. This is most useful if your build also
  generates outputs to your source directory. With `--output <dirname>` this
  also creates a merged output directory with all sources and generated assets.
- `watch` - like `build` but reruns after file changes. With
  `--output <dirname>` the merged output directory will be kept up to date with
  changes. This can be used to keep the outputs updated for use with another
  filed-based development server.
- `test` - Creates an output directory and runs `pub run test` within it.

## Switching to Dart2Js

By default `build_web_compilers` will use DDC. Switch to Dart2JS by creating a
`build.yaml` file with a `target` that matches the name of your packages.

```yaml
targets:
  my_package_name:
    builders:
      dart_web_compilers|entrypiont:
        options:
          compiler: dart2js
```

## Compatibility with other packages

### Upgrading from Transformers

`build_runner` will only run Builders which are published with a `build.yaml`
file. Legacy `Transformers` cannot be run by `build_runner`. Check with the
packages that provide Transformers you are using for versions published with a
`build.yaml` file.

### Upgrading from manual `build.dart` files

Older versions of `build_runner` were designed to run with manually written
build scripts referencing the Builders available in the local package or in
dependencies. Check with the packages that provide Builders you are using for
versions published with a `build.yaml` file.
