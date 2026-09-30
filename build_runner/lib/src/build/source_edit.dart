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

    // Inserted text uses the line ending of the first line.
    final eol = source.startsWith('\r\n', source.lineEnd(0)) ? '\r\n' : '\n';

    // After the last directive and any comment on the same line. Parts come
    // after imports and exports, so this is after the last part if there are
    // any; if not, the directive starts a section of its own.
    if (unit.directives.isNotEmpty) {
      final separator = parts.isEmpty ? '$eol$eol' : eol;
      return SourceEdit.of(
        offset: source.lineEnd(unit.directives.last.end),
        length: 0,
        replacement: '$separator$directive',
      );
    }

    // Before the first declaration and the comments that belong to it. File
    // header comments, such as a license, stay first: these are the comments
    // followed by a blank line. The comments with no blank line before the
    // declaration, such as `// ignore:` comments, belong to it and must stay
    // with it. The language version comment is always a file header comment,
    // even with no blank line after it.
    if (unit.declarations.isNotEmpty) {
      final declaration = unit.declarations.first;
      final firstToken = declaration.metadata.isEmpty
          ? declaration.firstTokenAfterCommentAndMetadata
          : declaration.metadata.first.beginToken;
      var offset = firstToken.offset;
      for (final comment in firstToken.precedingCommentList.reversed) {
        if (comment.offset == unit.languageVersionToken?.offset) break;
        if (source.hasBlankLine(comment.end, offset)) break;
        offset = comment.offset;
      }
      return SourceEdit.of(
        offset: offset,
        length: 0,
        replacement: '$directive$eol$eol',
      );
    }

    // At the end.
    final newline = source.isEmpty || source.endsWith('\n') ? '' : eol;
    return SourceEdit.of(
      offset: source.length,
      length: 0,
      replacement: '$newline$directive$eol',
    );
  }
}

extension on String {
  /// The end of the line containing [offset], before its line ending.
  ///
  /// Lines end with `\n` or `\r\n`; files can mix them.
  int lineEnd(int offset) {
    final newline = indexOf('\n', offset);
    if (newline == -1) return length;
    return newline > 0 && this[newline - 1] == '\r' ? newline - 1 : newline;
  }

  /// Whether there is a blank line between [start] and [end], which must
  /// contain only whitespace.
  bool hasBlankLine(int start, int end) {
    final first = indexOf('\n', start);
    if (first == -1 || first >= end) return false;
    final second = indexOf('\n', first + 1);
    return second != -1 && second < end;
  }
}

extension on Token {
  /// The comments before this token, in source order.
  List<Token> get precedingCommentList {
    final result = <Token>[];
    for (
      Token? comment = precedingComments;
      comment != null;
      comment = comment.next
    ) {
      result.add(comment);
    }
    return result;
  }
}
