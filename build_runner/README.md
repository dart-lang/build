<p align="center">
  Standalone generator and watcher for Dart using <a href="https://pub.dev/packages/build"><code>package:build</code></a>.
  <br>
  <a href="https://github.com/dart-lang/build/labels/package%3A%20build_runner">
    <img src="https://img.shields.io/github/issues-raw/dart-lang/build/package%3A%20build_runner.svg" alt="Issues related to build_runner" />
  </a>
  <a href="https://pub.dev/packages/build_runner">
    <img src="https://img.shields.io/pub/v/build_runner.svg" alt="Pub Package Version" />
  </a>
  <a href="https://pub.dev/documentation/build_runner/latest">
    <img src="https://img.shields.io/badge/dartdocs-latest-blue.svg" alt="Latest Dartdocs" />
  </a>
  <a href="https://gitter.im/dart-lang/build">
    <img src="https://badges.gitter.im/dart-lang/build.svg" alt="Join the chat on Gitter" />
  </a>
</p>

The `build_runner` package provides a concrete way of generating files using
Dart code, outside of tools like `pub`. Unlike `pub serve/build`, files are
always generated directly on disk, and rebuilds are _incremental_ - inspired by
tools such as [Bazel][].

> **NOTE**: Are you a user of this package? You may be interested in
> simplified user-facing documentation, such as our
> [getting started guide][getting-started-link].

[getting-started-link]: https://goo.gl/b9o2j6

