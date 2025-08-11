_Questions? Suggestions? Found a bug? Please 
[file an issue](https://github.com/dart-lang/build/issues) or
 [start a discussion](https://github.com/dart-lang/build/discussions)._

Package for writing code generators, called _builders_, that run with
[build_runner](https://pub.dev/packages/build_runner). 

- [See also: source_gen](#see-also-source_gen)
- [The `Builder` interface](#the-builder-interface)
   - [Using the analyzer](#using-the-analyzer)
- [Examples](#examples)

## See also: source_gen

The [source_gen](https://pub.dev/packages/source_gen) package provides helpers
for writing common types of builder, for example builders that are triggered by
a particular annotation.

Most builders should use `source_gen`, but it's still useful to learn about the
underlying `Builder` interface that `source_gen` plugs into.

## The `Builder` interface

A builder implements the
[Builder](https://pub.dev/documentation/build/latest/build/Builder-class.html)
interface.

```dart
abstract class Builder {
  /// Declares inputs and outputs by extension.
  Map<String, List<String>> get buildExtensions;

  /// Builds all outputs for a single input.
  FutureOr<void> build(BuildStep buildStep);
}
```

Its `buildExtensions` getter declares what inputs it runs on and what outputs
it might produce.

During a build its `build` method gets called once per matching input.

It uses `buildStep` to read, analyze and write files.

For example, here is a builder that copies input `.txt` files to `.txt.copy` files:

```dart
class CopyBuilder implements Builder {
  @override
  final buildExtensions = const {
    '.txt': ['.txt.copy']
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // Create the output ID from the build step input ID.
    final inputId = buildStep.inputId;
    final outputId = inputId.addExtension('.copy');

    // Read from the input, write to the output.
    final contents = await buildStep.readAsString(inputId);
    await buildStep.writeAsString(outputId, contents);
  }
}
```

Outputs are optional. For example, a builder that is activated by a particular
annotation will output nothing if it does not find that annotation.

### Using the analyzer

The `buildStep` passed to `build` gives easy access to the analyzer for
processing Dart source code.

Use `buildStep.resolver.compilationUnitFor` to parse a single source file, or
`libraryFor` to fully resolve it. This can be used to introspect the full API
of the source code the builder is running on. For example, a builder can learn
enough about a class's field and field types to correctly serialize it.

## Examples

There are some simple examples
[in the build repo](https://github.com/dart-lang/build/blob/master/example).

For real examples of builders, see the list of popular builders in the
[build_runner package documentation](https://pub.dev/packages/build_runner).