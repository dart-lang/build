// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  group('should resolveSource of', () {
    Resolver resolver;

    test('a simple dart file', () async {
      resolver = await resolveSource(r'''
        library example;

        class Foo {}
      ''');
      var libExample = resolver.getLibraryByName('example');
      expect(libExample.getType('Foo'), isNotNull);
    });

    test('a simple dart file with dart: dependencies', () async {
      resolver = await resolveSource(r'''
        library example;

        import 'dart:collection';

        abstract class Foo implements LinkedHashMap {}
      ''');
      var libExample = resolver.getLibraryByName('example');
      var classFoo = libExample.getType('Foo');
      expect(
        classFoo.allSupertypes.map(_toStringId),
        contains('dart:collection#LinkedHashMap'),
      );
    });

    test('a simple dart file package: dependencies', () async {
      resolver = await resolveSource(r'''
        library example;

        import 'package:collection/collection.dart';

        abstract class Foo implements Equality {}
      ''');
      var libExample = resolver.getLibraryByName('example');
      var classFoo = libExample.getType('Foo');
      expect(
        classFoo.allSupertypes.map(_toStringId),
        contains('asset:collection#Equality'),
      );
    });
  });
}

String _toStringId(InterfaceType t) =>
    '${t.element.source.uri.toString().split('/').first}#${t.name}';
