// GENERATED CODE - DO NOT MODIFY BY HAND
// 2015-09-16T21:34:57.658Z

part of source_gen.test.example;

// **************************************************************************
// Generator: JsonSerializableGenerator
// Target: class Person
// **************************************************************************

Person _$PersonFromJson(Map json) => new Person(
    json['firstName'], json['lastName'],
    middleName: json['middleName'],
    dateOfBirth: json['dateOfBirth'] == null
        ? null
        : DateTime.parse(json['dateOfBirth']));

abstract class _$PersonSerializerMixin {
  String get firstName;
  String get middleName;
  String get lastName;
  DateTime get dateOfBirth;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth?.toIso8601String()
      };
}

// **************************************************************************
// Generator: JsonSerializableGenerator
// Target: class Order
// **************************************************************************

Order _$OrderFromJson(Map json) => new Order()
  ..count = json['count']
  ..isRushed = json['isRushed']
  ..item = json['item'] == null ? null : new Item.fromJson(json['item']);

abstract class _$OrderSerializerMixin {
  int get count;
  bool get isRushed;
  Item get item;
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'count': count, 'isRushed': isRushed, 'item': item};
}

// **************************************************************************
// Generator: JsonSerializableGenerator
// Target: class Item
// **************************************************************************

Item _$ItemFromJson(Map json) =>
    new Item(json['price'])..itemNumber = json['itemNumber'];

abstract class _$ItemSerializerMixin {
  int get price;
  int get itemNumber;
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'price': price, 'itemNumber': itemNumber};
}
