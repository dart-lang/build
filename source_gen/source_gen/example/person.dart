library source_gen.example.person;

import 'package:source_gen/json_serial/json_annotation.dart';

part 'person.g.dart';

@JsonSerializable()
class Person extends Object with _$_PersonSerializerMixin {
  String firstName, middleName, lastName;
  DateTime dob;

  Person();
}

@JsonSerializable()
class Order {
  int count;
  int itemNumber;
  bool isRushed;
}

// TODO: Handle InvalidGenerationSourceError correctly Issue #9
// @JsonSerializable()
// const testValue = 12345;
