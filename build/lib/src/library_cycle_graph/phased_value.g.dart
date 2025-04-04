// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phased_value.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PhasedValue<T> extends PhasedValue<T> {
  @override
  final BuiltList<ExpiringValue<T>> values;

  factory _$PhasedValue([void Function(PhasedValueBuilder<T>)? updates]) =>
      (new PhasedValueBuilder<T>()..update(updates))._build();

  _$PhasedValue._({required this.values}) : super._() {
    BuiltValueNullFieldError.checkNotNull(values, r'PhasedValue', 'values');
    if (T == dynamic) {
      throw new BuiltValueMissingGenericsError(r'PhasedValue', 'T');
    }
  }

  @override
  PhasedValue<T> rebuild(void Function(PhasedValueBuilder<T>) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PhasedValueBuilder<T> toBuilder() =>
      new PhasedValueBuilder<T>()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PhasedValue && values == other.values;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, values.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PhasedValue')
      ..add('values', values)).toString();
  }
}

class PhasedValueBuilder<T>
    implements Builder<PhasedValue<T>, PhasedValueBuilder<T>> {
  _$PhasedValue<T>? _$v;

  ListBuilder<ExpiringValue<T>>? _values;
  ListBuilder<ExpiringValue<T>> get values =>
      _$this._values ??= new ListBuilder<ExpiringValue<T>>();
  set values(ListBuilder<ExpiringValue<T>>? values) => _$this._values = values;

  PhasedValueBuilder();

  PhasedValueBuilder<T> get _$this {
    final $v = _$v;
    if ($v != null) {
      _values = $v.values.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PhasedValue<T> other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$PhasedValue<T>;
  }

  @override
  void update(void Function(PhasedValueBuilder<T>)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PhasedValue<T> build() => _build();

  _$PhasedValue<T> _build() {
    _$PhasedValue<T> _$result;
    try {
      _$result = _$v ?? new _$PhasedValue<T>._(values: values.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'values';
        values.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'PhasedValue',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$ExpiringValue<T> extends ExpiringValue<T> {
  @override
  final T value;
  @override
  final int? expiresAfter;

  factory _$ExpiringValue([void Function(ExpiringValueBuilder<T>)? updates]) =>
      (new ExpiringValueBuilder<T>()..update(updates))._build();

  _$ExpiringValue._({required this.value, this.expiresAfter}) : super._() {
    BuiltValueNullFieldError.checkNotNull(value, r'ExpiringValue', 'value');
    if (T == dynamic) {
      throw new BuiltValueMissingGenericsError(r'ExpiringValue', 'T');
    }
  }

  @override
  ExpiringValue<T> rebuild(void Function(ExpiringValueBuilder<T>) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ExpiringValueBuilder<T> toBuilder() =>
      new ExpiringValueBuilder<T>()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ExpiringValue &&
        value == other.value &&
        expiresAfter == other.expiresAfter;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, value.hashCode);
    _$hash = $jc(_$hash, expiresAfter.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ExpiringValue')
          ..add('value', value)
          ..add('expiresAfter', expiresAfter))
        .toString();
  }
}

class ExpiringValueBuilder<T>
    implements Builder<ExpiringValue<T>, ExpiringValueBuilder<T>> {
  _$ExpiringValue<T>? _$v;

  T? _value;
  T? get value => _$this._value;
  set value(T? value) => _$this._value = value;

  int? _expiresAfter;
  int? get expiresAfter => _$this._expiresAfter;
  set expiresAfter(int? expiresAfter) => _$this._expiresAfter = expiresAfter;

  ExpiringValueBuilder();

  ExpiringValueBuilder<T> get _$this {
    final $v = _$v;
    if ($v != null) {
      _value = $v.value;
      _expiresAfter = $v.expiresAfter;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ExpiringValue<T> other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ExpiringValue<T>;
  }

  @override
  void update(void Function(ExpiringValueBuilder<T>)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ExpiringValue<T> build() => _build();

  _$ExpiringValue<T> _build() {
    final _$result =
        _$v ??
        new _$ExpiringValue<T>._(
          value: BuiltValueNullFieldError.checkNotNull(
            value,
            r'ExpiringValue',
            'value',
          ),
          expiresAfter: expiresAfter,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
