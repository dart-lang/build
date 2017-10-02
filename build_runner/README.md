# build_runner

<p align="center">
  Standalone generator and watcher for Dart using <a href="https://pub.dartlang.org/packages/build"><code>package:build</code></a>.
  <br>
  <a href="https://travis-ci.org/dart-lang/build">
    <img src="https://travis-ci.org/dart-lang/build.svg?branch=master" alt="Build Status" />
  </a>
  <a href="https://github.com/dart-lang/build/labels/package%3Abuild_runner">
    <img src="https://img.shields.io/github/issues-raw/dart-lang/build/package%3Abuild_test.svg" alt="Issues related to build_test" />
  </a>
  <a href="https://pub.dartlang.org/packages/build_runner">
    <img src="https://img.shields.io/pub/v/build_runner.svg" alt="Pub Package Version" />
  </a>
  <a href="https://www.dartdocs.org/documentation/build_runner/latest">
    <img src="https://img.shields.io/badge/dartdocs-latest-blue.svg" alt="Latest Dartdocs" />
  </a>
  <a href="https://gitter.im/dart-lang/source_gen">
    <img src="https://badges.gitter.im/dart-lang/source_gen.svg" alt="Join the chat on Gitter" />
  </a>
</p>

The `build_runner` package provides a concrete way of generating files using
Dart code, outside of tools like `pub`. Unlike `pub serve/build`, files are
always generated directly on disk, and rebuilds are _incremental_ - inspired by
tools such as [Bazel][].

* [Installation](#installation)
* [Usage](#usage)
  * [Configuring](#configuring)
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

To run a build, write a simple script to do the work. Every package which
*uses* a [`Builder`][builder] must have it's own script, they cannot be reused
from other packages. Often a package which defines a [`Builder`][builder] will
have an example you can reference, but a unique script must be written for the
consuming packages as well.

Your script should use one of the two functions defined by this library:

- [**`build`**][build_fn]: Run a single build and exit.
- [**`watch`**][watch_fn]: Continuously run builds as you edit files.

### Configuring

Both [`build`][build_fn] and [`watch`][watch_fn] have a single required
argument, a `List<BuildAction>` - each of these [`BuildAction`][build_action]s
may run in parallel, but they may only read outputs from steps _earlier_ in the
list.

A [`BuildAction`][build_action] is a combination of a single
[`Builder`][builder], which actually generates outputs, and a single
[`InputSet`][input_set] , which determines what the primary inputs to that
builder will be.

Lets look at a very simple example, with a single `BuildAction`. You can ignore
the `CopyBuilder` for now, just know that its a `Builder` which copies files:

```dart
main() async {
  await build([
    new BuildAction(
      new CopyBuilder('.copy'), 
      'my_package', 
      inputs: ['lib/*.dart'],
    ),
  ]);
}
```

> Copies all `*.dart` files under `lib` to a corresponding `*.dart.copy`.

Every time you run a `build`, `build_runner` checks for any changes to the
inputs specified, and reruns the `CopyBuilder` for the inputs that actually
changed.

A build with multiple steps may look like:

```dart
main() async {
  await build([
    new BuildAction(
      new CopyBuilder('.copy1'), 
      'my_package', 
      inputs: ['lib/*.dart'],
    ),
    new BuildAction(
      new CopyBuilder('.copy2'), 
      'my_package', 
      inputs: ['lib/*.dart'],
    ),
  ]);
}
```

> Makes _two_ copies of every `*.dart` file, a `.copy1` and `.copy2`.

Let's say, however, you want to use the _previous_ output as an input to the
next build action - for example, you want to convert `.md` (Markdown) to
`.html`, and then convert `.html` into a `.png` (screenshot of the page):

```dart
main() async {
  await build([
    new BuildAction(
      new MarkdownToHtmlBuilder(), 
      'my_package', 
      inputs: ['web/**.md'],
    ),
    new BuildAction(
      new ChromeScreenshotBuilder(), 
      'my_package', 
      inputs: ['web/**.html'],
    ),
  ]);
}
```

> This time, all the `*.html` files will be created first, and since the next
> `BuildAction` is waiting for `*.html` inputs, it will _wait_ for them to be
> created, and then create the `*.png` (screenshot) files.

**NOTE**: Any time you change your build script (or any of its dependencies),
the next build will be a full rebuild. This is because the system has no way
of knowing how that change may have affected the outputs.

### Inputs

Valid inputs follow the general dart package rules. You can read any files under
the top level `lib` folder any package dependency, and you can read all files
from the current package.

In general it is best to be as specific as possible with your `InputSet`s,
because all matching files will be checked against a `Builder`'s
[`buildExtensions`][build_extensions] - see [outputs](#outputs) for more
information.

> Future versions of `build_runner` may aid in automatically generating
> `InputSet`s based on the builders being used! See [issue #353][issue_353].

### Outputs

* You may output files anywhere in the current package.

> **NOTE**: When using the `writeToCache: true` option with either `build` or
> `watch`, builders _are_ allowed to output under the `lib` folder of _any_
> package you depend on.

* You are not allowed to overwrite existing files, only create new ones.
* Outputs from previous builds will not be treated as inputs to later ones.
* You may use a previous `BuildAction`'s outputs as an input to a later action.

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

## Contributing

We welcome a diverse set of contributions, including, but not limited to:

* [Filing bugs and feature requests][file_an_issue]
* [Send a pull request][pull_request]
* Or, create something awesome using this API and share with us and others!

For the stability of the API and existing users, consider opening an issue
first before implementing a large new feature or breaking an API. For smaller
changes (like documentation, minor bug fixes), just send a pull request.

### Testing

All pull requests are validated against [travis][travis], and must pass. The
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
$ pub run test
```

[Bazel]: https://bazel.build/
[`package:build`]: https://pub.dartlang.org/packages/build
[`shelf`]: https://pub.dartlang.org/packages/shelf
[analysis_options]: https://github.com/dart-lang/build/blob/master/analysis_options.yaml

[builder]: https://www.dartdocs.org/documentation/build/latest/build/Builder-class.html
[build_fn]: https://www.dartdocs.org/documentation/build_runner/latest/build_runner/build.html
[watch_fn]: https://www.dartdocs.org/documentation/build_runner/latest/build_runner/watch.html
[build_action]: https://www.dartdocs.org/documentation/build_runner/latest/build_runner/BuildAction-class.html
[input_set]: https://www.dartdocs.org/documentation/build_runner/latest/build_runner/InputSet-class.html
[build_extensions]: https://www.dartdocs.org/documentation/build/latest/build/Builder/buildExtensions.html

[issue_353]: https://github.com/dart-lang/build/issues/353

[travis]: https://travis-ci.org/
[dev_sdk]: https://www.dartlang.org/install
[dev_dependencies]: https://www.dartlang.org/tools/pub/dependencies#dev-dependencies
[pubspec]: https://www.dartlang.org/tools/pub/pubspec
[file_an_issue]: https://github.com/dart-lang/build/issues/new
[pull_request]: https://github.com/dart-lang/build/pulls
