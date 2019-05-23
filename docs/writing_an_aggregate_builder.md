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
exist on disk, but rather is used as an identifier for us. We currently support:

* `$lib$`
* `$test$`
* `$web$`

## Writing the `Builder`

Each of these exist if the folder exists, but they cannot be read. So, for this
example, lets write one based on `$lib$`, and say that we will always emit the
file `all_files.txt`:

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
    // Will throw for aggregate builders, because '$lib' isn't a real input!
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
    return new AssetId(
      buildStep.inputId.package,
      p.join('lib', 'all_files.txt'),
    );
  }

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': const ['all_files.txt'],
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

The `Resolver` provided by the build system only works when the primary input to
a build step is a `.dart` library, and then only for the code transitively
imported by that library. If an aggregate builder needs to resolve Dart code
form the inputs it globs then it needs to be split into two steps. Each of these
steps can be implemented as a separate `builder_factory` (and `Builder` class)
but roll into the same builder definition in `build.yaml` if they can both
output to cache - otherwise for the final output to source they need to be
separate builder definitions in `build.yaml` and use `runs_before` or
`required_inputs` to ensure that they happen in the correct order.

1. A `Builder` with `buildExtensions` of `{'.dart': ['.some_name.info']}`. Use
   the `Resolver` to find the information about the code that will be necessary
   later. Serialize this to json or similar and write it as an intermediate
   file. This should always be `build_to: cache`.
2. A `Builder` with `buildExtensiosn` of `{r'$lib$': ['final_output_name']}`.
   Use the glob APIs to read and desrialize the outputs from the previous step,
   then generate the final content.

This strategy has the benefit of improved invalidation - only the files that
_need_ to be re-read with the `Resolver` will be invalidated, the rest of the
`.info` files will be retained as-is.
