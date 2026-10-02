// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:crypto/crypto.dart';

import '../io/reader_writer.dart';
import '../logging/build_log.dart';
import 'br_outputs.dart';
import 'build_state/build_state.dart';
import 'builder_filesystem.dart';
import 'source_edit.dart';

/// Missing `part` directives for generated code: finding, placing and adding
/// them.
abstract final class PartDirectives {
  /// Libraries that have generated code but no `part` directive including it,
  /// so the generated code has no effect.
  ///
  /// Values are the md5 digests of the library content that was checked.
  static Future<BuiltMap<AssetId, Digest>> findMissing(
    BuildState buildState,
    BuilderFilesystem filesystem,
  ) async {
    final result = <AssetId, Digest>{};
    for (final libraryId in buildState.sharedPartLibraryIds) {
      // Generated libraries are owned by the builder that generates them.
      if (!buildState.isSource(libraryId)) continue;
      if (buildState.sharedPartContent(libraryId) == null) continue;
      final content = await filesystem.contentOf(libraryId);
      if (edit(content.stringValue(), libraryId.sharedPartUri!) == null) {
        continue;
      }
      result[libraryId] = md5.convert(content.bytes);
    }
    return result.build();
  }

  /// Reports [libraries] as missing the `part` directive for their generated
  /// code and, unless [onlyCheck], adds it.
  ///
  /// [libraries] maps each library to the md5 digest of the content that was
  /// checked, as returned by [findMissing]. A library that changed since then
  /// is not edited: the finding is stale, and the next build decides again.
  /// `build` reruns with the library as an update, and `watch` builds because
  /// of the change.
  static Future<void> addMissing(
    BuiltMap<AssetId, Digest> libraries,
    ReaderWriter readerWriter, {
    required bool onlyCheck,
  }) async {
    String directive(AssetId id) =>
        "${buildLog.renderId(id)}: part '${id.sharedPartUri}';";
    String lines(Iterable<AssetId> ids, String Function(AssetId) render) =>
        (ids.map(render).toList()..sort()).join('\n');

    if (onlyCheck) {
      buildLog.error(
        'Add missing `part` directives for generated code:\n\n'
        '${lines(libraries.keys, directive)}',
      );
      return;
    }
    final edited = <AssetId>[];
    final changedDuringBuild = <AssetId>[];
    for (final MapEntry(key: id, value: digest) in libraries.entries) {
      final bytes = await readerWriter.readAsBytes(id);
      if (md5.convert(bytes) != digest) {
        changedDuringBuild.add(id);
        continue;
      }
      final source = utf8.decode(bytes);
      // The content is what was checked, so the edit is needed.
      final sourceEdit = edit(source, id.sharedPartUri!)!;
      await readerWriter.writeAsString(
        id,
        source.replaceRange(
          sourceEdit.offset,
          sourceEdit.offset + sourceEdit.length,
          sourceEdit.replacement,
        ),
      );
      edited.add(id);
    }
    if (edited.isNotEmpty) {
      buildLog.error(
        'Added missing `part` directives for generated code:\n\n'
        '${lines(edited, directive)}',
      );
    }
    if (changedDuringBuild.isNotEmpty) {
      buildLog.error(
        'Not adding missing `part` directives to libraries that changed '
        'during the build:\n\n'
        '${lines(changedDuringBuild, buildLog.renderId)}',
      );
    }
  }

  /// The edit that adds `part '$partUri';` to library [source], or `null` if
  /// [source] already has it.
  ///
  /// The directive goes after every other `part` directive. With
  /// augmentations, `part` directive order can matter, and last is always
  /// correct. The directive is only added if missing, so tools that later
  /// reorder directives are not fought.
  static SourceEdit? edit(String source, String partUri) {
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
