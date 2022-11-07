// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Increase timeouts on this test which resolves source code and can be slow.
@Timeout.factor(2.0)
import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  // Resolved top-level types from dart:core and dart:collection.
  late InterfaceType staticUri;
  late InterfaceType staticMap;
  late InterfaceType staticHashMap;
  late InterfaceType staticUnmodifiableListView;
  late InterfaceType staticEnum;
  late TypeChecker staticIterableChecker;
  late TypeChecker staticMapChecker;
  late TypeChecker staticMapMixinChecker;
  late TypeChecker staticHashMapChecker;
  late TypeChecker staticEnumChecker;

  // Resolved top-level types from package:source_gen.
  late InterfaceType staticGenerator;
  late InterfaceType staticGeneratorForAnnotation;
  late TypeChecker staticGeneratorChecker;
  late TypeChecker staticGeneratorForAnnotationChecker;

  // Resolved top-level types from this file
  late InterfaceType staticMapMixin;
  late InterfaceType staticMyEnum;

  setUpAll(() async {
    late LibraryElement core;
    late LibraryElement collection;
    late LibraryReader sourceGen;
    late LibraryElement testSource;
    await resolveSource(
      r'''
      export 'package:source_gen/source_gen.dart';
      export 'type_checker_test.dart' show NonPublic;
    ''',
      (resolver) async {
        core = (await resolver.findLibraryByName('dart.core'))!;
        collection = (await resolver.findLibraryByName('dart.collection'))!;
        sourceGen = LibraryReader(
          await resolver
              .libraryFor(AssetId('source_gen', 'lib/source_gen.dart')),
        );
        testSource = await resolver
            .libraryFor(AssetId('source_gen', 'test/type_checker_test.dart'));
      },
      inputId: AssetId('source_gen', 'test/example.dart'),
    );

    final staticIterable = core.getClass('Iterable')!.instantiate(
      typeArguments: [core.typeProvider.dynamicType],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    staticIterableChecker = TypeChecker.fromStatic(staticIterable);
    staticUri = core.getClass('Uri')!.instantiate(
      typeArguments: [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    staticMap = core.getClass('Map')!.instantiate(
      typeArguments: [
        core.typeProvider.dynamicType,
        core.typeProvider.dynamicType
      ],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    staticMapChecker = TypeChecker.fromStatic(staticMap);
    staticEnum = core.getClass('Enum')!.instantiate(
      typeArguments: [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    staticEnumChecker = TypeChecker.fromStatic(staticEnum);
    staticMapMixin =
        (testSource.exportNamespace.get('MyMapMixin')! as InterfaceElement)
            .instantiate(
      typeArguments: [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    staticMapMixinChecker = TypeChecker.fromStatic(staticMapMixin);
    staticMyEnum =
        (testSource.exportNamespace.get('MyEnum')! as InterfaceElement)
            .instantiate(
      typeArguments: [],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    staticHashMap = collection.getClass('HashMap')!.instantiate(
      typeArguments: [
        core.typeProvider.dynamicType,
        core.typeProvider.dynamicType
      ],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    staticHashMapChecker = TypeChecker.fromStatic(staticHashMap);
    staticUnmodifiableListView =
        collection.getClass('UnmodifiableListView')!.instantiate(
      typeArguments: [core.typeProvider.dynamicType],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    staticGenerator = sourceGen.findType('Generator')!.instantiate(
      typeArguments: [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    staticGeneratorChecker = TypeChecker.fromStatic(staticGenerator);
    staticGeneratorForAnnotation =
        sourceGen.findType('GeneratorForAnnotation')!.instantiate(
      typeArguments: [core.typeProvider.dynamicType],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    staticGeneratorForAnnotationChecker =
        TypeChecker.fromStatic(staticGeneratorForAnnotation);
  });

  // Run a common set of type comparison checks with various implementations.
  void commonTests({
    required TypeChecker Function() checkIterable,
    required TypeChecker Function() checkEnum,
    required TypeChecker Function() checkMap,
    required TypeChecker Function() checkMapMixin,
    required TypeChecker Function() checkHashMap,
    required TypeChecker Function() checkGenerator,
    required TypeChecker Function() checkGeneratorForAnnotation,
  }) {
    group('(Iterable)', () {
      test('should be assignable from dart:collection#UnmodifiableListView',
          () {
        expect(
          checkIterable().isAssignableFromType(staticUnmodifiableListView),
          true,
        );
      });
    });

    group('(Enum)', () {
      test('should be supertype of enum classes', () {
        expect(checkEnum().isSuperTypeOf(staticMyEnum), isTrue);
      });
    });

    group(
      '(MapMixin',
      () {
        test('should equal MapMixin class', () {
          expect(checkMapMixin().isExactlyType(staticMapMixin), isTrue);
          expect(checkMapMixin().isExactly(staticMapMixin.element), isTrue);
        });
      },
      onPlatform: const {
        'windows': Skip('https://github.com/dart-lang/source_gen/issues/573'),
      },
    );

    group('(Map)', () {
      test('should equal dart:core#Map', () {
        expect(
          checkMap().isExactlyType(staticMap),
          isTrue,
          reason: '${checkMap()} != ${staticMap.element.name}',
        );
      });

      test('should not be a super type of dart:core#Map', () {
        expect(checkMap().isSuperTypeOf(staticMap), isFalse);
      });

      test('should not equal dart:core#HashMap', () {
        expect(
          checkMap().isExactlyType(staticHashMap),
          isFalse,
          reason: '${checkMap()} == $staticHashMapChecker',
        );
      });

      test('should be a super type of dart:collection#HashMap', () {
        expect(checkMap().isSuperTypeOf(staticHashMap), isFalse);
      });

      test('should be assignable from dart:collection#HashMap', () {
        expect(checkMap().isAssignableFromType(staticHashMap), isTrue);
      });

      test('should be assignable from dart:collection#MapMixin', () {
        expect(checkMap().isAssignableFromType(staticMapMixin), isTrue);
      });

      // Ensure we're consistent WRT generic types
      test('should be assignable from Map<String, String>', () {
        // Using Uri.queryParameters to get a Map<String, String>
        final stringStringMapType =
            staticUri.getGetter('queryParameters')!.returnType;

        expect(checkMap().isAssignableFromType(stringStringMapType), isTrue);
        expect(checkMap().isExactlyType(stringStringMapType), isTrue);
      });
    });

    group('(HashMap)', () {
      test('should equal dart:collection#HashMap', () {
        expect(
          checkHashMap().isExactlyType(staticHashMap),
          isTrue,
          reason: '${checkHashMap()} != $staticHashMapChecker',
        );
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
        expect(
          checkGenerator().isExactlyType(staticGenerator),
          isTrue,
          reason: '${checkGenerator()} != ${staticGenerator.element.name}',
        );
      });

      test('should not be a super type of Generator', () {
        expect(
          checkGenerator().isSuperTypeOf(staticGenerator),
          isFalse,
          reason: '${checkGenerator()} is super of '
              '${staticGenerator.element.name}',
        );
      });

      test('should be a super type of GeneratorForAnnotation', () {
        expect(
          checkGenerator().isSuperTypeOf(staticGeneratorForAnnotation),
          isTrue,
          reason: '${checkGenerator()} is not super of '
              '${staticGeneratorForAnnotation.element.name}',
        );
      });

      test('should be assignable from GeneratorForAnnotation', () {
        expect(
          checkGenerator().isAssignableFromType(staticGeneratorForAnnotation),
          isTrue,
          reason: '${checkGenerator()} is not assignable from '
              '${staticGeneratorForAnnotation.element.name}',
        );
      });
    });
  }

  group('TypeChecker.forRuntime', () {
    commonTests(
      checkIterable: () => const TypeChecker.fromRuntime(Iterable),
      checkEnum: () => const TypeChecker.fromRuntime(Enum),
      checkMap: () => const TypeChecker.fromRuntime(Map),
      checkMapMixin: () => const TypeChecker.fromRuntime(MyMapMixin),
      checkHashMap: () => const TypeChecker.fromRuntime(HashMap),
      checkGenerator: () => const TypeChecker.fromRuntime(Generator),
      checkGeneratorForAnnotation: () =>
          const TypeChecker.fromRuntime(GeneratorForAnnotation),
    );
  });

  group('TypeChecker.forStatic', () {
    commonTests(
      checkIterable: () => staticIterableChecker,
      checkEnum: () => staticEnumChecker,
      checkMap: () => staticMapChecker,
      checkMapMixin: () => staticMapMixinChecker,
      checkHashMap: () => staticHashMapChecker,
      checkGenerator: () => staticGeneratorChecker,
      checkGeneratorForAnnotation: () => staticGeneratorForAnnotationChecker,
    );
  });

  group('TypeChecker.fromUrl', () {
    commonTests(
      checkIterable: () => const TypeChecker.fromUrl('dart:core#Iterable'),
      checkEnum: () => const TypeChecker.fromUrl('dart:core#Enum'),
      checkMap: () => const TypeChecker.fromUrl('dart:core#Map'),
      checkMapMixin: () => const TypeChecker.fromUrl(
        'asset:source_gen/test/type_checker_test.dart#MyMapMixin',
      ),
      checkHashMap: () => const TypeChecker.fromUrl('dart:collection#HashMap'),
      checkGenerator: () => const TypeChecker.fromUrl(
        'package:source_gen/src/generator.dart#Generator',
      ),
      checkGeneratorForAnnotation: () => const TypeChecker.fromUrl(
        'package:source_gen/src/generator_for_annotation.dart#GeneratorForAnnotation',
      ),
    );
  });

  test('should fail gracefully when something is not resolvable', () async {
    final library = await resolveSource(
      r'''
      library _test;

      @depracated // Intentionally mispelled.
      class X {}
    ''',
      (resolver) async => (await resolver.findLibraryByName('_test'))!,
    );
    final classX = library.getClass('X')!;
    const $deprecated = TypeChecker.fromRuntime(Deprecated);

    expect(
      () => $deprecated.annotationsOf(classX),
      throwsA(
        const TypeMatcher<UnresolvedAnnotationException>().having(
          (e) => e.toString(),
          'toString',
          allOf(
            contains('Could not resolve annotation for `class X`.'),
            contains('@depracated'),
          ),
        ),
      ),
    );
  });

  test('should check multiple checkers', () {
    const listOrMap = TypeChecker.any([
      TypeChecker.fromRuntime(List),
      TypeChecker.fromRuntime(Map),
    ]);
    expect(listOrMap.isExactlyType(staticMap), isTrue);
  });

  group('should find annotations', () {
    late TypeChecker $A;
    late TypeChecker $B;
    late TypeChecker $C;

    late ClassElement $ExampleOfA;
    late ClassElement $ExampleOfMultiA;
    late ClassElement $ExampleOfAPlusB;
    late ClassElement $ExampleOfBPlusC;

    setUpAll(() async {
      final library = await resolveSource(
        r'''
      library _test;

      @A()
      class ExampleOfA {}

      @A()
      @A()
      class ExampleOfMultiA {}

      @A()
      @B()
      class ExampleOfAPlusB {}

      @B()
      @C()
      class ExampleOfBPlusC {}

      class A {
        const A();
      }

      class B {
        const B();
      }

      class C extends B {
        const C();
      }
    ''',
        (resolver) async => (await resolver.findLibraryByName('_test'))!,
      );

      $A = TypeChecker.fromStatic(
        library.getClass('A')!.instantiate(
          typeArguments: [],
          nullabilitySuffix: NullabilitySuffix.none,
        ),
      );
      $B = TypeChecker.fromStatic(
        library.getClass('B')!.instantiate(
          typeArguments: [],
          nullabilitySuffix: NullabilitySuffix.none,
        ),
      );
      $C = TypeChecker.fromStatic(
        library.getClass('C')!.instantiate(
          typeArguments: [],
          nullabilitySuffix: NullabilitySuffix.none,
        ),
      );
      $ExampleOfA = library.getClass('ExampleOfA')!;
      $ExampleOfMultiA = library.getClass('ExampleOfMultiA')!;
      $ExampleOfAPlusB = library.getClass('ExampleOfAPlusB')!;
      $ExampleOfBPlusC = library.getClass('ExampleOfBPlusC')!;
    });

    test('of a single @A', () {
      expect($A.hasAnnotationOf($ExampleOfA), isTrue);
      final aAnnotation = $A.firstAnnotationOf($ExampleOfA)!;
      expect(aAnnotation.type!.element!.name, 'A');
      expect($B.annotationsOf($ExampleOfA), isEmpty);
      expect($C.annotationsOf($ExampleOfA), isEmpty);
    });

    test('of a multiple @A', () {
      final aAnnotations = $A.annotationsOf($ExampleOfMultiA);
      expect(aAnnotations.map((a) => a.type!.element!.name), ['A', 'A']);
      expect($B.annotationsOf($ExampleOfA), isEmpty);
      expect($C.annotationsOf($ExampleOfA), isEmpty);
    });

    test('of a single @A + single @B', () {
      final aAnnotations = $A.annotationsOf($ExampleOfAPlusB);
      expect(aAnnotations.map((a) => a.type!.element!.name), ['A']);
      final bAnnotations = $B.annotationsOf($ExampleOfAPlusB);
      expect(bAnnotations.map((a) => a.type!.element!.name), ['B']);
      expect($C.annotationsOf($ExampleOfAPlusB), isEmpty);
    });

    test('of a single @B + single @C', () {
      final cAnnotations = $C.annotationsOf($ExampleOfBPlusC);
      expect(cAnnotations.map((a) => a.type!.element!.name), ['C']);
      final bAnnotations = $B.annotationsOf($ExampleOfBPlusC);
      expect(bAnnotations.map((a) => a.type!.element!.name), ['B', 'C']);
      expect($B.hasAnnotationOfExact($ExampleOfBPlusC), isTrue);
      final bExact = $B.annotationsOfExact($ExampleOfBPlusC);
      expect(bExact.map((a) => a.type!.element!.name), ['B']);
    });
  });

  group('unresolved annotations', () {
    late TypeChecker $A;
    late ClassElement $ExampleOfA;
    late ParameterElement $annotatedParameter;

    setUpAll(() async {
      final library = await resolveSource(
        r'''
      library _test;

      // Put the missing annotation first so it throws.
      @B()
      @A()
      class ExampleOfA {}

      void annotatedParameter(@B() @A() String parameter) {}

      class A {
        const A();
      }
    ''',
        (resolver) async => (await resolver.findLibraryByName('_test'))!,
      );
      $A = TypeChecker.fromStatic(
        library.getClass('A')!.instantiate(
          typeArguments: [],
          nullabilitySuffix: NullabilitySuffix.none,
        ),
      );
      $ExampleOfA = library.getClass('ExampleOfA')!;
      $annotatedParameter = library.topLevelElements
          .whereType<FunctionElement>()
          .firstWhere((f) => f.name == 'annotatedParameter')
          .parameters
          .single;
    });

    test('should throw by default', () {
      expect(
        () => $A.firstAnnotationOf($ExampleOfA),
        throwsUnresolvedAnnotationException,
      );
      expect(
        () => $A.annotationsOf($ExampleOfA),
        throwsUnresolvedAnnotationException,
      );
      expect(
        () => $A.firstAnnotationOfExact($ExampleOfA),
        throwsUnresolvedAnnotationException,
      );
      expect(
        () => $A.annotationsOfExact($ExampleOfA),
        throwsUnresolvedAnnotationException,
      );
      expect(
        () => $A.firstAnnotationOf($annotatedParameter),
        throwsUnresolvedAnnotationException,
      );
      expect(
        () => $A.annotationsOf($annotatedParameter),
        throwsUnresolvedAnnotationException,
      );
      expect(
        () => $A.firstAnnotationOfExact($annotatedParameter),
        throwsUnresolvedAnnotationException,
      );
      expect(
        () => $A.annotationsOfExact($annotatedParameter),
        throwsUnresolvedAnnotationException,
      );
    });

    test('should not throw if `throwOnUnresolved` == false', () {
      expect(
        $A
            .firstAnnotationOf($ExampleOfA, throwOnUnresolved: false)!
            .type!
            .element!
            .name,
        'A',
      );
      expect(
        $A
            .annotationsOf($ExampleOfA, throwOnUnresolved: false)
            .map((a) => a.type!.element!.name),
        ['A'],
      );
      expect(
        $A
            .firstAnnotationOfExact($ExampleOfA, throwOnUnresolved: false)!
            .type!
            .element!
            .name,
        'A',
      );
      expect(
        $A
            .annotationsOfExact($ExampleOfA, throwOnUnresolved: false)
            .map((a) => a.type!.element!.name),
        ['A'],
      );
    });
  });
}

final throwsUnresolvedAnnotationException = throwsA(
  const TypeMatcher<UnresolvedAnnotationException>()
      .having((e) => e.annotationSource, 'annotationSource', isNotNull),
);

// Not using `dart.collection#MapMixin` because we want to test elements
// actually declared as a `mixin`.
mixin MyMapMixin on Map<dynamic, dynamic> {}

enum MyEnum { foo, bar }
