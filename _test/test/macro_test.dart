// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_test/macros/debug_to_string.dart';

import 'package:test/test.dart';


void main() {
  test('macro stuff is generated', () {
    expect(User('Jill', 25).debugToString(), equals('''
User {
  name: Jill
  age: 25
}'''));
  });
}

@DebugToString()
class User {
  final String name;
  final int age;

  User(this.name, this.age);
}
