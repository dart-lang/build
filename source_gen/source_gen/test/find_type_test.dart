// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  LibraryElement library;

  setUpAll(() async {
    final resolver = await resolveSource(r'''
      library test_lib;
      
      export 'dart:collection' show LinkedHashMap;
      export 'package:source_gen/source_gen.dart' show Generator;
      import 'dart:async' show Stream;
      
      class Example {}
    ''');
    library = resolver.getLibraryByName('test_lib');
  });

  final isClassElement = const isInstanceOf<ClassElement>();

  test('should return a type not exported', () {
    expect(findType(library, 'Example'), isClassElement);
  });

  test('should return a type exported from dart:', () {
    expect(findType(library, 'LinkedHashMap'), isClassElement);
  });

  test('should return a type exported from package:', () {
    expect(findType(library, 'Generator'), isClassElement);
  });

  test('should not return a type imported', () {
    expect(findType(library, 'Stream'), isNull);
  });
}
