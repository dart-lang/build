// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/element/type.dart';
import 'package:build_test/build_test.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  // Resolved top-level types from dart:core and dart:collection.
  DartType staticMap;
  DartType staticHashMap;
  TypeChecker staticMapChecker;
  TypeChecker staticHashMapChecker;

  setUpAll(() async {
    final resolver = await resolveSource('');

    final core = resolver.getLibraryByName('dart.core');
    staticMap = core.getType('Map').type;
    staticMapChecker = new TypeChecker.fromStatic(staticMap);

    final collection = resolver.getLibraryByName('dart.collection');
    staticHashMap = collection.getType('HashMap').type;
    staticHashMapChecker = new TypeChecker.fromStatic(staticHashMap);
  });

  // Run a common set of type comparison checks with various implementations.
  void commonTests({
    @required TypeChecker checkMap(),
    @required TypeChecker checkHashMap(),
  }) {
    group('(Map)', () {
      test('should equal dart:core#Map', () {
        expect(checkMap().isExactlyType(staticMap), isTrue,
            reason: '${checkMap()} != $staticMap');
      });

      test('should not be a super type of dart:core#Map', () {
        expect(checkMap().isSuperTypeOf(staticMap), isFalse);
      });

      test('should not equal dart:core#HashMap', () {
        expect(checkMap().isExactlyType(staticHashMap), isFalse,
            reason: '${checkMap()} == $staticHashMapChecker');
      });

      test('should be a super type of dart:collection#HashMap', () {
        expect(checkMap().isSuperTypeOf(staticHashMap), isTrue);
      });

      test('should be assignable from dart:collection#HashMap', () {
        expect(checkMap().isAssignableFromType(staticHashMap), isTrue);
      });
    });

    group('(HashMap)', () {
      test('should equal dart:collection#HashMap', () {
        expect(checkHashMap().isExactlyType(staticHashMap), isTrue,
            reason: '${checkHashMap()} != $staticHashMapChecker');
      });

      test('should not be a super type of dart:core#Map', () {
        expect(checkHashMap().isSuperTypeOf(staticMap), isFalse);
      });

      test('should not assignable from type dart:core#Map', () {
        expect(checkHashMap().isAssignableFromType(staticMap), isFalse);
      });
    });
  }

  group('TypeChecker.forRuntime', () {
    commonTests(
        checkMap: () => const TypeChecker.fromRuntime(Map),
        checkHashMap: () => const TypeChecker.fromRuntime(HashMap));
  });

  group('TypeChecker.forStatic', () {
    commonTests(
        checkMap: () => staticMapChecker,
        checkHashMap: () => staticHashMapChecker);
  });

  group('TypeChecker.fromUrl', () {
    commonTests(
        checkMap: () => const TypeChecker.fromUrl('dart:core#Map'),
        checkHashMap: () =>
            const TypeChecker.fromUrl('dart:collection#HashMap'));
  });
}
