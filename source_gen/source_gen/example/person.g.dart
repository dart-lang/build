// GENERATED CODE - DO NOT MODIFY BY HAND
// 2015-02-10T16:07:01.811Z

part of source_gen.example.person;

// **************************************************************************
// Generator: JsonGenerator
// Target: class Person
// **************************************************************************

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

// **************************************************************************
// Generator: JsonGenerator
// Target: class Order
// **************************************************************************

abstract class _$OrderSerializerMixin {
  int get count;
  int get itemNumber;
  bool get isRushed;
  Map<String, Object> toJson() =>
      {'count': count, 'itemNumber': itemNumber, 'isRushed': isRushed};
}

// **************************************************************************
// Generator: JsonGenerator
// Target: class Item
// **************************************************************************

Item _$ItemFromJson(Map<String, Object> json) => new Item()
  ..count = json['count']
  ..itemNumber = json['itemNumber']
  ..isRushed = json['isRushed'];
