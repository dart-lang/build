// GENERATED CODE - DO NOT MODIFY BY HAND
// 2015-02-16T18:15:06.117Z

part of source_gen.example.example;

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