* [Installation](#installation)
* [Usage](#usage)
  * [Built-in commands](#built-in-commands)
  * [Inputs](#inputs)
  * [Outputs](#outputs)
  * [Source control](#source-control)
  * [Publishing packages](#publishing-packages)
* [Contributing](#contributing)
  * [Testing](#testing)

## Installation

This package is intended to support development of Dart projects with
[`package:build`][]. In general, put it under [dev_dependencies][], in your
[`pubspec.yaml`][pubspec].

```yaml
dev_dependencies:
  build_runner:
```

## Usage

When the packages providing `Builder`s are configured with a `build.yaml` file
they are designed to be consumed using an generated build script. Most builders
should need little or no configuration, see the documentation provided with the
Builder to decide whether the build needs to be customized. If it does you may
also provide a `build.yaml` with the configuration. See the
`package:build_config` README for more information on this file.

To have web code compiled to js add a `dev_dependency` on `build_web_compilers`.

### Built-in Commands

The `build_runner` package exposes a binary by the same name, which can be
invoked using `dart run build_runner <command>`.

The available commands are `build`, `watch`, `serve`, and `test`.

- `build`: Runs a single build and exits.
- `watch`: Runs a persistent build server that watches the files system for
  edits and does rebuilds as necessary.
- `serve`: Same as `watch`, but runs a development server as well.
  - By default this serves the `web` and `test` directories, on port `8080` and
    `8081` respectively. See below for how to configure this.
- `test`: Runs a single build, creates a merged output directory, and then runs
  `dart run test --precompiled <merged-output-dir>`. See below for instructions
  on passing custom args to the test command.
- `build-filter`: Build filters allow you to choose explicitly which files to build instead of building entire directories.

#### Command Line Options

All the above commands support the following arguments:

- `--help`: Print usage information for the command.
- `--delete-conflicting-outputs`: Assume conflicting outputs in the users
  package are from previous builds, and skip the user prompt that would usually
  be provided.
- `--[no-]fail-on-severe`: Whether to consider the build a failure on an error
  logged. By default this is false.

Some commands also have additional options:

### serve

- `--hostname`: The host to run the server on.
- `--live-reload`: Enables automatic page reloading on rebuilds.

Trailing args of the form `<directory>:<port>` are supported to customize what
directories are served, and on what ports.

For example to serve the `example` and `web` directories on ports 8000 and 8001
you would do `dart run build_runner serve example:8000 web:8001`.

### test

The test command will forward any arguments after an empty `--` arg to the
`dart run test` command.

For example if you wanted to pass `-p chrome` you would do
`dart run build_runner test -- -p chrome`.

### build-filter
Build filters allow you to choose explicitly which files to build instead of building entire directories.

A build filter is a combination of a package and a path, with glob syntax supported for each.

Whenever a build filter is provided, only required outputs matching one of the build filters will be built, in addition to the inputs to those outputs.

##### Command Line Usage:

Build filters are supplied using the new `--build-filter` option, which accepts relative paths under the package as well as `package:` uris.

Glob syntax is allowed in both package names and paths.

*Example*: The following would build and serve the JS output for an application, as well as copy over the required SDK resources for that app:

```bash
pub run build_runner serve \
  --build-filter="web/main.dart.js" \
  --build-filter="package:build_web_compilers/**/*.js"
```

##### Build Daemon Usage:

The build daemon now accepts build filters when registering a build target. If no filters are supplied these default filters are used, which is designed to match the previous behavior as closely as possible:

* <target-dir>/**
* package:*/**

*Note:* There is one small difference compared to the previous behavior, which is that build to source outputs from other top level directories in the root package will no longer be built when they would have before. This should have no meaningful impact other than being more efficient.

##### Common Use Cases:

*Note:* For all the listed use cases it is up to the user or tool the user is using to request all the required files for the desired task. This package only provides the core building blocks for these use cases.

##### Testing:

If you have a large number of tests but only want to run a single one you can now build just that test instead of all tests under the test directory.

This can greatly speed up iteration times in packages with lots of tests.

*Example:* This will build a single web test and run it:

```bash
pub run build_runner test \
  --build-filter="test/my_test.dart.browser_test.dart.js" \
  --build-filter="package:build_web_compilers/**/*.js" \
  -- -p chrome test/my_test.dart
```

*Note:* If your test requires any other generated files (css, etc) you will need to add additional filters.

##### Applications:

This feature works as expected with the `--output <dir>` and the `serve` command. This means you can create an output directory for a single application in your package instead of all applications under the same directory.

The serve command also uses the build filters to restrict what files are available, which means it ensures if something works in serve mode it will also work when you create an output directory.

### Inputs

Valid inputs follow the general dart package rules. You can read any files under
the top level `lib` folder any package dependency, and you can read all files
from the current package.

In general it is best to be as specific as possible with your `InputSet`s,
because all matching files will be checked against a `Builder`'s
[`buildExtensions`][build_extensions] - see [outputs](#outputs) for more
information.

### Outputs

* You may output files anywhere in the current package.

> **NOTE**: When a `BuilderApplication` specifies `hideOutput: true` it may
> output under the `lib` folder of _any_ package you depend on.

* Builders are not allowed to overwrite existing files, only create new ones.
* Outputs from previous builds will not be treated as inputs to later ones.
* You may use a previous `BuilderApplications`'s outputs as an input to a later
  action.

### Source control

This package creates a top level `.dart_tool` folder in your package, which
should not be submitted to your source control repository. You can see [our own
`.gitignore`](https://github.com/dart-lang/build/blob/master/.gitignore) as an
example.

```git
# Files generated by dart tools
.dart_tool
```

When it comes to _generated_ files it is generally best to not submit them to
source control, but a specific `Builder` may provide a recommendation otherwise.

It should be noted that if you do submit generated files to your repo then when
you change branches or merge in changes you may get a warning on your next build
about declared outputs that already exist. This will be followed up with a
prompt to delete those files. You can type `l` to list the files, and then type
`y` to delete them if everything looks correct. If you think something is wrong
you can type `n` to abandon the build without taking any action.

### Publishing packages

In general generated files **should** be published with your package, but this
may not always be the case. Some `Builder`s may provide a recommendation for
this as well.


## Legacy Usage

If the generated script does not do everything you need it's possible to
manually write one. With this approach every package which *uses* a
[`Builder`][builder] must have it's own script, they cannot be reused
from other packages. A package which defines a [`Builder`][builder] may have an
example you can reference, but a unique script must be written for the consuming
packages as well. You can reference the generated script at
`.dart_tool/build/entrypoint/build.dart` for an example.

Your script should the [**`run`**][run_fn] functions defined in this library.

### Configuring

[`run`][run_fn] has a required parameter which is a `List<BuilderApplication>`.
These correspond to the `BuilderDefinition` class from `package:build_config`.
See `apply` and `applyToRoot` to create instances of this class. These will be
translated into actions by crawling through dependencies. The order of this list
is important. Each Builder may read the generated outputs of any Builder that
ran on a package earlier in the dependency graph, but for the package it is
running on it may only read the generated outputs from Builders earlier in the
list of `BuilderApplication`s.

**NOTE**: Any time you change your build script (or any of its dependencies),
the next build will be a full rebuild. This is because the system has no way
of knowing how that change may have affected the outputs.

## Contributing

We welcome a diverse set of contributions, including, but not limited to:

* [Filing bugs and feature requests][file_an_issue]
* [Send a pull request][pull_request]
* Or, create something awesome using this API and share with us and others!

For the stability of the API and existing users, consider opening an issue
first before implementing a large new feature or breaking an API. For smaller
changes (like documentation, minor bug fixes), just send a pull request.

### Testing

All pull requests are validated against CI, and must pass. The
`build_runner` package lives in a mono repository with other `build` packages,
and _all_ of the following checks must pass for _each_ package.

Ensure code passes all our [analyzer checks][analysis_options]:

```sh
$ dartanalyzer .
```

Ensure all code is formatted with the latest [dev-channel SDK][dev_sdk].

```sh
$ dartfmt -w .
```

Run all of our unit tests:

```sh
$ dart run test
```

[Bazel]: https://bazel.build/
[`package:build`]: https://pub.dev/packages/build
[analysis_options]: https://github.com/dart-lang/build/blob/master/analysis_options.yaml

[builder]: https://pub.dev/documentation/build/latest/build/Builder-class.html
[run_fn]: https://pub.dev/documentation/build_runner/latest/build_runner/run.html
[builder_application]: https://pub.dev/documentation/build_runner/latest/build_runner/BuilderApplication-class.html
[build_extensions]: https://pub.dev/documentation/build/latest/build/Builder/buildExtensions.html

[dev_sdk]: https://dart.dev/get-dart
[dev_dependencies]: https://dart.dev/tools/pub/dependencies#dev-dependencies
[pubspec]: https://dart.dev/tools/pub/pubspec
[file_an_issue]: https://github.com/dart-lang/build/issues/new
[pull_request]: https://github.com/dart-lang/build/pulls
