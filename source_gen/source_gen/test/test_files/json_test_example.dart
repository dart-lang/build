// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_gen.test.example;

import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:source_gen/generators/json_serializable.dart';

part 'json_test_example.g.dart';

@JsonSerializable()
class Person extends Object with _$PersonSerializerMixin {
  final String firstName, middleName, lastName;
  final DateTime dateOfBirth;

  Person(this.firstName, this.lastName, {this.middleName, this.dateOfBirth});

  factory Person.fromJson(json) => _$PersonFromJson(json);

  bool operator ==(other) =>
      other is Person &&
      firstName == other.firstName &&
      middleName == other.middleName &&
      lastName == other.lastName &&
      dateOfBirth == other.dateOfBirth;
}

@JsonSerializable()
class Order extends Object with _$OrderSerializerMixin {
  int count;
  bool isRushed;
  final UnmodifiableListView<Item> items;

  int get price => items.fold(0, (item, total) => item.price + total);

  Order([Iterable<Item> items])
      : this.items = new UnmodifiableListView<Item>(
            new List<Item>.unmodifiable(items ?? const []));

  factory Order.fromJson(json) => _$OrderFromJson(json);

  bool operator ==(other) =>
      other is Order &&
      count == other.count &&
      isRushed == other.isRushed &&
      const DeepCollectionEquality().equals(items, other.items);
}

@JsonSerializable()
class Item extends Object with _$ItemSerializerMixin {
  final int price;
  int itemNumber;
  List<DateTime> saleDates;

  Item([this.price]);

  factory Item.fromJson(Map<String, Object> json) => _$ItemFromJson(json);

  bool operator ==(other) =>
      other is Item &&
      price == other.price &&
      itemNumber == other.itemNumber &&
      const DeepCollectionEquality().equals(saleDates, other.saleDates);
}
