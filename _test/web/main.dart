// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_test/app.dart';

import 'sub/message.dart' deferred as message;

void main() async {
  await message.loadLibrary();
  startApp(text: const String.fromEnvironment('message') ?? message.message);
}
