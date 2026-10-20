// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'source_edit.dart';

/// Edits to one source string, collected then applied together.
class SourceEdits {
  SourceEdits(this.source);

  final String source;
  final List<SourceEdit> _edits = [];

  bool get isEmpty => _edits.isEmpty;

  /// Replaces [length] characters at [offset] with [text].
  void replace(int offset, int length, String text) {
    _edits.add(SourceEdit.of(offset, length, text));
  }

  /// Inserts [text] at [offset].
  void insert(int offset, String text) => replace(offset, 0, text);

  /// The source text from [offset] to [end].
  String textAt(int offset, int end) => source.substring(offset, end);

  /// [source] with all edits applied.
  ///
  /// Inserts at the same offset keep the order they were added in, and come
  /// before a replacement at that offset. Throws a [StateError] if two
  /// replacements overlap.
  String apply() {
    final order = List.generate(_edits.length, (i) => i)
      ..sort((a, b) {
        final byOffset = _edits[a].offset.compareTo(_edits[b].offset);
        if (byOffset != 0) return byOffset;
        final byLength = _edits[a].length.compareTo(_edits[b].length);
        if (byLength != 0) return byLength;
        return a.compareTo(b);
      });
    final result = StringBuffer();
    var position = 0;
    for (final index in order) {
      final edit = _edits[index];
      if (edit.offset < position) {
        throw StateError('Overlapping edits at offset ${edit.offset}.');
      }
      result
        ..write(source.substring(position, edit.offset))
        ..write(edit.text);
      position = edit.offset + edit.length;
    }
    result.write(source.substring(position));
    return result.toString();
  }
}
