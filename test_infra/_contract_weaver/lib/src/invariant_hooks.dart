// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';

part 'invariant_hooks.g.dart';

/// The invariant checks woven around a method body.
abstract class InvariantHooks
    implements Built<InvariantHooks, InvariantHooksBuilder> {
  String get className;

  /// Whether the body can change the object, so that a memoized check result
  /// must be discarded on exit.
  bool get mightMutate;

  InvariantHooks._();
  factory InvariantHooks([void Function(InvariantHooksBuilder) updates]) =
      _$InvariantHooks;

  /// Creates an [InvariantHooks] from its fields.
  factory InvariantHooks.of({
    required String className,
    required bool mightMutate,
  }) => _$InvariantHooks._(className: className, mightMutate: mightMutate);
}
