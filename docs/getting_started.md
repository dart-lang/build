# Getting started with `build_runner`

To use `build_runner`, you need a 2.x version of
the Dart SDK.

* [Automated installers](https://dart.dev/get-dart#install)
* [Direct downloads](https://dart.dev/tools/sdk/archive#dev-channel)

If you have issues using `build_runner`, see the
[Troubleshooting section](#troubleshooting), below.

* [Using `build_runner` as a development server](#using-build_runner-as-a-development-server)
* [Creating an output directory](#creating-an-output-directory)
* [Using other `build_runner` commands](#using-other-build_runner-commands)
* [Switching to Dart2JS](#switching-to-dart2js)
* [Troubleshooting](#troubleshooting)
  * [`build_runner` has no versions that match...](#build_runner-has-no-versions-that-match)
  * [Too many open files](#too-many-open-files)

## Using `build_runner` as a development server

1. Edit your package's **pubspec.yaml** file,
   adding dev dependencies on **build_runner** and **build_web_compilers**:

   ```yaml
   ...
   environment:
     sdk: '>=2.0.0 <3.0.0'
   ...
   dev_dependencies:
     build_runner: ^1.0.0
     build_web_compilers: ^0.4.0
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

## Creating an output directory

Build with `--output <directory name>` to write files into a merged output
directory with file paths that match internally referenced URIs. This can be
used with the `build`, `watch`, and `serve` commands. This directory can also
be used with a different server if the `serve` command is insufficient.

To output only part of the package, for example to output only the `web`
directory, use `--output web:<directory name>`.

## Using other `build_runner` commands

In addition to **serve** you can use:

- **build:** Runs a single build and exits. This is most useful if your build
  also generates output to your source directory. With `--output <dirname>` this
  also creates a merged output directory with all sources and generated assets.

- **watch:** Like `build` but reruns after file changes. With
  `--output <dirname>` the merged output directory will be kept up to date with
  changes. This can be used to keep the outputs updated for use with another
  filed-based development server.

- **test:** Creates an output directory and runs `pub run test` within it.
  This command requires a dev dependency on `build_test`.

## Switching to dart2js

By default `build_web_compilers` uses dartdevc. To switch to dart2js, pass
`--release` to `pub run build_runner build` (or `serve`). Pass args to dart2js
by creating a `build.yaml` file.

```yaml
targets:
  $default:
    builders:
      build_web_compilers|entrypoint:
        options:
          dart2js_args:
          - --minify
          - --fast-startup
```

## Troubleshooting

<!-- summarize here. -->

### Diagnosing build times

See
<https://github.com/dart-lang/build/blob/master/docs/measuring_performance.md>.

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
