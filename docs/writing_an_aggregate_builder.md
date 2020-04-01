Most examples (and use-cases) for builders and generation are around reading a
single file, and outputting another file as a result. For example,
`json_serializable` emits a `<file>.g.dart` per a `<file>.dart` to encode/decode
to JSON, and `sass_builder` emits a `<file>.css` per a `<file>.scss`.

However, sometimes you want to output one or more files based on the inputs of
_many_ files, perhaps even all of them. We call this abstractly, an _aggregate
builder_, or a builder with many inputs and one (or less) outputs.

> **WARNING**: This pattern could have negative effects on your development
> cycle and incremental build, as it invalidates frequently (if _any_ of the
> read files change).

## Defining your `Builder`

Like usual, you'll implement the `Builder` class from `package:build`. Lets
write a simple builder that writes a text file called `all_files.txt` to your
`lib/` folder, which contains a listing of all the files found in `lib/**`.

Obviously this builder isn't too useful, it's just an example!

```dart
import 'package:build/build.dart';

class ListAllFilesBuilder implements Builder {
  // TODO: Implement.
}
```

Every `Builder` needs a method, `build` implemented, and a field or getter,
`buildExtensions`. While they work the same here as any normal builder, they are
slightly more involved. Lets look at `buildExtensions` first.

Normally to write, "generate `{file}.g.dart` for `{file.dart}`", you'd write:

```dart
Map<String, List<String>> get buildExtensions {
  return const {
    '.dart': const ['.g.dart'],
  };
}
```

However, we only want a single output file in (this) aggregate builder. So,
instead we will build on a _synthetic_ input - a file that does not actually
exist on disk, but rather is used as an identifier for build extensions. We
currently support the following synthetic files for this purpose:

* `lib/$lib$`
* `$package$`
* `test/$test$` (deprecated)
* `web/$web$` (deprecated)

When choosing whether to use `$package$` or `lib/$lib$`, there are two primary
considerations.

- _where_ do you want to output your files (which directory should they be
  written to).
  - If you want to output to directories other than `lib`, you should use
    `$package$`.
  - If you want to output files only under `lib`, then use `lib/$lib$`.
- _which_ packages will this builder run on (only the root package or any
  package in the dependency tree).
  - If want to run on any package other than the root, you _must_ use
    `lib/$lib$` since only files under `lib` are accessible from dependencies -
    even synthetic files.

## Writing the `Builder` using a synthetic input

Each of these synthetic inputs exist if the folder exists (and is available to
the build), but they cannot be read. So, for this example, lets write one based
on `lib/$lib$`, and say that we will always emit the file `lib/all_files.txt`.

Since out files are declared by simply replacing the declared input extension
with the declared output extensions, we can use `$lib$` as the input extension,
and `all_files.txt` as the output extension, which will declare an output at
`lib/all_files.txt`.

**Note:** If using `$package$` as an input extension you need to declare the
full output path from the root of the package, since it lives at the root of
the package.

```dart
import 'package:build/build.dart';

class ListAllFilesBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      // Using r'...' is a "raw" string, so we don't interpret $lib$ as a field.
      // An alternative is escaping manually, or '\$lib\$'.
      r'$lib$': const ['all_files.txt'],
    };
  }
}
```

Great! Now, to write the `build` method. Normally for a `build` method you'd
read an input, and write based on that. Again, aggregate builders work a little
differently, there is no "input" (you need to find inputs manually):

```dart
import 'package:build/build.dart';

class ListAllFilesBuilder implements Builder {
  @override
  Future<void> build(BuildStep buildStep) async {
    // Will throw for aggregate builders, because '$lib$' isn't a real input!
    buildStep.readAsString(buildStep.inputId);
  }
}
```

Instead, we can use the `findAssets` API to find the inputs we want to process,
and create a new `AssetId` based off the current package we are processing.

```dart
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

class ListAllFilesBuilder implements Builder {
  static final _allFilesInLib = new Glob('lib/**');

  static AssetId _allFileOutput(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      p.join('lib', 'all_files.txt'),
    );
  }

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': ['all_files.txt'],
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final files = <String>[];
    await for (final input in buildStep.findAssets(_allFilesInLib)) {
      files.add(input.path);
    }
    final output = _allFileOutput(buildStep);
    return buildStep.writeAsString(output, files.join('\n'));
  }
}
```

## Using a `Resolver`

Since the input of aggregate builders isn't a real asset that could be read,
we also can't use `buildStep.inputLibrary` to resolve it.
However, recent versions of the build system allow us to resolve any asset our
builder can read.

For instance, we could adapt the `ListAllFilesBuilder` from before to instead 
list the names of all classes defined in `lib/`:

```dart
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';
import 'package:path/path.dart' as p;

class ListAllClassesBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions {
    return const {r'$lib$': ['all_classes.txt']};
  }

  static AssetId _allFileOutput(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      p.join('lib', 'all_classes.txt'),
    );
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final classNames = <String>[];

    await for (final input in buildStep.findAssets(Glob('lib/**'))) {
      final library = await buildStep.resolver.libraryFor(input);
      final classesInLibrary = LibraryReader(library).classes;

      classNames.addAll(classesInLibrary.map((c) => c.name));
    }

    await buildStep.writeAsString(
        _allFileOutput(buildStep), classNames.join('\n'));
  }
}
```

As the resolver has no single entry point in aggregate builders, be aware that
[`findLibraryByName`][findLibraryByName] and [`libraries`][libraries] can only
find libraries that have been discovered through `libraryFor` or `isLibrary`.

Note that older versions of the build `Resolver` only picked up libraries based
on the builder's input. As the synthetic input asset of an aggregate builder
isn't readable, the `Resolver` wasn't available for aggregate builders in older
versions of the build system.

To ensure your builder only runs in an environment where this is supported, you
can set the minimum version in your `pubspec.yaml`:

```yaml
dependencies:
  build_resolvers: ^1.3.0
  # ...
```

### Workaround for older versions

If you want to support older versions of the build system as well, you can split
your aggregate builder into two steps:

1. A `Builder` with `buildExtensions` of `{'.dart': ['.some_name.info']}`. Use
   the `Resolver` to find the information about the code that will be necessary
   later. Serialize this to json or similar and write it as an intermediate
   file. This should always be `build_to: cache`.
2. A `Builder` with `buildExtensiosn` of `{r'$lib$': ['final_output_name']}`.
   Use the glob APIs to read and deserialize the outputs from the previous step,
   then generate the final content.

Each of these steps  must be a separate `Builder` instance in Dart code. They
can be in the same builder definition in `build.yaml` only if they are both
output to cache. If the final result should be built to source they must be
separate builder definitions. In the single builder definition case ordering is
handled by the order of the `builder_factories` in the config. In the separate
builder definition case ordering should be handled by configuring the second
step to have a `required_inputs: ['.some_name.info']` based on the build
extensions of the first step.

This strategy has the benefit of improved invalidation - only the files that
_need_ to be re-read with the `Resolver` will be invalidated, the rest of the
`.info` files will be retained as-is.

[findLibraryByName]: https://pub.dev/documentation/build/latest/build/Resolver/findLibraryByName.html
[libraries]: https://pub.dev/documentation/build/latest/build/Resolver/libraries.html