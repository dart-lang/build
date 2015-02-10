library source_gen.example.person;

import 'package:source_gen/json_serial/json_annotation.dart';

part 'person_part.dart';
part 'person.g.dart';

@JsonSerializable()
class Person extends Object with _$PersonSerializerMixin {
  String firstName, middleName, lastName;
  DateTime dob;

  Person();

  factory Person.fromJson(json) => _$PersonFromJson(json);
}
