// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:_test/macros/debug_to_string.dart';

void main() {
  document.body!.text = User('Jill', 25).debugToString();
}

@DebugToString()
class User {
  final String name;
  final int age;

  User(this.name, this.age);
}
