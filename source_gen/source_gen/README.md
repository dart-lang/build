[![Build Status](https://travis-ci.org/dart-lang/source_gen.svg?branch=master)](https://travis-ci.org/dart-lang/source_gen)
[![Coverage Status](https://coveralls.io/repos/dart-lang/source_gen/badge.svg?branch=master)](https://coveralls.io/r/dart-lang/source_gen)

`source_gen` provides:

* A **tool** for generating code that is part of your Dart project.
* A **framework** for creating and using multiple code generators in a single
  project.
* A **convention** for human and tool generated Dart code to coexist with clean
  separation.

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

`source_gen` is based on the `build` package (
  [pub](https://pub.dartlang.org/packages/build),
  [GitHub](https://github.com/dart-lang/build)).

See `build.dart` and `watch.dart` in the `tool` directory. Both reference
`tool/phases.dart`, which contains information mapping `source_gen` generators
to target files.

## source_gen vs Dart Transformers
[Dart Transformers][] are often used to create and modify code and assets as part
of a Dart project.

Transformers allow modification of existing code and encapsulates changes by
having developers use `pub` commands – `run`, `serve`, and `build`.

`source_gen` provides a different model. Code is generated and updated
as part of a project. It is designed to create *part* files that augment
developer maintained Dart libraries.

Generated code **MAY** be checked in as part of our project source,
although the decision may vary depending on project needs.

Generated code **SHOULD** be included when publishing a project as a *pub
package*. The fact that `source_gen` is used in a package is an *implementation
detail*.

[Dart Transformers]: https://www.dartlang.org/tools/pub/assets-and-transformers.html
[example code]: https://github.com/dart-lang/source_gen/tree/master/example
[Trivial example]: https://github.com/dart-lang/source_gen/blob/master/test/src/comment_generator.dart
[Included generators]: https://github.com/dart-lang/source_gen/tree/master/lib/generators
[build.dart]: https://github.com/dart-lang/source_gen/blob/master/build.dart
[generate]: http://www.dartdocs.org/documentation/source_gen/latest/index.html#source_gen/source_gen@id_generate
[build]: http://www.dartdocs.org/documentation/source_gen/latest/index.html#source_gen/source_gen@id_build
