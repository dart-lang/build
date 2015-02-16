// GENERATED CODE - DO NOT MODIFY BY HAND
// 2015-02-16T23:03:38.487Z

part of source_gen.example.example;

// **************************************************************************
// Generator: JsonGenerator
// Target: class Person
// **************************************************************************

Person _$PersonFromJson(Map<String, Object> json) => new Person(
    json['firstName'], json['lastName'],
    middleName: json['middleName'],
    dateOfBirth: json.containsKey('dateOfBirth')
        ? DateTime.parse(json['dateOfBirth'])
        : null);

abstract class _$PersonSerializerMixin {
  String get firstName;
  String get middleName;
  String get lastName;
  DateTime get dateOfBirth;
  Map<String, Object> toJson() => {
    'firstName': firstName,
    'middleName': middleName,
    'lastName': lastName,
    'dateOfBirth': dateOfBirth == null ? null : dateOfBirth.toIso8601String()
  };
}

// **************************************************************************
// Generator: JsonGenerator
// Target: class Order
// **************************************************************************

Order _$OrderFromJson(Map<String, Object> json) => new Order()
  ..count = json['count']
  ..itemNumber = json['itemNumber']
  ..isRushed = json['isRushed'];

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

// **************************************************************************
// Generator: Instance of 'JsonLiteralGenerator'
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
