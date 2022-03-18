// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Uses `?` to ensure null safety is enabled
// ignore: unnecessary_nullable_for_final_variable_declarations
final String? message = 'hello';

// Used in null assertion tests.
void printNonNullable(String message) => print(message);
