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

  // Resolved top-level types from package:source_gen.
  DartType staticGenerator;
  DartType staticGeneratorForAnnotation;
  TypeChecker staticGeneratorChecker;
  TypeChecker staticGeneratorForAnnotationChecker;

  setUpAll(() async {
    final resolver = await resolveSource(r'''
      export 'package:source_gen/source_gen.dart';
    ''');

    final core = resolver.getLibraryByName('dart.core');
    staticMap = core.getType('Map').type;
    staticMapChecker = new TypeChecker.fromStatic(staticMap);

    final collection = resolver.getLibraryByName('dart.collection');
    staticHashMap = collection.getType('HashMap').type;
    staticHashMapChecker = new TypeChecker.fromStatic(staticHashMap);

    final sourceGen =
        new LibraryReader(resolver.getLibraryByName('source_gen'));
    staticGenerator = sourceGen.findType('Generator').type;
    staticGeneratorChecker = new TypeChecker.fromStatic(staticGenerator);
    staticGeneratorForAnnotation =
        sourceGen.findType('GeneratorForAnnotation').type;
    staticGeneratorForAnnotationChecker =
        new TypeChecker.fromStatic(staticGeneratorForAnnotation);
  });

  // Run a common set of type comparison checks with various implementations.
  void commonTests({
    @required TypeChecker checkMap(),
    @required TypeChecker checkHashMap(),
    @required TypeChecker checkGenerator(),
    @required TypeChecker checkGeneratorForAnnotation(),
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

    group('(Generator)', () {
      test('should equal Generator', () {
        expect(checkGenerator().isExactlyType(staticGenerator), isTrue,
            reason: '${checkGenerator()} != $staticGenerator');
      });

      test('should not be a super type of Generator', () {
        expect(checkGenerator().isSuperTypeOf(staticGenerator), isFalse,
            reason: '${checkGenerator()} is super of $staticGenerator');
      });

      test('should be a super type of GeneratorForAnnotation', () {
        expect(checkGenerator().isSuperTypeOf(staticGeneratorForAnnotation),
            isTrue,
            reason:
                '${checkGenerator()} is not super of $staticGeneratorForAnnotation');
      });

      test('should be assignable from GeneratorForAnnotation', () {
        expect(
            checkGenerator().isAssignableFromType(staticGeneratorForAnnotation),
            isTrue,
            reason:
                '${checkGenerator()} is not assignable from $staticGeneratorForAnnotation');
      });
    });
  }

  group('TypeChecker.forRuntime', () {
    commonTests(
        checkMap: () => const TypeChecker.fromRuntime(Map),
        checkHashMap: () => const TypeChecker.fromRuntime(HashMap),
        checkGenerator: () => const TypeChecker.fromRuntime(Generator),
        checkGeneratorForAnnotation: () =>
            const TypeChecker.fromRuntime(GeneratorForAnnotation));
  });

  group('TypeChecker.forStatic', () {
    commonTests(
        checkMap: () => staticMapChecker,
        checkHashMap: () => staticHashMapChecker,
        checkGenerator: () => staticGeneratorChecker,
        checkGeneratorForAnnotation: () => staticGeneratorForAnnotationChecker);
  });

  group('TypeChecker.fromUrl', () {
    commonTests(
        checkMap: () => const TypeChecker.fromUrl('dart:core#Map'),
        checkHashMap: () =>
            const TypeChecker.fromUrl('dart:collection#HashMap'),
        checkGenerator: () => const TypeChecker.fromUrl(
            'package:source_gen/src/generator.dart#Generator'),
        checkGeneratorForAnnotation: () => const TypeChecker.fromUrl(
            'package:source_gen/src/generator_for_annotation.dart#GeneratorForAnnotation'));
  });
}
