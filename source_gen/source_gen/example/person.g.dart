// GENERATED CODE - DO NOT MODIFY BY HAND
// 2015-02-03T04:14:24.191Z

part of source_gen.example.person;

// **************************************************************************
// Generator: JsonGenerator
// Target: class Person
// **************************************************************************

abstract class _$_PersonSerializerMixin {
  String get firstName;
  String get middleName;
  String get lastName;
  DateTime get dob;

  static Person fromJson(Map<String, Object> json) {
    return new Person()
      ..firstName = json['firstName']
      ..middleName = json['middleName']
      ..lastName = json['lastName']
      ..dob = json['dob'];
  }

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

abstract class _$_OrderSerializerMixin {
  int get count;
  int get itemNumber;
  bool get isRushed;

  static Order fromJson(Map<String, Object> json) {
    return new Order()
      ..count = json['count']
      ..itemNumber = json['itemNumber']
      ..isRushed = json['isRushed'];
  }

  Map<String, Object> toJson() =>
      {'count': count, 'itemNumber': itemNumber, 'isRushed': isRushed};
}

// **************************************************************************
// Generator: JsonGenerator
// Target: const dynamic testValue
// **************************************************************************

// ERROR: Generator cannot target `const dynamic testValue`.
// TODO: Remove the JsonSerializable annotation from `const dynamic testValue`.
