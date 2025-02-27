// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:web/web.dart';

void startApp({String? text}) {
  text ??= 'Hello World!';
  // ignore: deprecated_member_use
  var component = HTMLDivElement()..text = text;
  document.body!.append(component);
}
