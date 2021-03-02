// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  test('should assert something was logged synchronously', () {
    expect(
      recordLogs(() => log.info('Hello World')),
      emitsAnyOf([
        anyLogOf('Hello World'),
      ]),
    );
  });

  test('should assert something was logged asynchronously', () {
    expect(
      recordLogs(() => Future.microtask(() => log.info('Hello World'))),
      emitsAnyOf([
        anyLogOf('Hello World'),
      ]),
    );
  });

  test('should assert log levels', () {
    expect(
      recordLogs(() {
        log
          ..info('INFO')
          ..warning('WARNING')
          ..severe('SEVERE');
      }),
      emitsInOrder([
        infoLogOf('INFO'),
        warningLogOf('WARNING'),
        severeLogOf('SEVERE'),
      ]),
    );
  });
}
