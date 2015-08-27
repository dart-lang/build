// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_gen.test.example;

import 'package:source_gen/generators/json_serializable.dart';

part 'json_test_example.g.dart';

@JsonSerializable()
class Person extends Object with _$PersonSerializerMixin {
  final String firstName, middleName, lastName;
  final DateTime dateOfBirth;

  Person(this.firstName, this.lastName, {this.middleName, this.dateOfBirth});

  factory Person.fromJson(json) => _$PersonFromJson(json);

  bool operator ==(other) => other is Person &&
      firstName == other.firstName &&
      middleName == other.middleName &&
      lastName == other.lastName &&
      dateOfBirth == other.dateOfBirth;
}

@JsonSerializable()
class Order extends Object with _$OrderSerializerMixin {
  int count;
  bool isRushed;
  Item item;

  Order();

  factory Order.fromJson(json) => _$OrderFromJson(json);

  bool operator ==(other) => other is Order &&
      count == other.count &&
      isRushed == other.isRushed &&
      item == other.item;
}

@JsonSerializable()
class Item extends Object with _$ItemSerializerMixin {
  final int price;
  int itemNumber;

  Item([this.price]);

  factory Item.fromJson(Map<String, Object> json) => _$ItemFromJson(json);

  bool operator ==(other) =>
      other is Item && price == other.price && itemNumber == other.itemNumber;
}
