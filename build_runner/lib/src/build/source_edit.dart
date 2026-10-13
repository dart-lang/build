// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
}
