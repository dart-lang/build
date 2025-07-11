<p align="center">
  Testing utilities for users of <a href="https://pub.dev/packages/build"><code>package:build</code></a>.
  <br>
  <a href="https://github.com/dart-lang/build/labels/package%3Abuild_test">
    <img src="https://img.shields.io/github/issues-raw/dart-lang/build/package%3Abuild_test.svg" alt="Issues related to build_test" />
  </a>
  <a href="https://pub.dev/packages/build_test">
    <img src="https://img.shields.io/pub/v/build_test.svg" alt="Pub Package Version" />
  </a>
  <a href="https://pub.dev/documentation/build_test/latest">
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
  build_test: ^3.0.0
```

## Running tests

To run tests, you should go through the `dart run build_runner test` command.
This will compile all your tests to a temp directory and run them using
`dart run test`. If you would like to see the output directory, you can use the
`--output=<dir>` option to force the output to go to a specific place.

### Forwarding additional args to `dart run test`

It is very common to need to pass some arguments through to the eventual call
to `dart run test`. To do this, add all those args after an empty `--` arg.

For example, to run all chrome platform tests you would do
`dart run build_runner test -- -p chrome`.

## Debugging web tests

This package will automatically create `*.debug.html` files next to all your
`*_test.dart` files, which can be loaded in a browser from the normal
development server (`dart run build_runner serve`).

**Note:** In order to run the tests this way, you will need to configure them
to be compiled (by default we only compile `*.browser_test.dart` files). You
can do this in your build.yaml file, with something like the following:

```yaml
targets:
  $default:
    builders:
      build_web_compilers:entrypoint:
        generate_for:
        - test/**_test.dart
        - web/**.dart
```

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

### Exposing actual package sources to `testBuilder`

To pass sources on disk to `testBuilder`, create a `TestReaderWriter`. You can
write individual sources to it from a `PackageAssetReader`, or write all sources
to it with `loadIsolateSources`:

```dart
final readerWriter = TestReaderWriter(rootPackage: 'test_package');
await readerWriter.testing.loadIsolateSources();
testBuilder(
  yourBuilder,
  {'test_package|lib/a.dart': '''
import 'package:real_package/annotations.dart';

@RealAnnotation()
class TestClass {}
'''},
  readerWriter: readerWriter,
);
```

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
* [`TestReaderWriter`][api:TestReaderWriter]
* [`PackageAssetReader`][api:PackageAssetReader]

[development dependency]: https://dart.dev/tools/pub/dependencies#dev-dependencies
[`package:build`]: https://pub.dev/packages/build

[api:FakeWatcher]: https://pub.dev/documentation/build_test/latest/build_test/FakeWatcher-class.html
[api:TestReaderWriter]: https://pub.dev/documentation/build_test/latest/build_test/TestReaderWriter-class.html
[api:PackageAssetReader]: https://pub.dev/documentation/build_test/latest/build_test/PackageAssetReader-class.html

[api:resolveAsset]: https://pub.dev/documentation/build_test/latest/build_test/resolveAsset.html
[api:resolveSource]: https://pub.dev/documentation/build_test/latest/build_test/resolveSource.html
[api:testBuilder]: https://pub.dev/documentation/build_test/latest/build_test/testBuilder.html
