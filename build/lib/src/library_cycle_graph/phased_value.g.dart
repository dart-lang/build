// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phased_value.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<PhasedValue<Object?>> _$phasedValueSerializer =
    new _$PhasedValueSerializer();
Serializer<ExpiringValue<Object?>> _$expiringValueSerializer =
    new _$ExpiringValueSerializer();

class _$PhasedValueSerializer
    implements StructuredSerializer<PhasedValue<Object?>> {
  @override
  final Iterable<Type> types = const [PhasedValue, _$PhasedValue];
  @override
  final String wireName = 'PhasedValue';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    PhasedValue<Object?> object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterT =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result = <Object?>[
      'values',
      serializers.serialize(
        object.values,
        specifiedType: new FullType(BuiltList, [
          new FullType(ExpiringValue, [parameterT]),
        ]),
      ),
    ];

    return result;
  }

  @override
  PhasedValue<Object?> deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterT =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result =
        isUnderspecified
            ? new PhasedValueBuilder<Object?>()
            : serializers.newBuilder(specifiedType)
                as PhasedValueBuilder<Object?>;

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'values':
          result.values.replace(
            serializers.deserialize(
                  value,
                  specifiedType: new FullType(BuiltList, [
                    new FullType(ExpiringValue, [parameterT]),
                  ]),
                )!
                as BuiltList<Object?>,
          );
          break;
      }
    }

    return result.build();
  }
}

class _$ExpiringValueSerializer
    implements StructuredSerializer<ExpiringValue<Object?>> {
  @override
  final Iterable<Type> types = const [ExpiringValue, _$ExpiringValue];
  @override
  final String wireName = 'ExpiringValue';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    ExpiringValue<Object?> object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterT =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result = <Object?>[
      'value',
      serializers.serialize(object.value, specifiedType: parameterT),
    ];
    Object? value;
    value = object.expiresAfter;
    if (value != null) {
      result
        ..add('expiresAfter')
        ..add(serializers.serialize(value, specifiedType: const FullType(int)));
    }
    return result;
  }

  @override
  ExpiringValue<Object?> deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterT =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result =
        isUnderspecified
            ? new ExpiringValueBuilder<Object?>()
            : serializers.newBuilder(specifiedType)
                as ExpiringValueBuilder<Object?>;

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'value':
          result.value = serializers.deserialize(
            value,
            specifiedType: parameterT,
          );
          break;
        case 'expiresAfter':
          result.expiresAfter =
              serializers.deserialize(value, specifiedType: const FullType(int))
                  as int?;
          break;
      }
    }

    return result.build();
  }
}

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
