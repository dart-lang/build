_Questions? Suggestions? Found a bug? Please
[file an issue](https://github.com/dart-lang/build/issues) or
 [start a discussion](https://github.com/dart-lang/build/discussions)._

Code generation for Dart and Flutter packages.

- [Builders](#builders)
- [Getting started](#getting-started)
   - [Install builders](#install-builders)
   - [Build and watch](#build-and-watch)
   - [Output files](#output-files)
   - [Internal files](#internal-files)
   - [Additional configuration](#additional-configuration)
- [Writing your own builder](#writing-your-own-builder)

## Builders

A `build_runner` code generator is called a _builder_.

Usually, a builder adds some capability to your code that is inconvenient to
add and maintain in pure Dart. Examples include serialization, data classes,
data binding, dependency injection, and mocking.

Here is a selection of the most-used builders on [pub.dev](https://pub.dev).
Except as noted, they are not owned or specifically endorsed by Google.

|Builder|Adds capabilities|Notes|
|-|-|-
|[auto_route_generator](https://pub.dev/packages/auto_route)|Flutter navigation|
|[built_value_generator](https://pub.dev/packages/built_value)|data classes with JSON serialization|[Flutter Favourite](https://docs.flutter.dev/packages-and-plugins/favorites) by&nbsp;Google
|[chopper_generator](https://pub.dev/packages/chopper)|REST HTTP client|[Flutter Favourite](https://docs.flutter.dev/packages-and-plugins/favorites)
|[copy_with_extension_gen](https://pub.dev/packages/copy_with_extension_gen)|`copyWith` extension methods|
|[dart_mappable_builder](https://pub.dev/packages/dart_mappable)|data classes with JSON serialization|
|[drift_dev](https://pub.dev/packages/drift_dev)|reactive data binding and SQL|
|[envied_generator](https://pub.dev/packages/envied)|environment variable bindings|
|[freezed](https://pub.dev/packages/freezed)|data classes, tagged unions, nested classes, cloning|[Flutter Favourite](https://docs.flutter.dev/packages-and-plugins/favorites)
|[flutter_gen_runner](https://pub.dev/packages/flutter_gen_runner)|Flutter asset bindings|
|[go_router_builder](https://pub.dev/packages/go_router_builder)|Flutter navigation|by&nbsp;Google
|[hive_ce_generator](https://pub.dev/packages/hive_ce)|key-value database|
|[injectable_generator](https://pub.dev/packages/injectable_generator)|dependency injecton|
|[json_serializable](https://pub.dev/packages/json_serializable)|JSON serialization|[Flutter Favourite](https://docs.flutter.dev/packages-and-plugins/favorites) by&nbsp;Google
|[mockito](https://pub.dev/packages/mockito)|mocks and fakes for testing|by&nbsp;Google
|[retrofit_generator](https://pub.dev/packages/retrofit_generator)|REST HTTP client|
|[riverpod_generator](https://pub.dev/packages/riverpod)|reactive caching and data binding|[Flutter Favourite](https://docs.flutter.dev/packages-and-plugins/favorites)
|[slang_build_runner](https://pub.dev/packages/slang)|type-safe i18n|
|[swagger_dart_code_generator](https://pub.dev/packages/swagger_dart_code_generator)|dart types from Swagger/OpenAPI schemas|
|[theme_tailor](https://pub.dev/packages/theme_tailor)|Flutter themes and extensions|
|[webdev](https://pub.dev/packages/webdev)|compilation to javascript|by&nbsp;Google

## Getting started

### Install builders

Find builders that look useful, perhaps via the list above, and follow their
"getting started" guides.

The guides will take you through adding the necessary dependencies to your
package, then how to write code that activates the builder's capabilities.
Most builders are activated via an annotation that tells the builder to run
and what exactly it should do.

For example, after following the `json_serializable` guide you will have these
dependencies in your `pubspec.yaml`:

```yaml
dependencies:
  json_annotation: ^4.9.0

dev_dependencies:
  build_runner: ^2.6.0
  json_serializable: ^6.10.0
```

and activate it with code like

```dart
import 'package:json_annotation/json_annotation.dart';

// Include the file that the builder will generate.
part 'example.g.dart';.

// Activate the builder.
@JsonSerializable()
class Person {
  final String name;
  final DateTime? dateOfBirth;

  Person({required this.name, this.dateOfBirth});

  // Wire up the generated `toJson` in `example.g.dart`.
  Map<String, dynamic> toJson() => _$PersonToJson(this);

  // Wire up the generated `fromJson` in `example.g.dart`.
  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);
}
```

—see [the json_serializable documentation](https://pub.dev/packages/json_serializable) for more detail.

### Build and watch

Once you have installed builders in your package, use the terminal to do a single build

```bash
cd <package root folder>
dart run build_runner build
```

or to launch "watch mode", which runs a build whenever your source code changes:

```bash
cd <package root folder>
dart run build_runner watch
```

So, for example, in the `json_serializable` example, watch mode updates the
generated `toJson` and `fromJson` as you add or remove fields from the
`Person` class.

```dart
@JsonSerializable()
class Person {
  final String name;
  final DateTime? dateOfBirth;
  // Added.
  final int age;

  // Updated manually.
  Person({required this.name, this.dateOfBirth, this.age});

  // No change needed, the generated implementations referenced get updated.
  Map<String, dynamic> toJson() => _$PersonToJson(this);
  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);
}
```

If you have multiple packages then you need to run `build` or `watch` in each
package separately; there is an
[open feature request for workspace support](https://github.com/dart-lang/build/issues/3804).

### Output files

Output is written directly to your package source, for example under `lib`.
This makes it immediately available to all tools including compilers and IDEs.

You can choose whether or not to check generated files into source control.

If you publish your package, you must publish the generated files with it.
Users getting your package via `pub` cannot run the build step themselves.

### Internal files

`build_runner`uses a folder called `.dart_tool` in your package for internal files.
These are private to `build_runner` and should not be edited, checked in,
published or used in any other way.

So, tools such as `git` must be configured to ignore them. Make `git` ignore `.dart_tool` by adding to your `.gitignore` file:

```bash
.dart_tool
```

### Additional configuration

Builders can be further configured with a `build.yaml` file in your package's
root folder.

For example, you can restrict which files in your package a builder runs for:

```yaml
targets:
  $default:
    builders:
      json_serializable:
        generate_for:
          # Only run `json_serializable` on source under `lib/models`.
          - lib/models/*.dart
```

Occasionally when using multiple builders you will need to specify which order
they run in. For full details on this and other options see the
[build_config documentation](https://pub.dev/packages/build_config).

Some settings apply to a specific builder, for example `freezed`:

```yaml
targets:
  $default:
    builders:
      freezed:
        options:
          # Do format output.
          format: true
          # Don't generate `copyWith` or `operator==`.
          copy_with: false
          equal: false
```

—see each builder's documentation for details.

## Writing your own builder

For advanced use cases it's possible to write your own builder.

Get started with the [build package documentation](https://pub.dev/packages/build).
For testing builders, see the [`build_test` package](https://pub.dev/packages/build_test).

## Debugging builds

To debug the build process, note that `build_runner` spawns a child process to run
the build.
Options used to spawn this process can be customized, which allows attaching a debugger:

```shell
dart run build_runner build --dart-jit-vm-arg=--observe --dart-jit-vm-arg=--pause-isolates-on-start
```
