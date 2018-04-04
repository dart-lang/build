# build_test

<p align="center">
  Testing utilities for users of <a href="https://pub.dartlang.org/packages/build"><code>package:build</code></a>.
  <br>
  <a href="https://travis-ci.org/dart-lang/build">
    <img src="https://travis-ci.org/dart-lang/build.svg?branch=master" alt="Build Status" />
  </a>
  <a href="https://github.com/dart-lang/build/labels/package%3A%20build_test">
    <img src="https://img.shields.io/github/issues-raw/dart-lang/build/package%3A%20build_test.svg" alt="Issues related to build_test" />
  </a>
  <a href="https://pub.dartlang.org/packages/build_test">
    <img src="https://img.shields.io/pub/v/build_test.svg" alt="Pub Package Version" />
  </a>
  <a href="https://pub.dartlang.org/documentation/build_test/latest">
    <img src="https://img.shields.io/badge/dartdocs-latest-blue.svg" alt="Latest Dartdocs" />
  </a>
  <a href="https://gitter.im/dart-lang/build">
    <img src="https://badges.gitter.im/dart-lang/build.svg" alt="Join the chat on Gitter" />
  </a>
</p>

## Installation

This package is intended to only be as a [development dependency][] for users
of [`package:build`][], and should not be used in any production code. Simply
add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  build_test:
```

## Running tests

To run tests, you should go through the `pub run build_runner test` command.
This will compile all your tests to a temp directory and run them using
`pub run test`. If you would like to see the output directory, you can use the
`--output=<dir>` option to force the output to go to a specific place.

### Forwarding additional args to `pub run test`

It is very common to need to pass some arguments through to the eventual call
to `pub run test`. To do this, add all those args after an empty `--` arg.

For example, to run all chrome platform tests you would do
`pub run build_runner test -- -p chrome`.

## Debugging web tests

This package will automatically create `*.debug.html` files next to all your
`*_test.dart` files, which can be loaded in a browser from the normal
development server (`pub run build_runner serve`).

You may also view an index of links to every `*.debug.html` file by navigating
to `http://localhost:8081` (or wherever your `test` folder is being served).

## Writing tests for your custom Builder

In addition to assiting in running normal tests, this package provides some
utilities for testing your custom `Builder` classes.

_See the `test` folder in the `build` package for more examples_.

### Run a `Builder` within a test environment

Using [`testBuilder`][api:testBuilder], you can run a functional test of a
`Builder`, including feeding specific assets, and more. It automatically
creates an in-memory representation of various utility classes.

### Resolve source code for testing

Using [`resolveAsset`][api:resolveAsset] and
[`resolveSource`][api:resolveSource], you can resolve Dart source code into a
static element model, suitable for probing and using within tests of code you
might have written for a `Builder`:

```dart
test('should resolve a simple dart file', () async {
  var resolver = await resolveSource(r'''
    library example;

    class Foo {}
  ''');
  var libExample = resolver.getLibraryByName('example');
  expect(libExample.getType('Foo'), isNotNull);
});
```

### Various test implementations of classes

* [`FakeWatcher`][api:FakeWatcher]
* [`InMemoryAssetReader`][api:InMemoryAssetReader]
* [`InMemoryAssetWriter`][api:InMemoryAssetWriter]
* [`MultiAssetReader`][api:MultiAssetReader]
* [`PackageAssetReader`][api:PackageAssetReader]
* [`RecordingAssetWriter`][api:RecordingAssetWriter]
* [`StubAssetReader`][api:StubAssetReader]
* [`StubAssetWriter`][api:StubAssetWriter]

[development dependency]: https://www.dartlang.org/tools/pub/dependencies#dev-dependencies
[`package:build`]: https://pub.dartlang.org/packages/build

[api:FakeWatcher]: https://www.dartdocs.org/documentation/build_test/latest/build_test/FakeWatcher-class.html
[api:InMemoryAssetReader]: https://www.dartdocs.org/documentation/build_test/latest/build_test/InMemoryAssetReader-class.html
[api:InMemoryAssetWriter]: https://www.dartdocs.org/documentation/build_test/latest/build_test/InMemoryAssetWriter-class.html
[api:MultiAssetReader]: https://www.dartdocs.org/documentation/build_test/latest/build_test/MultiAssetReader-class.html
[api:PackageAssetReader]: https://www.dartdocs.org/documentation/build_test/latest/build_test/PackageAssetReader-class.html
[api:RecordingAssetWriter]: https://www.dartdocs.org/documentation/build_test/latest/build_test/RecordingAssetWriter-class.html
[api:StubAssetReader]: https://www.dartdocs.org/documentation/build_test/latest/build_test/StubAssetReader-class.html
[api:StubAssetWriter]: https://www.dartdocs.org/documentation/build_test/latest/build_test/StubAssetWriter-class.html

[api:resolveAsset]: https://www.dartdocs.org/documentation/build_test/latest/build_test/resolveAsset.html
[api:resolveSource]: https://www.dartdocs.org/documentation/build_test/latest/build_test/resolveSource.html
[api:testBuilder]: https://www.dartdocs.org/documentation/build_test/latest/build_test/testBuilder.html
