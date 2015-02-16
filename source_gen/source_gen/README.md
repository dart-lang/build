[![Build Status](https://travis-ci.org/kevmoo/source_gen.dart.svg)](https://travis-ci.org/kevmoo/source_gen.dart)
[![Coverage Status](https://coveralls.io/repos/kevmoo/source_gen.dart/badge.svg)](https://coveralls.io/r/kevmoo/source_gen.dart)
[![Stories in Ready](https://badge.waffle.io/kevmoo/source_gen.dart.png?label=ready&title=Ready)](https://waffle.io/kevmoo/source_gen.dart)

**NOTE: Dart 1.9 is required to use this package. You can download a Dev channel 
release [here](https://www.dartlang.org/tools/download-archive/).**

`source_gen` provides:

* A **tool** for generating code that is part of your Dart project.
* A **framework** for creating and using multiple code generators in a single
  project.
* A **convention** for human and tool generated Dart code to coexist with clean
  seperation.

## Example

Given a library `person.dart`:

```dart
library source_gen.example.person;

import 'package:source_gen/json_serial/json_annotation.dart';

part 'person.g.dart';

@JsonSerializable()
class Person extends Object with _$PersonSerializerMixin {
  String firstName, middleName, lastName;
  DateTime dob;

  Person();

  factory Person.fromJson(json) => _$PersonFromJson(json);
}
```

`source_gen` creates the corresponding part `person.g.dart`:

```dart
part of source_gen.example.person;

Person _$PersonFromJson(Map<String, Object> json) => new Person()
  ..firstName = json['firstName']
  ..middleName = json['middleName']
  ..lastName = json['lastName']
  ..dob = json['dob'];

abstract class _$PersonSerializerMixin {
  String get firstName;
  String get middleName;
  String get lastName;
  DateTime get dob;
  Map<String, Object> toJson() => {
    'firstName': firstName,
    'middleName': middleName,
    'lastName': lastName,
    'dob': dob
  };
}
```

See the [example code][] in the `source_gen` GitHub repo.

## Creating a generator

Extend the `Generator` class to plug into `source_gen`.

* [Trivial example][]
* [Included generators][]

## Running generators

Create a script that invokes the [generate][] method.

Alternatively, you can create a `build.dart` file which calls the [build] 
method.

You can invoke this script directly. It also understands the 
[Dart Editor build system][] so code is updated as your modify files.

See [build.dart][] in the repository for an example.

## source_gen vs Dart Transformers
[Dart Transformers][] are often used create and modify code and assets as part
of a Dart project.

Transformers allow modification of existing code and encapsulates changes by
having developers use `pub` commands – `run`, `serve`, and `build`.

`source_gen` provides a different model. Code is generated and updated
as part of a project. It is designed to create *part* files that agument
developer maintained Dart libraries.

Generated code **MAY** be checked in as part of our project source,
although the decision may vary depending on project needs.

Generated code **SHOULD** be included when publishing a project as a *pub
package*. The fact that `source_gen` is used in a package is an *implementation
detail*.

[Dart Transformers]: https://www.dartlang.org/tools/pub/assets-and-transformers.html
[example code]: https://github.com/kevmoo/source_gen.dart/tree/master/example
[Trivial example]: https://github.com/kevmoo/source_gen.dart/blob/master/test/src/class_comment_generator.dart
[Included generators]: https://github.com/kevmoo/source_gen.dart/tree/master/lib/generators
[build.dart]: https://github.com/kevmoo/source_gen.dart/blob/master/build.dart
[generate]: http://www.dartdocs.org/documentation/source_gen/latest/index.html#source_gen/source_gen@id_generate
[build]: http://www.dartdocs.org/documentation/source_gen/latest/index.html#source_gen/source_gen@id_build
[Dart Editor build system]: https://www.dartlang.org/tools/editor/build.html