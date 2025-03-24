// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

part 'phased_value.g.dart';

/// A value that changes during the build, according to the `int` build phase.
///
/// The initial state of the build is at phase 0. At every phase after that,
/// files can be generated, causing the old value to _expire_. The new value
/// is available in the _next_ phase.
///
/// For example, if `foo.dart` is a generated file generated in phase 3:
///
///  - the value of `foo.dart` at phase 0 is empty/missing;
///  - that value expires at phase 3
///  - the new value of `foo.dart` is readable in phase 4
///
/// Ignoring post process deletion, which happens outside the main build, a
/// single file can change at most once during the build: when a generated file
/// is generated. But a _set_ of files can change more than once, since files in
/// the set can change at different phases. So, any number of changes is
/// supported, allowing a `PhasedValue` to model multi-asset entities such as
/// dependency trees.
///
/// Represented as a list of [ExpiringValue] with ascending
/// [ExpiringValue.expiresAt].
///
/// If the last value in the list has non-null [ExpiringValue.expiresAt] then
/// the `PhasedValue` is incomplete: after the specified phase it changes to an
/// unknown value. Or, if the last value in the list has `null` `expiresAt` then
/// the `PhasedValue` is complete; no further changes are possible.
///
/// A `PhasedValue` cannot have missing values before present values: the
/// initial value is always known, and the value after all changes except
/// possibly the last.
///
/// TODO(davidmorgan): it might be more efficient to represent the simpler
/// cases, fixed or changing exactly once, as different implementation types.
abstract class PhasedValue<T>
    implements Built<PhasedValue<T>, PhasedValueBuilder<T>> {
  BuiltList<ExpiringValue<T>> get values;

  factory PhasedValue([void Function(PhasedValueBuilder<T>)? updates]) =
      _$PhasedValue<T>;
  PhasedValue._();

  /// A fixed [value] with no changes.
  factory PhasedValue.fixed(T value) => PhasedValue((b) {
    b.values.add(ExpiringValue<T>(value));
  });

  /// A value that will be generated during [untilAfterPhase].
  ///
  /// Pass the "missing" value for T as [before].
  factory PhasedValue.unavailable({
    required int untilAfterPhase,
    required T before,
  }) => PhasedValue((b) {
    b.values.add(ExpiringValue<T>(before, expiresAt: untilAfterPhase));
  });

  /// A value that is generated during [atPhase], changing from [before] to
  /// [value].
  factory PhasedValue.generated(
    T value, {
    required int atPhase,
    required T before,
  }) => PhasedValue((b) {
    b.values.add(ExpiringValue<T>(before, expiresAt: atPhase));
    b.values.add(ExpiringValue<T>(value));
  });

  /// A [value] expiring at [expiresAt] if it's not `null`.
  factory PhasedValue.of(T value, {required int? expiresAt}) =>
      PhasedValue((b) {
        b.values.add(ExpiringValue<T>(value, expiresAt: expiresAt));
      });

  /// Whether this value is complete: all values are known, no further changes
  /// are possible.
  bool get isComplete => values.last.expiresAt == null;

  int? get expiresAt => values.last.expiresAt;

  /// Whether this value has expired at the specified [phase], meaning the
  /// actual value is not known.
  bool isExpiredAt({required int phase}) {
    return expiresAt != null && expiresAt! < phase;
  }

  /// The value at [phase], with its expirey phase.
  ///
  /// Throws `StateError` if the value has expired at [phase], meaning the value
  /// is not known.
  ExpiringValue<T> expiringValueAt({required int phase}) {
    final result = values.firstWhere(
      (v) => v.expiresAt == null || v.expiresAt! >= phase,
      orElse: () => throw StateError('No value for phase $phase in $this.'),
    );
    return result;
  }

  /// The value at [phase].
  ///
  /// Throws `StateError` if the value has expired at [phase], meaning the value
  /// is not known.
  T valueAt({required int phase}) => expiringValueAt(phase: phase).value;

  /// The value after all changes have happened.
  ///
  /// Throws if not [isComplete], meaning the last value is not known.
  T get lastValue {
    if (!isComplete) throw StateError('Not complete, no last value: $this');
    return values.last.value;
  }

  /// This value followed by [value].
  ///
  /// Throws `StateError` if [isComplete], as a complete value cannot change.
  ///
  /// Throws `StateError` if the additional value expires before or at
  /// [expiresAt], as it cannot follow this one.
  PhasedValue<T> followedBy(ExpiringValue<T> value) {
    if (values.last.expiresAt == null) {
      throw StateError("Can't follow a value that doesn't expire.");
    }
    if (value.expiresAt != null && value.expiresAt! <= values.last.expiresAt!) {
      throw StateError(
        "Can't follow with a value expiring before or at the existing value."
        ' This: $this, followedBy: $value',
      );
    }
    return rebuild((b) {
      b.values.add(value);
    });
  }
}

/// A [value] with optionally limited lifespan.
///
/// If [expiresAt] is `null`, the value never expires.
///
/// If [expiresAt] is set, the value expires at that phase: it takes a new value
/// in the _next_ phase after that.
abstract class ExpiringValue<T>
    implements Built<ExpiringValue<T>, ExpiringValueBuilder<T>> {
  T get value;
  int? get expiresAt;

  factory ExpiringValue(T value, {int? expiresAt}) =>
      _$ExpiringValue<T>._(value: value, expiresAt: expiresAt);
  ExpiringValue._();
}
