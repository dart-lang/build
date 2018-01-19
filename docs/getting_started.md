# Getting started with `build_runner`

To use `build_runner`, you need a 2.x (dev channel or fresher) version of
the Dart SDK.

* [Automated installers](https://www.dartlang.org/install#automated-installation-and-updates)
* [Direct downloads](https://www.dartlang.org/install/archive#dev-channel)

If you have issues using `build_runner`, see the
[Troubleshooting section](#troubleshooting), below.


## Using `build_runner` as a development server

1. Edit your package's **pubspec.yaml** file,
   removing all transformers and
   adding dev dependencies on **build_runner** and **build_web_compilers**:

   ```yaml
   ...  
   environment:
     sdk: '>=2.0.0-dev <2.0.0'
   ...  
   dev_dependencies:
     build_runner: ^0.7.0
     build_web_compilers: ^0.2.0
   ```

2. Get package dependencies:

   ```sh
   pub get
   ```

3. Start the server:
  
   ```sh
   pub run build_runner serve
   ```

While the `serve` command runs, every change you save triggers a rebuild.

The first build is the slowest. After that, assets are cached on disk and
incremental builds are faster.

## Using other build_runner commands

In addition to **serve** you can use:

- **build:** Runs a single build and exits. This is most useful if your build also
  generates output to your source directory. With `--output <dirname>` this
  also creates a merged output directory with all sources and generated assets.

- **watch:** Like `build` but reruns after file changes. With
  `--output <dirname>` the merged output directory will be kept up to date with
  changes. This can be used to keep the outputs updated for use with another
  filed-based development server.

- **test:** Creates an output directory and runs `pub run test` within it.

## Switching to dart2js

By default `build_web_compilers` uses dartdevc. To switch to dart2js,
create a `build.yaml` file with a `target` that matches the name of your packages.

```yaml
targets:
  my_package_name:
    builders:
      dart_web_compilers|entrypoint:
        options:
          compiler: dart2js
```

<!--PENDING: Why does this show a `builders` line? Is that necessary for
dart2js?-->


## Compatibility with other packages

### Upgrading from transformers

`build_runner` can only run Builders that are published with a `build.yaml`
file; it can't use legacy `Transformers`. If your pubspec lists transformers,
switch to a version of the transformer-containing package that has a
`build.yaml` file.

### Upgrading from manual `build.dart` files

Older versions of `build_runner` were designed to run with manually written
build scripts referencing the Builders available in the local package or in
dependencies. This pattern can still be used when customization is needed
outside of `build.yaml`, but we recommend using the generated build script
with `pub run build_runner`, because it will be kept up to date with changes
in the build packages. If your pubspec lists builders, switch to a version of
the builder-containing package that has a `build.yaml` file.


## Troubleshooting

<!-- summarize here. -->

<!-- add something about symptoms if you don't remove transformers -->

### build_runner has no versions that match...

1. Make sure you're using a 2.x SDK.

   ```sh
   dart --version
   ```

2. Check the versions of the packages that your app depends on.
   They should all be compatible with a 2.x SDK.


### Too many open files

If you see a FileSystemException, saying the directory listing failed
due to too many open files, you might need to increase the OS limits.

For details, see <https://github.com/dart-lang/build/issues/857>.
