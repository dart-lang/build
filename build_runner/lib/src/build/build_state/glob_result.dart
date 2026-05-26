// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:crypto/crypto.dart';

part 'glob_result.g.dart';

/// Execution results and dependency tracking for a glob evaluation.
abstract class GlobResult implements Built<GlobResult, GlobResultBuilder> {
  static Serializer<GlobResult> get serializer => _$globResultSerializer;

  /// The matching outputs that actually exist/were output in the build state.
  BuiltSet<AssetId> get results;

  /// All matching files checked as inputs.
  ///
  /// This includes declared outputs that the build step did not output, so they
  /// don't exist.
  BuiltSet<AssetId> get inputs;

  /// Content signature computed from the sorted list of matched
  /// result paths.
  Digest get digest;

  factory GlobResult([void Function(GlobResultBuilder)? updates]) =
      _$GlobResult;
  GlobResult._();
}
