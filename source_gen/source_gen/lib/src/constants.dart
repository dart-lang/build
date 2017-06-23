// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import 'revive.dart';
import 'type_checker.dart';

/// Throws an exception if [root] or its super(s) does not contain [name].
void _assertHasField(ClassElement root, String name) {
  var element = root;
  while (element != null) {
    final field = element.getField(name);
    if (field != null) {
      return;
    }
    element = element.supertype?.element;
  }
  final allFields = root.fields.toSet();
  root.allSupertypes.forEach((t) => allFields.addAll(t.element.fields));
  throw new FormatException(
    'Class ${root.name} does not have field "$name".',
    'Fields: $allFields',
  );
}

/// Returns whether or not [object] is or represents a `null` value.
bool _isNull(DartObject object) => object?.isNull != false;

/// Similar to [DartObject.getField], but traverses super classes.
///
/// Returns `null` if ultimately [field] is never found.
DartObject _getFieldRecursive(DartObject object, String field) {
  if (_isNull(object)) {
    return null;
  }
  final result = object.getField(field);
  if (_isNull(result)) {
    return _getFieldRecursive(object.getField('(super)'), field);
  }
  return result;
}

/// A wrapper for analyzer's [DartObject] with a predictable high-level API.
///
/// Unlike [DartObject.getField], all `readX` methods attempt to access super
/// classes for the field value if not found.
abstract class ConstantReader {
  factory ConstantReader(DartObject object) =>
      _isNull(object) ? const _NullConstant() : new _Constant(object);

  /// Constant as any supported literal value.
  ///
  /// Throws [FormatException] if a valid literal value cannot be returned. This
  /// is the case if the constant is not a literal or if the literal value
  /// is represented at least partially with [DartObject] instances.
  dynamic get anyValue;

  /// Returns whether this constant represents a `bool` literal.
  bool get isBool;

  /// Returns this constant as a `bool` value.
  bool get boolValue;

  /// Returns whether this constant represents an `int` literal.
  bool get isInt;

  /// Returns this constant as an `int` value.
  ///
  /// Throws [FormatException] if [isInt] is `false`.
  int get intValue;

  /// Returns whether this constant represents a `List` literal.
  ///
  /// If `true`, [listValue] will return a `List` (not throw).
  bool get isList;

  /// Returns this constant as a `List` value.
  ///
  /// Note: the list values are instances of [DartObject] which represent the
  /// original values.
  ///
  /// Throws [FormatException] if [isList] is `false`.
  List<DartObject> get listValue;

  /// Returns whether this constant represents a `Map` literal.
  ///
  /// If `true`, [listValue] will return a `Map` (not throw).
  bool get isMap;

  /// Returns this constant as a `Map` value.
  ///
  /// Note: the map keys and values are instances of [DartObject] which
  /// represent the original values.
  ///
  /// Throws [FormatException] if [isMap] is `false`.
  Map<DartObject, DartObject> get mapValue;

  /// Returns whether this constant represents a `String` literal.
  ///
  /// If `true`, [stringValue] will return a `String` (not throw).
  bool get isString;

  /// Returns this constant as an `String` value.
  ///
  /// Throws [FormatException] if [isString] is `false`.
  String get stringValue;

  /// Returns whether this constant represents a `double` literal.
  ///
  /// If `true`, [doubleValue] will return a `double` (not throw).
  bool get isDouble;

  /// Returns this constant as an `double` value.
  ///
  /// Throws [FormatException] if [isDouble] is `false`.
  double get doubleValue;

  /// Returns whether this constant represents a `Symbol` literal.
  ///
  /// If `true`, [symbolValue] will return a `Symbol` (not throw).
  bool get isSymbol;

  /// Returns this constant as an `Symbol` value.
  ///
  /// Throws [FormatException] if [isSymbol] is `false`.
  Symbol get symbolValue;

  /// Returns whether this constant represents a `Type` literal.
  ///
  /// If `true`, [typeValue] will return a `DartType` (not throw).
  bool get isType;

  /// Returns a [DartType] representing this as a `Type` value.
  ///
  /// Throws [FormatException] if [isType] is `false`.
  DartType get typeValue;

  /// Returns whether this constant represents `null`.
  bool get isNull;

  /// Returns whether this constant matches [checker].
  bool instanceOf(TypeChecker checker);

  /// Reads[ field] from the constant as another constant value.
  ConstantReader read(String field);

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
  dynamic get anyValue => null;

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
  Revivable revive() => throw new UnsupportedError('Null');

  dynamic _throw(String expected) =>
      throw new FormatException('Not an instance of $expected.');
}

/// Default implementation of [ConstantReader].
class _Constant implements ConstantReader {
  final DartObject _object;

  const _Constant(this._object);

  @override
  dynamic get anyValue =>
      _object.toBoolValue() ??
      _object.toIntValue() ??
      _object.toStringValue() ??
      _object.toDoubleValue() ??
      (isSymbol ? this.symbolValue : null) ??
      _throw('bool, int, double, String or Symbol');

  @override
  bool get boolValue => isBool ? _object.toBoolValue() : _throw('bool');

  @override
  int get intValue => isInt ? _object.toIntValue() : _throw('int');

  @override
  String get stringValue =>
      isString ? _object.toStringValue() : _throw('String');

  @override
  List<DartObject> get listValue =>
      isList ? _object.toListValue() : _throw('List');

  @override
  Map<DartObject, DartObject> get mapValue =>
      isMap ? _object.toMapValue() : _throw('Map');

  @override
  bool get isBool => _object.toBoolValue() != null;

  @override
  bool get isInt => _object.toIntValue() != null;

  @override
  bool get isList => _object.toListValue() != null;

  @override
  bool get isNull => _isNull(_object);

  @override
  bool get isMap => _object.toMapValue() != null;

  @override
  bool get isString => _object.toStringValue() != null;

  @override
  bool get isDouble => _object.toDoubleValue() != null;

  @override
  double get doubleValue =>
      isDouble ? _object.toDoubleValue() : _throw('double');

  @override
  bool get isSymbol => _object.toSymbolValue() != null;

  @override
  Symbol get symbolValue =>
      isSymbol ? new Symbol(_object.toSymbolValue()) : _throw('Symbol');

  @override
  bool get isType => _object.toTypeValue() != null;

  @override
  DartType get typeValue => isType ? _object.toTypeValue() : _throw("Type");

  @override
  bool instanceOf(TypeChecker checker) =>
      checker.isAssignableFromType(_object.type);

  @override
  ConstantReader read(String field) {
    final constant = new ConstantReader(_getFieldRecursive(_object, field));
    if (constant.isNull) {
      _assertHasField(_object?.type?.element, field);
    }
    return constant;
  }

  @override
  Revivable revive() => reviveInstance(_object);

  @override
  String toString() => 'ConstantReader ${_object}';

  dynamic _throw(String expected) =>
      throw new FormatException('Not an instance of $expected.', _object);
}
