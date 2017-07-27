// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/type.dart';

import 'constants/utils.dart';
import 'revive.dart';
import 'type_checker.dart';

/// A wrapper for analyzer's [DartObject] with a predictable high-level API.
///
/// Unlike [DartObject.getField], the [read] method attempts to access super
/// classes for the field value if not found.
abstract class ConstantReader {
  factory ConstantReader(DartObject object) =>
      isNullLike(object) ? const _NullConstant() : new _Constant(object);

  /// Whether this constant is a supported literal value.
  bool get isAny;

  /// Constant as any supported literal value.
  ///
  /// Throws [FormatException] if a valid literal value cannot be returned. This
  /// is the case if the constant is not a literal or if the literal value
  /// is represented at least partially with [DartObject] instances.
  dynamic get anyValue;

  /// Underlying object used to create this instance.
  DartObject get objectValue;

  /// Whether this constant represents a `bool` literal.
  bool get isBool;

  /// This constant as a `bool` value.
  bool get boolValue;

  /// This constant represents an `int` literal.
  bool get isInt;

  /// This constant as an `int` value.
  ///
  /// Throws [FormatException] if [isInt] is `false`.
  int get intValue;

  /// Whether this constant represents a `List` literal.
  ///
  /// If `true`, [listValue] will return a `List` (not throw).
  bool get isList;

  /// This constant as a `List` value.
  ///
  /// Note: the list values are instances of [DartObject] which represent the
  /// original values.
  ///
  /// Throws [FormatException] if [isList] is `false`.
  List<DartObject> get listValue;

  /// Whether this constant represents a `Map` literal.
  ///
  /// If `true`, [listValue] will return a `Map` (not throw).
  bool get isMap;

  /// This constant as a `Map` value.
  ///
  /// Note: the map keys and values are instances of [DartObject] which
  /// represent the original values.
  ///
  /// Throws [FormatException] if [isMap] is `false`.
  Map<DartObject, DartObject> get mapValue;

  /// Whether this constant represents a `String` literal.
  ///
  /// If `true`, [stringValue] will return a `String` (not throw).
  bool get isString;

  /// This constant as an `String` value.
  ///
  /// Throws [FormatException] if [isString] is `false`.
  String get stringValue;

  /// Whether this constant represents a `double` literal.
  ///
  /// If `true`, [doubleValue] will return a `double` (not throw).
  bool get isDouble;

  /// This constant as an `double` value.
  ///
  /// Throws [FormatException] if [isDouble] is `false`.
  double get doubleValue;

  /// Whether this constant represents a `Symbol` literal.
  ///
  /// If `true`, [symbolValue] will return a `Symbol` (not throw).
  bool get isSymbol;

  /// Returns this constant as an `Symbol` value.
  ///
  /// Throws [FormatException] if [isSymbol] is `false`.
  Symbol get symbolValue;

  /// Whether this constant represents a `Type` literal.
  ///
  /// If `true`, [typeValue] will return a `DartType` (not throw).
  bool get isType;

  /// A [DartType] representing this as a `Type` value.
  ///
  /// Throws [FormatException] if [isType] is `false`.
  DartType get typeValue;

  /// Whether this constant represents `null`.
  bool get isNull;

  /// Whether this constant matches [checker].
  bool instanceOf(TypeChecker checker);

  /// Reads [field] from the constant as another constant value.
  ///
  /// If the field is not present in the [DartObject] crawl up the chain of
  /// super classes until it is found. If the field is not present throw a
  /// [FormatException].
  ConstantReader read(String field);

  /// Reads [field] from the constant as another constant value.
  ///
  /// Unlike [read], returns `null` if the field is not found.
  ConstantReader peek(String field);

  /// Returns as a revived meta class.
  ///
  /// This is appropriate for cases where the underlying object is not a literal
  /// and code generators will want to figure out how to "recreate" a constant
  /// at runtime.
  Revivable revive();
}

/// Implements a [ConstantReader] representing a `null` value.
class _NullConstant implements ConstantReader {
  const _NullConstant();

  @override
  bool get isAny => true;

  @override
  dynamic get anyValue => null;

