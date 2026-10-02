// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

/// Guesses, without resolution, whether instances of a class are immutable.
///
/// Methods of an immutable class cannot invalidate a memoized invariant check,
/// so a guess of "yes" must be safe.
class ImmutabilityDetector {
  static const _mutableTypePrefixes = [
    'Set<',
    'Map<',
    'List<',
    'Queue<',
    'MapBuilder<',
    'SetBuilder<',
    'ListBuilder<',
    'StringBuffer',
  ];

  /// Whether [node] looks immutable.
  ///
  /// A `built_value` class is. Otherwise the class must have instance fields,
  /// all final, and none of a well known mutable type.
  static bool isImmutable(ClassDeclaration node) {
    final implementsClause = node.implementsClause;
    if (implementsClause != null) {
      for (final iface in implementsClause.interfaces) {
        if (iface.name.lexeme == 'Built') return true;
      }
    }
    final body = node.body;
    if (body is! BlockClassBody) return false;
    var hasInstanceFields = false;
    for (final member in body.members) {
      if (member is FieldDeclaration && !member.isStatic) {
        hasInstanceFields = true;
        if (!member.fields.isFinal && !member.fields.isConst) {
          return false;
        }
        final typeStr = member.fields.type?.toSource() ?? '';
        if (_mutableTypePrefixes.any(typeStr.startsWith)) return false;
      }
    }
    return hasInstanceFields;
  }
}
