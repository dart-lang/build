// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_gen.test.json_serializable_integration_test;

import 'dart:convert';

import 'package:test/test.dart';

import 'test_files/json_test_example.dart';

void main() {
  group('Person', () {
    roundTripPerson(Person p) {
      _roundTripObject(p, (json) => new Person.fromJson(json));
    }

    test("null", () {
      roundTripPerson(new Person(null, null));
    });

    test("empty", () {
      roundTripPerson(new Person('', '',
          middleName: '',
          dateOfBirth: new DateTime.fromMillisecondsSinceEpoch(0)));
    });

    test("now", () {
      roundTripPerson(new Person('a', 'b',
          middleName: 'c', dateOfBirth: new DateTime.now()));
    });

    test("now toUtc", () {
      roundTripPerson(new Person('a', 'b',
          middleName: 'c', dateOfBirth: new DateTime.now().toUtc()));
    });
  });

  group('Order', () {
    roundTripOrder(Order p) {
      _roundTripObject(p, (json) => new Order.fromJson(json));
    }

    test("null", () {
      roundTripOrder(new Order());
    });

    test("empty", () {
      roundTripOrder(new Order()
        ..count = 0
        ..isRushed = false
        ..item = (new Item(0)..itemNumber = 0));
    });

    test("simple", () {
      roundTripOrder(new Order()
        ..count = 42
        ..isRushed = true
        ..item = (new Item(13)..itemNumber = 72));
    });
  });
}

void _roundTripObject(object, factory(json)) {
  var json;
  try {
    json = JSON.encode(object.toJson());
  } on JsonUnsupportedObjectError catch (e) {
    print(e.cause);
    rethrow;
  }

  var person2 = factory(JSON.decode(json));

  expect(person2, equals(object));

  var json2 = JSON.encode(person2.toJson());

  expect(json2, equals(json));
}
