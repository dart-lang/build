// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_contract_weaver/src/immutability_detector.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';

void main() {
  bool isImmutable(String source) => ImmutabilityDetector.isImmutable(
    parseString(content: source).unit.declarations.single as ClassDeclaration,
  );

  group('ImmutabilityDetector', () {
    test('trusts built_value classes', () {
      expect(
        isImmutable('abstract class V implements Built<V, VBuilder> {}'),
        isTrue,
      );
    });

    test('accepts final fields of immutable types', () {
      expect(
        isImmutable('''
class C {
  static int count = 0;
  final int a;
  final String b;
  final BuiltList<int> c;
}
'''),
        isTrue,
      );
    });

    test('rejects a class with no instance fields', () {
      // It might hold its state elsewhere, for example in an Expando.
      expect(isImmutable('class C { static int count = 0; }'), isFalse);
    });

    test('rejects a non-final field', () {
      expect(isImmutable('class C { final int a; int b; }'), isFalse);
    });

    for (final type in [
      'List<int>',
      'Set<int>',
      'Map<int, int>',
      'Queue<int>',
      'ListBuilder<int>',
      'SetBuilder<int>',
      'MapBuilder<int, int>',
      'StringBuffer',
    ]) {
      test('rejects a final field of type $type', () {
        expect(isImmutable('class C { final $type a; }'), isFalse);
      });
    }
  });
}
