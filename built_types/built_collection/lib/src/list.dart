// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math' show Random;

import 'internal/copy_on_write_list.dart';
import 'internal/hash.dart';
import 'internal/iterables.dart';
import 'internal/null_safety.dart';
import 'iterable.dart' show BuiltIterable;
import 'set.dart' show BuiltSet;

part 'list/built_list.dart';
part 'list/list_builder.dart';

// Internal only, for testing.
class OverriddenHashcodeBuiltList<T> extends _BuiltList<T> {
  final int _overridenHashCode;

  OverriddenHashcodeBuiltList(super.iterable, this._overridenHashCode)
    : super.from();

  @override
  // ignore: hash_and_equals
  int get hashCode => _overridenHashCode;
}
