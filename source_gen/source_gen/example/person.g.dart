// GENERATED CODE - DO NOT MODIFY BY HAND
// 2015-02-02T21:20:44.694Z

part of source_gen.example.person;

// Sample Json Generator
// class Person
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

// Sample Json Generator
// class Order
abstract class _$_OrderSerializerMixin {
  int get count;
  int get itemNumber;
  bool get isRush;
  static Order fromJson(Map<String, Object> json) {
    return new Order()
      ..count = json['count']
      ..itemNumber = json['itemNumber']
      ..isRush = json['isRush'];
  }
  Map<String, Object> toJson() =>
      {'count': count, 'itemNumber': itemNumber, 'isRush': isRush};
}
