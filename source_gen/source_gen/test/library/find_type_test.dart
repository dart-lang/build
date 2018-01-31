// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

final _source = r'''
  library test_lib;

  export 'dart:collection' show LinkedHashMap;
  export 'package:source_gen/source_gen.dart' show Generator;
  import 'dart:async' show Stream;

  class Example {}
''';

void main() {
  LibraryReader library;

  setUpAll(() async {
    library = await resolveSource(
      _source,
      (r) async => new LibraryReader(await r.findLibraryByName('test_lib')),
    );
  });

  test('should return a type not exported', () {
    expect(library.findType('Example'), _isClassElement);
  });

  test('should return a type exported from dart:', () {
    expect(library.findType('LinkedHashMap'), _isClassElement);
  });

  test('should return a type exported from package:', () {
    expect(library.findType('Generator'), _isClassElement);
  });

  test('should not return a type imported', () {
    expect(library.findType('Stream'), isNull);
  });
}

final _isClassElement = const isInstanceOf<ClassElement>();
