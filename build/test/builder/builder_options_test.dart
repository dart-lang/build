// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:test/test.dart';

void main() {
  group('BuilderOptions', () {
    test('overrides with non-empty options', () {
      var defaults = const BuilderOptions(const {'foo': 'bar', 'baz': 'bop'});
      var overridden = defaults.overrideWith(
          const BuilderOptions(const {'baz': 'different', 'more': 'added'}));
      expect(overridden.config,
          {'foo': 'bar', 'baz': 'different', 'more': 'added'});
    });

    test('changes nothing when overriding with empty options', () {
      var defaults = const BuilderOptions(const {'foo': 'bar', 'baz': 'bop'});
      var overridden = defaults.overrideWith(BuilderOptions.empty);
      expect(overridden, same(defaults));
    });
  });
}
