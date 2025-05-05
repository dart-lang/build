// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

import '../asset/id.dart';

part 'library_cycle.g.dart';

/// A set of Dart source assets that mutually depend on each other.
///
/// This means they have to be compiled as a single unit.
abstract class LibraryCycle
    implements Built<LibraryCycle, LibraryCycleBuilder> {
  BuiltSet<AssetId> get ids;

  factory LibraryCycle([void Function(LibraryCycleBuilder) updates]) =
      _$LibraryCycle;
  LibraryCycle._();

  factory LibraryCycle.of(Iterable<AssetId> ids) =>
      _$LibraryCycle._(ids: ids.toBuiltSet());
}
