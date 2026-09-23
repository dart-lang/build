// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_contract_weaver/src/mutation_detector.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';

void main() {
  /// Whether the single member of a class with body [member] might mutate.
  bool mightMutate(String member) {
    final unit = parseString(content: 'class C {\n$member\n}').unit;
    final declaration = unit.declarations.single as ClassDeclaration;
    final body = declaration.body as BlockClassBody;
    return MutationDetector.mightMutateState(
      body.members.single as MethodDeclaration,
    );
  }

  group('MutationDetector', () {
    for (final member in [
      'int f() => a + b;',
      'bool f() { final x = items.contains(1); return x; }',
      'int f() => items.length;',
      'String f() => toString();',
    ]) {
      test('treats `$member` as read only', () {
        expect(mightMutate(member), isFalse);
      });
    }

    for (final member in [
      'set f(int v) {}',
      'void f() { a = 1; }',
      'void f() { a += 1; }',
      'void f() { a++; }',
      'void f() { --a; }',
      'void f() { items.add(1); }',
      'void f() { cache.removeWhere((_) => true); }',
      'void f() { if (x) { state.markDirty(); } }',
      // A closure that is never called still counts: no flow analysis.
      'void f() { final g = () => items.clear(); }',
      // A local variable is not the object, but there is no resolution to
      // tell them apart.
      'void f() { var i = 0; i++; }',
    ]) {
      test('treats `$member` as mutating', () {
        expect(mightMutate(member), isTrue);
      });
    }
  });
}
