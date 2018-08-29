// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:build_modules/build_modules.dart';

main() {
  test('dartdevc doesnt support mirrors/io/ui, but does support html', () {
    expect(DartPlatform.dartdevc.supportsLibrary('io'), isFalse);
    expect(DartPlatform.dartdevc.supportsLibrary('mirrors'), isFalse);
    expect(DartPlatform.dartdevc.supportsLibrary('ui'), isFalse);
    expect(DartPlatform.dartdevc.supportsLibrary('html'), isTrue);
  });

  test('dart2js doesnt support mirrors/io/ui, but does support html', () {
    expect(DartPlatform.dart2js.supportsLibrary('io'), isFalse);
    expect(DartPlatform.dart2js.supportsLibrary('mirrors'), isFalse);
    expect(DartPlatform.dart2js.supportsLibrary('ui'), isFalse);
    expect(DartPlatform.dart2js.supportsLibrary('html'), isTrue);
  });

  test('dart2jsServer doesnt support mirrors/io/ui/html', () {
    expect(DartPlatform.dart2jsServer.supportsLibrary('io'), isFalse);
    expect(DartPlatform.dart2jsServer.supportsLibrary('mirrors'), isFalse);
    expect(DartPlatform.dart2jsServer.supportsLibrary('ui'), isFalse);
    expect(DartPlatform.dart2jsServer.supportsLibrary('html'), isFalse);
  });

  test('vm supports mirrors/io, but doesnt support html/ui', () {
    expect(DartPlatform.vm.supportsLibrary('io'), isTrue);
    expect(DartPlatform.vm.supportsLibrary('mirrors'), isTrue);
    expect(DartPlatform.vm.supportsLibrary('ui'), isFalse);
    expect(DartPlatform.vm.supportsLibrary('html'), isFalse);
  });

  test('flutter supports io/ui, but doesnt support html/mirrors', () {
    expect(DartPlatform.flutter.supportsLibrary('io'), isTrue);
    expect(DartPlatform.flutter.supportsLibrary('mirrors'), isFalse);
    expect(DartPlatform.flutter.supportsLibrary('ui'), isTrue);
    expect(DartPlatform.flutter.supportsLibrary('html'), isFalse);
  });
}
