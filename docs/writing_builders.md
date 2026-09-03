# Writing builders

A guide to writing builders that run with
[`build_runner`](https://pub.dev/packages/build_runner): an overview of existing
builder APIs and detail on the upcoming *Add to Library* feature.

-   [Builder and PostProcessBuilder](#builder-and-postprocessbuilder)
    -   [Builder](#builder)
    -   [PostProcessBuilder](#postprocessbuilder)
-   [Shared part builders in source_gen](#shared-part-builders-in-source_gen)
-   [Outputting libraries vs. parts](#outputting-libraries-vs-parts)
    -   [Libraries](#libraries)
    -   [Parts](#parts)
    -   [Upcoming language feature: parts with imports](#upcoming-language-feature-parts-with-imports)
-   [Upcoming build runner feature: Add to Library](#upcoming-build-runner-feature-add-to-library)
    -   [How it works](#how-it-works)
    -   [Scoped imports](#scoped-imports)
    -   [Simpler output](#simpler-output)
    -   [More powerful](#more-powerful)
    -   [Builder configuration and implementation](#builder-configuration-and-implementation)

--------------------------------------------------------------------------------

## Builder and PostProcessBuilder

The two types of builder are
[`Builder`](https://pub.dev/documentation/build/latest/build/Builder-class.html)
and
[`PostProcessBuilder`](https://pub.dev/documentation/build/latest/build/PostProcessBuilder-class.html).

### Builder

`Builder` is the most powerful and general builder.

-   **Declared file mappings**: Declares inputs and outputs in advance using
    `buildExtensions`, such as `{'.dart': ['.freezed.dart']}` or `{'.dart':
    ['.json']}`.
-   **Build steps**: Each build step runs on one *primary input file* and
    produces zero or more outputs.
-   **Phased execution**: The build runs in a series of phases, with each phase
    containing all the build steps for one particular builder. Outputs from a
    builder become visible in the next phase: so a `freezed` build step cannot
    read the output of other `freezed` build steps, but a different builder
    running at a later phase *can* read them.
-   **Analyzer access**: `buildStep.resolver` allows inspecting Dart ASTs,
    resolving library elements, reading annotations, and introspecting types.
-   **Asset reading**: Can read any readable asset in the package or in
    transitive dependency packages via `buildStep.readAsString` or
    `buildStep.readAsBytes`.

#### Typical uses

-   Generating standalone Dart files such as `.freezed.dart`, `.mocks.dart`, or
    `.mapper.dart`.
-   Serializing assets or compiling web and styling resources.
-   Generating auxiliary metadata files consumed by subsequent build phases.

### PostProcessBuilder

`PostProcessBuilder` is a limited type of builder for specific purposes. It runs
at the end of the build after all standard `Builder` phases have finished.

-   **Declared input**: Matches assets by `inputExtensions`.
-   **Any output**: Can emit any output file that does not collide with existing
    assets.
-   **Primary input only**: Can only read its primary input asset. Has no access
    to `buildStep.resolver`.
-   **Asset deletion**: Can delete its primary input using
    `buildStep.deletePrimaryInput()`.
-   **Write only**: Because it runs at the end of the build, its outputs cannot
    be consumed by any other `Builder` or `PostProcessBuilder`.

#### Typical uses

-   Deleting artifact tree files that are not needed after the build, so they
    will not be written when using `--output` or served when using `dart run
    build_runner serve`.
-   Preparing assets for distribution, such as archiving or compression.

--------------------------------------------------------------------------------

## Shared part builders in source_gen

When multiple builders contribute code to the same Dart library, creating a
separate generated file for each builder clutters the package and forces the
user to write multiple `part` directives.

To solve this, [`package:source_gen`](https://pub.dev/packages/source_gen)
introduced shared part builders.

Behind the scenes, `source_gen` coordinates `Builder` and `PostProcessBuilder`
across multiple phases:

1.  **Generation phase**: Each generator runs as a `SharedPartBuilder`. Instead
    of writing directly to the final part file, each builder writes an artifact
    tree file under `.dart_tool/build/generated/`, such as
    `model.json_serializable.g.part`.
2.  **Combining phase**: A subsequent `combining_builder` reads all `.part`
    artifact tree files for `model.dart`, concatenates their source under a
    single `part of 'model.dart';` header, and writes the consolidated
    `model.g.dart` file.
3.  **Cleanup**: A `PostProcessBuilder` deletes the `.part` artifact tree files
    so they will not be written when using `--output` or served when using `dart
    run build_runner serve`.

The user writes a single directive in their code:

```dart
// lib/model.dart
import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

@JsonSerializable()
class Model {
  ...
}
```

--------------------------------------------------------------------------------

## Outputting libraries vs. parts

A builder that outputs Dart source must choose whether to output a library or a
part.

### Libraries

A builder can output an independent library file, such as `user.mocks.dart`,
imported by the user with `import 'user.mocks.dart';`.

-   **Advantage**: The generated library declares its own `import` directives.
    It manages its own dependencies without forcing the user to add imports to
    the main library file.
-   **Limitation**: As a separate library, the generated code cannot access or
    provide private (`_`) symbols in the user's library. This makes it harder
    for the generated and user code to collaborate.

### Parts

A builder can output a dedicated part file, included with `part
'user.custom.dart';`, or contribute to a shared part file like `part
'user.g.dart';`.

-   **Advantage**: Generated code belongs to the same library. It has access to
    private declarations, can implement private interfaces, and can supply
    mixins like `with _$User`.
-   **Limitation**: Dart `part` files cannot declare `import` directives. Any
    package or type referenced by generated code must be imported by the user in
    the main library file, even if handwritten code never references those
    symbols directly.

### Upcoming language feature: parts with imports

A future Dart SDK release will allow part files to declare imports.

When the feature arrives, parts will be the recommended way to add source to an
existing library. Builders should continue to generate libraries when there is
no existing library to add it to.

## Upcoming build runner feature: Add to Library

*Add to Library* gives builders a new way to write Dart source code. It's a
better way to write part files, and should be immediately interesting for
builders that currently write source to part files. When *Parts with Imports*
launches, builders that currently generate a separate library only to manage
imports should use *Add to Library* instead.

### How it works

-   `build_runner` collects contributions and imports from all participating
    builders directly into a single shared part file per library.
-   Formatting and whitespace from contributions are not preserved:
    `build_runner` handles formatting of the final output.
-   Shared part files are generated under reserved package paths managed by
    `build_runner`. Files under `lib` correspond to part files under `lib/_br_`.
    Files outside `lib` correspond to part files under `_br_` in the package
    root.
-   The user includes the part in their code:

```dart
// lib/src/user.dart -> lib/_br_/src/user.dart
part '../_br_/src/user.dart';

@MyAnnotation()
class User {
  ...
}
```

### Scoped imports

When *Parts with Imports* is available, `LibrarySourceSink` provides a mechanism
for builders to scope the imports they add.

Through `BuildStep.librarySourceSink`, builders declare their imports with a
unique prefix:

```dart
sink.addImport('package:my_helpers/helpers.dart', as: '${sink.importPrefix}_helpers');
```

Each builder receives its own `sink.importPrefix`. Imports do not collide
between builders and do not leak into the parent library scope.

### Simpler output

The *Add to Library* feature distinguishes its outputs from other files: they do
not participate in normal builder input selection or asset reading. They are
never primary inputs, are not returned by `findAssets`, and cannot be read using
`BuildStep` asset-reading methods.

This improves performance compared to equivalent approaches using base `Builder`
and `PostProcessBuilder` features.

### More powerful

Unlike `source_gen` shared part builders, builders using *Add to Library* can
see added source from earlier build phases using analysis. This means for
example that if one `Builder` adds a class to the library then a `Builder` in a
later phase can generate additional code based on it.

### Builder configuration and implementation

#### 1. Configuration in `build.yaml`

A builder declares `adds_to_library: true`:

```yaml
builders:
  my_builder:
    import: "package:my_builder/builder.dart"
    builder_factories: ["myBuilder"]
    # No explicit declared output is needed.
    build_extensions: {".dart": []}
    adds_to_library: true
    auto_apply: dependents
```

#### 2. Writing code in the builder

Inside `build(BuildStep buildStep)`:

```dart
import 'package:build/build.dart';

class MyBuilder implements Builder {
  @override
  final buildExtensions = const {
    '.dart': [],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final sink = await buildStep.librarySourceSink;
    // Null `sink` means the primary input file is not a Dart library.
    if (sink == null) return;

    sink.add("String generatedMessage() => 'Generated';");
  }
}
```
