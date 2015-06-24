// GENERATED CODE - DO NOT MODIFY BY HAND
// 2015-06-24T03:27:46.394Z

part of source_gen.example.example;

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
    'dateOfBirth': dateOfBirth == null ? null : dateOfBirth.toIso8601String()
  };
}

// **************************************************************************
// Generator: JsonSerializableGenerator
// Target: class Order
// **************************************************************************

Order _$OrderFromJson(Map json) => new Order()
  ..count = json['count']
  ..itemNumber = json['itemNumber']
  ..isRushed = json['isRushed']
  ..item = json['item'] == null ? null : new Item.fromJson(json['item']);

abstract class _$OrderSerializerMixin {
  int get count;
  int get itemNumber;
  bool get isRushed;
  Item get item;
  Map<String, dynamic> toJson() => <String, dynamic>{
    'count': count,
    'itemNumber': itemNumber,
    'isRushed': isRushed,
    'item': item
  };
}

// **************************************************************************
// Generator: JsonSerializableGenerator
// Target: class Item
// **************************************************************************

Item _$ItemFromJson(Map json) => new Item()
  ..count = json['count']
  ..itemNumber = json['itemNumber']
  ..isRushed = json['isRushed'];

// **************************************************************************
// Generator: JsonLiteralGenerator
// Target: glossaryData
// **************************************************************************

final _$glossaryDataJsonLiteral = {
  "glossary": {
    "title": "example glossary",
    "GlossDiv": {
      "title": "S",
      "GlossList": {
        "GlossEntry": {
          "ID": "SGML",
          "SortAs": "SGML",
          "GlossTerm": "Standard Generalized Markup Language",
          "Acronym": "SGML",
          "Abbrev": "ISO 8879:1986",
          "GlossDef": {
            "para":
                "A meta-markup language, used to create markup languages such as DocBook.",
            "GlossSeeAlso": ["GML", "XML"]
          },
          "GlossSee": "markup"
        }
      }
    }
  }
};
