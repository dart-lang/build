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

/// `part` directives for generated code: finding missing and unused ones,
/// and adding and removing them.
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
      if (addEdit(content.stringValue(), libraryId.sharedPartUri!) == null) {
        continue;
      }
      result[libraryId] = md5.convert(content.bytes);
    }
    return result.build();
  }

  /// Libraries with a `part` directive for a shared part that is not written,
  /// because every builder that adds to the library succeeded and chose to
  /// write nothing.
  ///
  /// A library with no builder that adds to it is not included: then nothing
  /// says whether the directive is used.
  ///
  /// Values are the md5 digests of the library content that was checked.
  static Future<BuiltMap<AssetId, Digest>> findUnused(
    BuildState buildState,
    BuilderFilesystem filesystem,
  ) async {
    final plan = buildState.buildStepPlan;
    final phases = plan.buildPhases.inBuildPhases;
    final allSucceeded = <AssetId, bool>{};
    for (var phase = 0; phase != phases.length; ++phase) {
      if (!phases[phase].addsToLibrary) continue;
      for (final step in plan.buildStepsByPhase[phase]) {
        final succeeded = buildState.stepResultOrNull(step)?.succeeded ?? false;
        allSucceeded.update(
          step.primaryInput,
          (previous) => previous && succeeded,
          ifAbsent: () => succeeded,
        );
      }
    }

    final result = <AssetId, Digest>{};
    for (final MapEntry(key: libraryId, value: succeeded)
        in allSucceeded.entries) {
      if (!succeeded || buildState.hasSharedPart(libraryId)) continue;
      // Generated libraries are owned by the builder that generates them.
      if (!buildState.isSource(libraryId)) continue;
      final partUri = libraryId.sharedPartUri;
      if (partUri == null) continue;
      final content = await filesystem.contentOf(libraryId);
      final source = content.stringValue();
      // Most libraries do not mention the part, so check that before parsing.
      if (!source.contains(partUri)) continue;
      if (removeEdit(source, partUri) == null) continue;
      result[libraryId] = md5.convert(content.bytes);
    }
    return result.build();
  }

  /// Reports [libraries] as missing the `part` directive for their generated
  /// code and, unless [onlyCheck], adds it.
  ///
  /// [libraries] is as returned by [findMissing]; see [_edit].
  static Future<void> addMissing(
    BuiltMap<AssetId, Digest> libraries,
    ReaderWriter readerWriter, {
    required bool onlyCheck,
  }) => _edit(
    libraries,
    readerWriter,
    onlyCheck: onlyCheck,
    edit: addEdit,
    check: 'Add missing `part` directives for generated code:',
    edited: 'Added missing `part` directives for generated code:',
    changedDuringBuild:
        'Not adding missing `part` directives to libraries that changed '
        'during the build:',
  );

  /// Reports [libraries] as having an unused `part` directive for generated
  /// code and, unless [onlyCheck], removes it.
  ///
  /// [libraries] is as returned by [findUnused]; see [_edit].
  static Future<void> removeUnused(
    BuiltMap<AssetId, Digest> libraries,
    ReaderWriter readerWriter, {
    required bool onlyCheck,
  }) => _edit(
    libraries,
    readerWriter,
    onlyCheck: onlyCheck,
    edit: removeEdit,
    check: 'Remove unused `part` directives for generated code:',
    edited: 'Removed unused `part` directives for generated code:',
    changedDuringBuild:
        'Not removing unused `part` directives from libraries that changed '
        'during the build:',
  );

  /// Applies [edit] to [libraries] and reports it, or with [onlyCheck] only
  /// reports what to do.
  ///
  /// [libraries] maps each library to the md5 digest of the content that was
  /// checked. A library that changed since then is not edited: the finding is
  /// stale, and the next build decides again. `build` reruns with the library
  /// as an update, and `watch` builds because of the change.
  ///
  /// [check], [edited] and [changedDuringBuild] are the headings of the
  /// reports.
  static Future<void> _edit(
    BuiltMap<AssetId, Digest> libraries,
    ReaderWriter readerWriter, {
    required bool onlyCheck,
    required SourceEdit? Function(String source, String partUri) edit,
    required String check,
    required String edited,
    required String changedDuringBuild,
  }) async {
    String directive(AssetId id) =>
        "${buildLog.renderId(id)}: part '${id.sharedPartUri}';";
    String lines(Iterable<AssetId> ids, String Function(AssetId) render) =>
        (ids.map(render).toList()..sort()).join('\n');

    if (onlyCheck) {
      buildLog.error('$check\n\n${lines(libraries.keys, directive)}');
      return;
    }
    final editedIds = <AssetId>[];
    final changedDuringBuildIds = <AssetId>[];
    for (final MapEntry(key: id, value: digest) in libraries.entries) {
      final bytes = await readerWriter.readAsBytes(id);
      if (md5.convert(bytes) != digest) {
        changedDuringBuildIds.add(id);
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
      editedIds.add(id);
    }
    if (editedIds.isNotEmpty) {
      buildLog.error('$edited\n\n${lines(editedIds, directive)}');
    }
    if (changedDuringBuildIds.isNotEmpty) {
      buildLog.error(
        '$changedDuringBuild\n\n'
        '${lines(changedDuringBuildIds, buildLog.renderId)}',
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
  static SourceEdit? addEdit(String source, String partUri) {
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

  /// The edit that removes `part '$partUri';` from library [source], or
  /// `null` if [source] does not have it or it is not safe to remove.
  ///
  /// It is not safe to remove if [source] has parse errors, or if the
  /// directive has metadata or a doc comment: these belong to the library,
  /// and without the directive they would belong to whatever follows.
  ///
  /// Removes the line of the directive, including any `//` comment after it,
  /// unless the line has other code or another kind of comment. A blank line
  /// left next to another blank line, or at the start or end of the file, is
  /// removed too, so that removing what [addEdit] added gives back the
  /// original source.
  static SourceEdit? removeEdit(String source, String partUri) {
    final result = parseString(content: source, throwIfDiagnostics: false);
    if (result.errors.isNotEmpty) return null;
    final directive = result.unit.directives
        .whereType<PartDirective>()
        .where((part) => part.uri.stringValue == partUri)
        .firstOrNull;
    if (directive == null) return null;
    if (directive.metadata.isNotEmpty) return null;
    if (directive.documentationComment != null) return null;

    var start = source.lineStart(directive.offset);
    var end = source.lineEnd(directive.end);
    final next = directive.endToken.next!;
    final following = next.precedingCommentList.firstOrNull ?? next;

    // Other code before it on the line: remove the directive and the space
    // that separates it from that code.
    if (!source.isBlank(start, directive.offset)) {
      start = directive.offset;
      while (source[start - 1] == ' ' || source[start - 1] == '\t') {
        start--;
      }
      return SourceEdit.of(
        offset: start,
        length: directive.end - start,
        replacement: '',
      );
    }

    // Other code or a comment that is not a `//` comment after it on the
    // line: remove the directive and the space up to what follows.
    final onlyLineComments = next.precedingCommentList
        .where((comment) => comment.offset < end)
        .every(
          (comment) =>
              comment.lexeme.startsWith('//') &&
              !comment.lexeme.startsWith('///'),
        );
    if (next.offset < end || !onlyLineComments) {
      return SourceEdit.of(
        offset: directive.offset,
        length: following.offset - directive.offset,
        replacement: '',
      );
    }

    // The whole line.
    end = source.nextLineStart(end);
    final previousStart = start == 0 ? null : source.lineStart(start - 1);
    final previousIsBlank =
        previousStart != null && source.isBlank(previousStart, start);
    final nextIsBlank =
        end < source.length && source.isBlank(end, source.lineEnd(end));
    if ((start == 0 || previousIsBlank) && nextIsBlank) {
      end = source.nextLineStart(source.lineEnd(end));
    } else if (previousIsBlank && end == source.length) {
      start = previousStart;
    }
    return SourceEdit.of(offset: start, length: end - start, replacement: '');
  }
}

extension on String {
  /// The start of the line containing [offset].
  int lineStart(int offset) =>
      offset == 0 ? 0 : lastIndexOf('\n', offset - 1) + 1;

  /// The end of the line containing [offset], before its line ending.
  ///
  /// Lines end with `\n` or `\r\n`; files can mix them.
  int lineEnd(int offset) {
    final newline = indexOf('\n', offset);
    if (newline == -1) return length;
    return newline > 0 && this[newline - 1] == '\r' ? newline - 1 : newline;
  }

  /// The start of the line after the line ending at [lineEnd], or [length] if
  /// there is none.
  int nextLineStart(int lineEnd) {
    final newline = indexOf('\n', lineEnd);
    return newline == -1 ? length : newline + 1;
  }

  /// Whether there is only whitespace between [start] and [end].
  bool isBlank(int start, int end) => substring(start, end).trim().isEmpty;

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
