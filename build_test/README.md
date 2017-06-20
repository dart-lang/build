# build_test

Testing utilities for users of [`package:build`][].

<p align="center">
  <a href="https://travis-ci.org/dart-lang/build">
    <img src="https://travis-ci.org/dart-lang/build.svg?branch=master" alt="Build Status" />
  </a>
  <a href="https://github.com/dart-lang/build/labels/package%3Abuild_test">
    <img src="https://img.shields.io/github/issues-raw/dart-lang/build/package%3Abuild_test.svg" alt="Issues related to build_test" />
  </a>
  <a href="https://pub.dartlang.org/packages/build_test">
    <img src="https://img.shields.io/pub/v/build_test.svg" alt="Pub Package Version" />
  </a>
  <a href="https://www.dartdocs.org/documentation/build_test/latest">
    <img src="https://img.shields.io/badge/dartdocs-latest-blue.svg" alt="Latest Dartdocs" />
  </a>
  <a href="https://gitter.im/dart-lang/source_gen">
    <img src="https://badges.gitter.im/dart-lang/source_gen.svg" alt="Join the chat on Gitter" />
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

## Usage

_See the `test` folder in the `build` package for more examples_.

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

### Run a `Builder` within a test environment

Using [`testBuilder`][api:testBuilder], you can run a functional test of a
`Builder`, including feeding specific assets, and more. It automatically
creates an in-memory representation of various utility classes.

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
