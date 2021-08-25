// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'common/counter.dart';

void main() {
  document.body!.append(SpanElement()
    ..id = 'second_app_counter'
    ..text = '$counter');
}
