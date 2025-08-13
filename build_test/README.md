_Questions? Suggestions? Found a bug? Please 
[file an issue](https://github.com/dart-lang/build/issues) or
 [start a discussion](https://github.com/dart-lang/build/discussions)._

Test helpers for [build_runner](https://pub.dev/packages/build_runner) builders.

- [In-memory builds](#in-memory-builds)
- [In-memory builds with real sources](#in-memory-builds-with-real-sources)
- [Resolving source code](#resolving-source-code)

### In-memory builds

The [testBuilders][api:testBuilders] method provides a way to run builds in
memory for small, self contained tests. See the `test` folder in the `build` package for examples.

### In-memory builds with real sources

To pass sources on disk to `testBuilders`, create a
[TestReaderWriter][api:TestReaderWriter].

You can write individual sources to it from a
[PackageAssetReader][api:PackageAssetReader], or write all sources to it with
`loadIsolateSources`:

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

### Resolving source code

Use [resolveAsset][api:resolveAsset] or
[resolveSource][api:resolveSource] to resolve code with the analyzer:

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

[api:PackageAssetReader]: https://pub.dev/documentation/build_test/latest/build_test/PackageAssetReader-class.html
[api:resolveAsset]: https://pub.dev/documentation/build_test/latest/build_test/resolveAsset.html
[api:resolveSource]: https://pub.dev/documentation/build_test/latest/build_test/resolveSource.html
[api:testBuilders]: https://pub.dev/documentation/build_test/latest/build_test/testBuilders.html
[api:TestReaderWriter]: https://pub.dev/documentation/build_test/latest/build_test/TestReaderWriter-class.html
