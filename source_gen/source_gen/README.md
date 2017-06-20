# source_gen

<p align="center">
  <a href="https://travis-ci.org/dart-lang/source_gen">
    <img src="https://travis-ci.org/dart-lang/source_gen.svg?branch=master" alt="Build Status" />
  </a>
  <a href="https://pub.dartlang.org/packages/source_gen">
    <img src="https://img.shields.io/pub/v/source_gen.svg" alt="Pub Package Version" />
  </a>
  <a href="https://gitter.im/dart-lang/source_gen">
    <img src="https://badges.gitter.im/dart-lang/source_gen.svg" alt="Join the chat on Gitter" />
  </a>
</p>

## Overview

`source_gen` provides utilities for automated source code generation for Dart:

* A **tool** for generating code that is part of your Dart project.
* A **framework** for creating and using multiple code generators in a single
  project.
* A **convention** for human and tool generated Dart code to coexist with clean
  separation.

It's main purpose is to expose a developer-friendly API on top of lower-level
packages like the [analyzer](https://pub.dartlang.org/packages/analyzer) or
[build][]. You don't _have_ to use `source_gen` in order to generate source code;
we also expose a set of library APIs that might be useful in your generators.

## Quick Start Guide

Because `source_gen` is a package, not an executable, it should be included as
a dependency in your project. If you are creating a generator for others to use
(for example, a JSON serialization generator) or a library that builds on top
of `source_gen` include it in your [pubspec `dependencies`][pub_deps]:

```yaml
dependencies:
  source_gen:
```

If you're only using `source_gen` in your own project to generate code, and
then you publish that code (generated code included), then you can simply add
as a `dev_dependency`:

```yaml
dev_dependencies:
  source_gen:
```

[pub_deps]: https://www.dartlang.org/tools/pub/dependencies
  
Once you have `source_gen` setup, you should reference the examples below.

## Example

Given a library `example.dart` with an `Person` class annotated with
`@JsonSerializable`:

```dart
library source_gen.example;

import 'package:source_gen/generators/json_serializable.dart';
part 'example.g.dart';

@JsonSerializable()
class Person extends Object with _$PersonSerializerMixin {
  final String firstName, middleName, lastName;

  @JsonKey('date-of-birth')
  final DateTime dateOfBirth;

  Person(this.firstName, this.lastName, {this.middleName, this.dateOfBirth});

  factory Person.fromJson(json) => _$PersonFromJson(json);
}
```

`source_gen` creates the corresponding part `example.g.dart`:

```dart
part of source_gen.example;

Person _$PersonFromJson(Map json) => new Person(
    json['firstName'], json['lastName'],
    middleName: json['middleName'],
    dateOfBirth: json['date-of-birth'] == null
        ? null
        : DateTime.parse(json['date-of-birth']));

abstract class _$PersonSerializerMixin {
  String get firstName;
  String get middleName;
  String get lastName;
  DateTime get dateOfBirth;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'date-of-birth': dateOfBirth?.toIso8601String(),
      };
}
```

See the [example code][] in the `source_gen` GitHub repo.

## Creating a generator

Extend the `Generator` class to plug into `source_gen`.

* [Trivial example][]
* [Included generators][]

## Running generators

`source_gen` is based on the [`build`][build] package.

See `build.dart` and `watch.dart` in the `tool` directory. Both reference
`tool/phases.dart`, which contains information mapping `source_gen` generators
to target files.

## FAQ

### What is the difference between `source_gen` and [`build`][build]?

Build is a platform-agnostic framework for Dart asset or code generation that
is pluggable into multiple build systems including
[barback (pub/dart transformers)][build_barback], [bazel][bazel_codegen], and
standalone tools like [build_runner][]. You could also build your own.

Meanwhile, `source_gen` provides an API and tooling that is easily usable on
top of `build` to make common tasks easier and more developer friendly. For
example the [`GeneratorBuilder`][api:GeneratorBuilder] class wraps one or
more [`Generator`][api:Generator] instances to make a [`Builder`][api:Builder].

### What is the difference between `source_gen` and transformers?

[Dart transformers][] are often used to create and modify code and assets as part
of a Dart project.

Transformers allow modification of existing code and encapsulates changes by
having developers use `pub` commands – `run`, `serve`, and `build`.
Unfortunately the API exposed by transformers hinder fast incremental builds,
output caching, and predictability, so we introduced _builders_ as part of
[`package:build`][build].

Builders and `source_gen` provide for a different model: outputs _must_ be
declared ahead of time and code is generated and updated as part of a project.
It is designed to create *part* _or_ standalone files that augment developer
maintained Dart libraries. For example [AngularDart][angular2] uses `build` and
`source_gen` to "compile" HTML and annotation metadata into plain `.dart` code.

Unlike _transformers_, generated code **MAY** be checked in as part of your
project source, although the decision may vary depending on project needs.

Generated code **SHOULD** be included when publishing a project as a *pub
package*. The fact that `source_gen` is used in a package is an *implementation
detail*.

<!-- Packages -->
[angular2]: https://pub.dartlang.org/packages/angular2
[bazel_codegen]: https://pub.dartlang.org/packages/_bazel_codegen
[build]: https://pub.dartlang.org/packages/build
[build_barback]: https://pub.dartlang.org/packages/build_barback
[build_runner]: https://pub.dartlang.org/packages/build_runner

<!-- Dartdoc -->
[api:Builder]: https://www.dartdocs.org/documentation/build/latest/builder/Builder-class.html
[api:Generator]: https://www.dartdocs.org/documentation/source_gen/latest/builder/Generator-class.html
[api:GeneratorBuilder]: https://www.dartdocs.org/documentation/source_gen/latest/builder/GeneratorBuilder-class.html

[Dart transformers]: https://www.dartlang.org/tools/pub/assets-and-transformers.html
[example code]: https://github.com/dart-lang/source_gen/tree/master/example
[Trivial example]: https://github.com/dart-lang/source_gen/blob/master/test/src/comment_generator.dart
[Included generators]: https://github.com/dart-lang/source_gen/tree/master/lib/generators
[build.dart]: https://github.com/dart-lang/source_gen/blob/master/build.dart
[generate]: http://www.dartdocs.org/documentation/source_gen/latest/index.html#source_gen/source_gen@id_generate
[build]: http://www.dartdocs.org/documentation/source_gen/latest/index.html#source_gen/source_gen@id_build
