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

@JsonSerializable()
class Order extends Object with _$OrderSerializerMixin {
  int count;
  int itemNumber;
  bool isRushed;

  Order();

  factory Order.fromJson(json) => _$OrderFromJson(json);
}

@JsonSerializable()
const testValue = 12345;
