library source_gen.example.example;

import 'package:source_gen/generators/json_serializable.dart';
import 'package:source_gen/generators/json_literal.dart';

part 'example.g.dart';

@JsonSerializable()
class Person extends Object with _$PersonSerializerMixin {
  final String firstName, middleName, lastName;
  final DateTime dateOfBirth;

  Person(this.firstName, this.lastName, {this.middleName, this.dateOfBirth});

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

@JsonSerializable(createToJson: false)
class Item {
  int count;
  int itemNumber;
  bool isRushed;

  Item();

  factory Item.fromJson(Map<String, Object> json) => _$ItemFromJson(json);
}

@JsonLiteral('data.json')
Map get glossaryData => _$glossaryDataJsonLiteral;
