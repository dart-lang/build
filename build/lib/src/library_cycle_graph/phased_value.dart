// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

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
///  - that value expires after phase 3
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
/// [ExpiringValue.expiresAfter].
///
/// If the last value in the list has non-null [ExpiringValue.expiresAfter] then
/// the `PhasedValue` is incomplete: after the specified phase it changes to an
/// unknown value. Or, if the last value in the list has `null` `expiresAfter`
/// then the `PhasedValue` is complete; no further changes are possible.
///
/// A `PhasedValue` cannot have missing values before present values: the
/// initial value is always known, and the value after all changes except
/// possibly the last.
///
/// TODO(davidmorgan): it might be more efficient to represent the simpler
/// cases, fixed or changing exactly once, as different implementation types.
abstract class PhasedValue<T>
    implements Built<PhasedValue<T>, PhasedValueBuilder<T>> {
  static Serializer<PhasedValue> get serializer => _$phasedValueSerializer;

  BuiltList<ExpiringValue<T>> get values;

  factory PhasedValue([void Function(PhasedValueBuilder<T>)? updates]) =
      _$PhasedValue<T>;
  PhasedValue._();

  /// A fixed [value] with no changes.
  factory PhasedValue.fixed(T value) => PhasedValue((b) {
    b.values.add(ExpiringValue<T>(value));
  });

  /// A value that will be generated in phase [expiresAfter].
  ///
  /// Pass the "missing" value for T as [before].
  factory PhasedValue.unavailable({
    required int expiresAfter,
    required T before,
  }) => PhasedValue((b) {
    b.values.add(ExpiringValue<T>(before, expiresAfter: expiresAfter));
  });

  /// A value that is generated during [atPhase], changing from [before] to
  /// [value].
  factory PhasedValue.generated(
    T value, {
    required int atPhase,
    required T before,
  }) => PhasedValue((b) {
    b.values.add(ExpiringValue<T>(before, expiresAfter: atPhase));
    b.values.add(ExpiringValue<T>(value));
  });

  /// A [value] expiring after [expiresAfter] if it's not `null`.
  factory PhasedValue.of(T value, {required int? expiresAfter}) =>
      PhasedValue((b) {
        b.values.add(ExpiringValue<T>(value, expiresAfter: expiresAfter));
      });

  /// Whether this value is complete: all values are known, no further changes
  /// are possible.
  bool get isComplete => values.last.expiresAfter == null;

  /// The phase after which the value expires, or `null` if it never expires.
  int? get expiresAfter => values.last.expiresAfter;

  /// Whether this value has expired at the specified [phase], meaning the
  /// actual value is not known.
  bool isExpiredAt({required int phase}) {
    return expiresAfter != null && expiresAfter! < phase;
  }

  /// The value at [phase], with its expirey phase.
  ///
  /// Throws `StateError` if the value has expired at [phase], meaning the value
  /// is not known.
  ExpiringValue<T> expiringValueAt({required int phase}) {
    for (final value in values) {
      if (value.expiresAfter == null || value.expiresAfter! >= phase) {
        return value;
      }
    }
    throw StateError('No value for phase $phase.');
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
    if (!isComplete) throw StateError('Not complete, no last value.');
    return values.last.value;
  }

  /// This value followed by [value].
  ///
  /// Throws `StateError` if [isComplete], as a complete value cannot change.
  ///
  /// Throws `StateError` if the additional value expires before or at
  /// [expiresAfter], as it cannot follow this one.
  PhasedValue<T> followedBy(ExpiringValue<T> value) {
    if (values.last.expiresAfter == null) {
      throw StateError("Can't follow a value that doesn't expire.");
    }
    if (value.expiresAfter != null &&
        value.expiresAfter! <= values.last.expiresAfter!) {
      throw StateError(
        "Can't follow with a value expiring before or at the existing value.",
      );
    }
    return rebuild((b) {
      b.values.add(value);
    });
  }
}

/// A [value] with optionally limited lifespan.
///
/// If [expiresAfter] is `null`, the value never expires.
///
/// If [expiresAfter] is set, the value expires after that phase, taking a new
/// value in the next phase.
abstract class ExpiringValue<T>
    implements Built<ExpiringValue<T>, ExpiringValueBuilder<T>> {
  static Serializer<ExpiringValue> get serializer => _$expiringValueSerializer;

  T get value;
  int? get expiresAfter;

  factory ExpiringValue(T value, {int? expiresAfter}) =>
      _$ExpiringValue<T>._(value: value, expiresAfter: expiresAfter);
  ExpiringValue._();
}

/// Returns the earliest of two nullable phases [a] and [b].
///
/// `null` represents "never", so any non-`null` phase is earlier than a `null`
/// one.
int? earliestPhase(int? a, int? b) {
  if (a == null) return b;
  if (b == null) return a;
  return min(a, b);
}
