// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'glob_id.g.dart';

/// Unique ID for a glob evaluation.
abstract class GlobId implements Built<GlobId, GlobIdBuilder> {
  static Serializer<GlobId> get serializer => _$globIdSerializer;

  String get package;
  String get glob;
  int get phaseNumber;

  factory GlobId({
    required String package,
    required String glob,
    required int phaseNumber,
  }) = _$GlobId._;
  GlobId._();
}
