// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_contract_weaver/src/clause_reader.dart';
import 'package:_contract_weaver/src/member_contract.dart';
import 'package:_contract_weaver/src/throw_clauses.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';

void main() {
  /// The contract on the single function declared in [source].
  MemberContract read(String source) {
    final unit = parseString(content: source).unit;
    final function = unit.declarations.single as FunctionDeclaration;
    return ClauseReader(source).read(function.metadata);
  }

  group('ClauseReader', () {
    test('reads nothing from an unannotated function', () {
      expect(read('void f() {}'), MemberContract());
    });

    test('ignores annotations with other names', () {
      expect(
        read('''
@override
@Deprecated('x')
void f() {}
'''),
        MemberContract(),
      );
    });

    test('reads clauses in annotation order', () {
      expect(
        read('''
@Requires('a')
@Ensures('c')
@Requires('b')
@Ensures('d')
int f(int x) => x;
'''),
        MemberContract(
          (b) => b
            ..preconditions.addAll(['a', 'b'])
            ..postconditions.addAll(['c', 'd']),
        ),
      );
    });

    test('groups @ThrowEnsures by type, in order of first appearance', () {
      expect(
        read('''
@ThrowEnsures(StateError, 'a')
@ThrowEnsures(ArgumentError, 'b')
@ThrowEnsures(StateError, 'c')
void f() {}
'''),
        MemberContract(
          (b) => b.throwClauses.addAll([
            ThrowClauses.of(type: 'StateError', clauses: ['a', 'c']),
            ThrowClauses.of(type: 'ArgumentError', clauses: ['b']),
          ]),
        ),
      );
    });

    test('keeps the source text of a prefixed type', () {
      expect(
        read('''
@ThrowEnsures(core.StateError, 'a')
void f() {}
''').throwClauses.single.type,
        'core.StateError',
      );
    });

    test('joins adjacent string literals', () {
      expect(
        read('''
@Requires('x > 0 '
    '&& x < 10')
void f(int x) {}
''').preconditions,
        ['x > 0 && x < 10'],
      );
    });

    test('reads raw strings without escapes', () {
      expect(
        read(r'''
@Ensures(r'result.$1 > 0')
(int, int) f() => (1, 2);
''').postconditions,
        [r'result.$1 > 0'],
      );
    });

    test('reads class invariants', () {
      const source = '''
@Invariant('a')
@Requires('ignored')
@Invariant('b')
class C {}
''';
      final unit = parseString(content: source).unit;
      final declaration = unit.declarations.single as ClassDeclaration;
      expect(ClauseReader(source).invariants(declaration.metadata), ['a', 'b']);
    });

    group('rejects', () {
      for (final (description, annotation) in [
        ('no arguments', '@Requires()'),
        ('several clauses', "@Requires('a', 'b')"),
        ('a non-string clause', '@Requires(1)'),
        ('an interpolated clause', r"@Requires('$x')"),
        ('@ThrowEnsures without a clause', '@ThrowEnsures(StateError)'),
        ('@ThrowEnsures with several clauses', "@ThrowEnsures(E, 'a', 'b')"),
      ]) {
        test(description, () {
          expect(
            () => read('$annotation\nvoid f(int x) {}'),
            throwsFormatException,
          );
        });
      }
    });
  });
}
