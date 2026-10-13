// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build_runner/src/build/resolver/sdk_summary.dart';
import 'package:test/test.dart';

void main() {
  group('depsMatch', () {
    final currentDeps = {'sdk': '3.10.0', 'analyzer': '/packages/analyzer'};

    test('matches the same deps', () {
      expect(depsMatch(jsonEncode(currentDeps), currentDeps), true);
    });

    test('does not match a changed value', () {
      expect(
        depsMatch(jsonEncode({...currentDeps, 'sdk': '3.11.0'}), currentDeps),
        false,
      );
    });

    test('does not match a missing key', () {
      expect(depsMatch(jsonEncode({'sdk': '3.10.0'}), currentDeps), false);
    });

    test('does not match an extra key', () {
      expect(
        depsMatch(
          jsonEncode({...currentDeps, 'build_runner': '/packages/br'}),
          currentDeps,
        ),
        false,
      );
    });

    test('does not match an empty deps file', () {
      expect(depsMatch('', currentDeps), false);
    });

    test('does not match a truncated deps file', () {
      expect(
        depsMatch(jsonEncode(currentDeps).substring(0, 5), currentDeps),
        false,
      );
    });

    test('does not match content that is not a JSON map', () {
      expect(depsMatch('7', currentDeps), false);
    });
  });
}
