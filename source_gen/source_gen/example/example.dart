library source_gen.example.example;

import 'package:source_gen/generators/json_serializable.dart';
import 'package:source_gen/generators/json_literal.dart';

part 'example.g.dart';

@JsonSerializable()
class Person extends Object with _$PersonSerializerMixin {
  String firstName, middleName, lastName;
  DateTime dob;

  Person();

  factory Person.fromJson(json) => _$PersonFromJson(json);
}

@JsonSerializable(createFactory: false)
class Order extends Object with _$OrderSerializerMixin {
  int count;
  int itemNumber;
  bool isRushed;

  Order();
}

@JsonSerializable(createToJson: false)
class Item extends Object {
  int count;
  int itemNumber;
  bool isRushed;

  Item();

  factory Item.fromJson(Map<String, Object> json) => _$ItemFromJson(json);
}

@JsonLiteral('data.json')
Map get glossaryData => _$glossaryDataJsonLiteral;
