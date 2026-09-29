// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:built_value/built_value.dart';

part 'source_edit.g.dart';

/// A replacement of [length] characters at [offset] in a source file.
abstract class SourceEdit implements Built<SourceEdit, SourceEditBuilder> {
  int get offset;
  int get length;
  String get replacement;

  SourceEdit._();
  factory SourceEdit([void Function(SourceEditBuilder) updates]) = _$SourceEdit;

  /// Creates a [SourceEdit] from its fields.
  factory SourceEdit.of({
    required int offset,
    required int length,
    required String replacement,
  }) =>
      _$SourceEdit._(offset: offset, length: length, replacement: replacement);

  /// The edit that adds `part '$partUri';` to library [source], or `null` if
  /// [source] already has it.
  ///
  /// The directive goes after every other `part` directive. With
  /// augmentations, `part` directive order can matter, and last is always
  /// correct. The directive is only added if missing, so tools that later
  /// reorder directives are not fought.
  static SourceEdit? ensurePartDirective(String source, String partUri) {
    final unit = parseString(content: source, throwIfDiagnostics: false).unit;
    final directive = "part '$partUri';";
    final parts = unit.directives.whereType<PartDirective>();
    if (parts.any((part) => part.uri.stringValue == partUri)) return null;
    final eol = source.contains('\r\n') ? '\r\n' : '\n';

    // After the last directive and any comment on the same line. Parts come
    // after imports and exports, so this is after the last part if there are
    // any; if not, the directive starts a section of its own.
    if (unit.directives.isNotEmpty) {
      final lineEnd = source.indexOf(eol, unit.directives.last.end);
      final separator = parts.isEmpty ? '$eol$eol' : eol;
      return SourceEdit.of(
        offset: lineEnd == -1 ? source.length : lineEnd,
        length: 0,
        replacement: '$separator$directive',
      );
    }

    // Before the first declaration and the comments attached to it, meaning
    // those with no blank line between them and the declaration. The language
    // version comment must stay first, so it is never attached.
    if (unit.declarations.isNotEmpty) {
      final declaration = unit.declarations.first;
      final firstToken = declaration.metadata.isEmpty
          ? declaration.firstTokenAfterCommentAndMetadata
          : declaration.metadata.first.beginToken;
      final comments = <Token>[];
      for (
        Token? comment = firstToken.precedingComments;
        comment != null;
        comment = comment.next
      ) {
        comments.add(comment);
      }
      var offset = firstToken.offset;
      for (final comment in comments.reversed) {
        if (comment.offset == unit.languageVersionToken?.offset) break;
        final gap = source.substring(comment.end, offset);
        if (eol.allMatches(gap).length > 1) break;
        offset = comment.offset;
      }
      return SourceEdit.of(
        offset: offset,
        length: 0,
        replacement: '$directive$eol$eol',
      );
    }

    // At the end.
    final newline = source.isEmpty || source.endsWith(eol) ? '' : eol;
    return SourceEdit.of(
      offset: source.length,
      length: 0,
      replacement: '$newline$directive$eol',
    );
  }
}
