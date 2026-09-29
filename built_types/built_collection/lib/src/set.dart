// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'internal/copy_on_write_set.dart';
import 'internal/hash.dart';
import 'internal/iterables.dart';
import 'internal/null_safety.dart';
import 'internal/unmodifiable_set.dart';
import 'iterable.dart' show BuiltIterable;
import 'list.dart' show BuiltList;

part 'set/built_set.dart';
part 'set/set_builder.dart';

// Internal only, for testing.
class OverriddenHashcodeBuiltSet<T> extends _BuiltSet<T> {
  final int _overridenHashCode;

  OverriddenHashcodeBuiltSet(super.iterable, this._overridenHashCode)
    : super.from();

  @override
  // ignore: hash_and_equals
  int get hashCode => _overridenHashCode;
}
