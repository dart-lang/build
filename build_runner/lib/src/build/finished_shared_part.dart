// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart' hide Builder;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

part 'finished_shared_part.g.dart';

/// Immutable representation of a shared part in a finished build.
abstract class FinishedSharedPart
    implements Built<FinishedSharedPart, FinishedSharedPartBuilder> {
  /// The library that this part is for.
  AssetId get libraryId;

  /// The language version override specified in the library source, or `null`
  /// if it has none.
  String? get languageVersion;

  /// Imports added to this part, keyed by phase number.
  BuiltMap<int, BuiltList<String>> get imports;

  /// Contributions added to this part, keyed by phase number.
  BuiltMap<int, String> get contributions;

  FinishedSharedPart._();
  factory FinishedSharedPart([
    void Function(FinishedSharedPartBuilder) updates,
  ]) = _$FinishedSharedPart;
}
