// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
import 'dart:html';

import 'package:test/test.dart';

import 'common/counter.dart';

void main() {
  test('can use custom html', () {
    expect(document.getElementById('my-element'), isNotNull);
  });

  test('can load additional apps, with their own context', () async {
    expect(counter, 1);
    SpanElement? secondAppCounter;
    while (secondAppCounter == null) {
      await Future.delayed(Duration(milliseconds: 100));
      secondAppCounter =
          document.body!.querySelector('#second_app_counter') as SpanElement?;
    }
    expect(secondAppCounter.text, '1');
  });
}
