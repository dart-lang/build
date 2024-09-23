// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@Tags(['multiple-entrypoints'])
@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:test/test.dart';

void main() {
  test('did load script from a subdirectory', () {
    // The custom HTML file includes `sub-dir/subdir_source.dart.js`, which
    // should have set the `otherScriptLoader` propery.
    expect(globalContext.has('otherScriptLoaded'), isTrue);
  });
}
