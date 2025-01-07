// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'built_value1.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Value extends Value {
  factory _$Value([void Function(ValueBuilder)? updates]) =>
      (new ValueBuilder()..update(updates))._build();

  _$Value._() : super._();

  @override
  Value rebuild(void Function(ValueBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ValueBuilder toBuilder() => new ValueBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Value;
  }

  @override
  int get hashCode {
    return 887435281;
  }

  @override
  String toString() {
    return newBuiltValueToStringHelper(r'Value').toString();
  }
}

class ValueBuilder implements Builder<Value, ValueBuilder> {
  _$Value? _$v;

  ValueBuilder();

  @override
  void replace(Value other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Value;
  }

  @override
  void update(void Function(ValueBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Value build() => _build();

  _$Value _build() {
    final _$result = _$v ?? new _$Value._();
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
