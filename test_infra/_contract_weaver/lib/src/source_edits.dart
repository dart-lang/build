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
  /// Edits are applied from the end backwards, so that offsets stay valid.
  /// Edits at the same offset are applied in the order they were added, so
  /// the text of the last one added comes first.
  String apply() {
    final order = List.generate(_edits.length, (i) => i)
      ..sort((a, b) {
        final byOffset = _edits[b].offset.compareTo(_edits[a].offset);
        return byOffset != 0 ? byOffset : a.compareTo(b);
      });
    var result = source;
    for (final index in order) {
      final edit = _edits[index];
      result =
          result.substring(0, edit.offset) +
          edit.text +
          result.substring(edit.offset + edit.length);
    }
    return result;
  }
}