  @override
  DartObject get objectValue => throw new UnsupportedError('Null');

  @override
  bool get boolValue => _throw('bool');

  @override
  int get intValue => _throw('int');

  @override
  String get stringValue => _throw('String');

  @override
  List<DartObject> get listValue => _throw('List');

  @override
  Map<DartObject, DartObject> get mapValue => _throw('Map');

  @override
  bool get isBool => false;

  @override
  bool get isInt => false;

  @override
  bool get isList => false;

  @override
  bool get isMap => false;

  @override
  bool get isNull => true;

  @override
  bool get isString => false;

  @override
  bool get isDouble => false;

  @override
  double get doubleValue => _throw("double");

  @override
  bool get isSymbol => false;

  @override
  Symbol get symbolValue => _throw("Symbol");

  @override
  get isType => false;

  @override
  DartType get typeValue => _throw("Type");

  @override
  bool instanceOf(TypeChecker checker) => false;

  @override
  ConstantReader read(_) => throw new UnsupportedError('Null');

  @override
  ConstantReader peek(_) => null;

  @override
  Revivable revive() => throw new UnsupportedError('Null');

  dynamic _throw(String expected) =>
      throw new FormatException('Not an instance of $expected.');
}

/// Default implementation of [ConstantReader].
class _Constant implements ConstantReader {
  const _Constant(this.objectValue);

  @override
  final DartObject objectValue;

  dynamic get _anyValue =>
      objectValue.toBoolValue() ??
      objectValue.toIntValue() ??
      objectValue.toStringValue() ??
      objectValue.toDoubleValue() ??
      (isSymbol ? symbolValue : null);

  @override
  dynamic get anyValue =>
      _anyValue ??
      (objectValue.isNull
          ? null
          : _throw('bool, int, double, String or Symbol'));

  @override
  bool get boolValue => isBool ? objectValue.toBoolValue() : _throw('bool');

  @override
  int get intValue => isInt ? objectValue.toIntValue() : _throw('int');

  @override
  String get stringValue =>
      isString ? objectValue.toStringValue() : _throw('String');

  @override
  List<DartObject> get listValue =>
      isList ? objectValue.toListValue() : _throw('List');

  @override
  Map<DartObject, DartObject> get mapValue =>
      isMap ? objectValue.toMapValue() : _throw('Map');

  @override
  bool get isAny => _anyValue != null;

  @override
  bool get isBool => objectValue.toBoolValue() != null;

  @override
  bool get isInt => objectValue.toIntValue() != null;

  @override
  bool get isList => objectValue.toListValue() != null;

  @override
  bool get isNull => isNullLike(objectValue);

  @override
  bool get isMap => objectValue.toMapValue() != null;

  @override
  bool get isString => objectValue.toStringValue() != null;

  @override
  bool get isDouble => objectValue.toDoubleValue() != null;

  @override
  double get doubleValue =>
      isDouble ? objectValue.toDoubleValue() : _throw('double');

  @override
  bool get isSymbol => objectValue.toSymbolValue() != null;

  @override
  Symbol get symbolValue =>
      isSymbol ? new Symbol(objectValue.toSymbolValue()) : _throw('Symbol');

  @override
  bool get isType => objectValue.toTypeValue() != null;

  @override
  DartType get typeValue => isType ? objectValue.toTypeValue() : _throw("Type");

  @override
  bool instanceOf(TypeChecker checker) =>
      checker.isAssignableFromType(objectValue.type);

  @override
  ConstantReader peek(String field) {
    final constant = new ConstantReader(getFieldRecursive(objectValue, field));
    if (constant.isNull) {
      return null;
    }
    return constant;
  }

  @override
  ConstantReader read(String field) {
    final reader = peek(field);
    if (reader == null) {
      assertHasField(objectValue?.type?.element, field);
      return const _NullConstant();
    }
    return reader;
  }

  @override
  Revivable revive() => reviveInstance(objectValue);

  @override
  String toString() => 'ConstantReader ${objectValue}';

  dynamic _throw(String expected) =>
      throw new FormatException('Not an instance of $expected.', objectValue);
}
