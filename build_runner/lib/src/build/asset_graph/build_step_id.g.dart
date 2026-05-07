// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_step_id.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<BuildStepId> _$buildStepIdSerializer = _$BuildStepIdSerializer();

class _$BuildStepIdSerializer implements StructuredSerializer<BuildStepId> {
  @override
  final Iterable<Type> types = const [BuildStepId, _$BuildStepId];
  @override
  final String wireName = 'BuildStepId';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    BuildStepId object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'primaryInput',
      serializers.serialize(
        object.primaryInput,
        specifiedType: const FullType(AssetId),
      ),
      'phaseNumber',
      serializers.serialize(
        object.phaseNumber,
        specifiedType: const FullType(int),
      ),
    ];

    return result;
  }

  @override
  BuildStepId deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BuildStepIdBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'primaryInput':
          result.primaryInput =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(AssetId),
                  )!
                  as AssetId;
          break;
        case 'phaseNumber':
          result.phaseNumber =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(int),
                  )!
                  as int;
          break;
      }
    }

    return result.build();
  }
}

class _$BuildStepId extends BuildStepId {
  @override
  final AssetId primaryInput;
  @override
  final int phaseNumber;

  factory _$BuildStepId([void Function(BuildStepIdBuilder)? updates]) =>
      (BuildStepIdBuilder()..update(updates))._build();

  _$BuildStepId._({required this.primaryInput, required this.phaseNumber})
    : super._();
  @override
  BuildStepId rebuild(void Function(BuildStepIdBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BuildStepIdBuilder toBuilder() => BuildStepIdBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BuildStepId &&
        primaryInput == other.primaryInput &&
        phaseNumber == other.phaseNumber;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, primaryInput.hashCode);
    _$hash = $jc(_$hash, phaseNumber.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BuildStepId')
          ..add('primaryInput', primaryInput)
          ..add('phaseNumber', phaseNumber))
        .toString();
  }
}

class BuildStepIdBuilder implements Builder<BuildStepId, BuildStepIdBuilder> {
  _$BuildStepId? _$v;

  AssetId? _primaryInput;
  AssetId? get primaryInput => _$this._primaryInput;
  set primaryInput(AssetId? primaryInput) =>
      _$this._primaryInput = primaryInput;

  int? _phaseNumber;
  int? get phaseNumber => _$this._phaseNumber;
  set phaseNumber(int? phaseNumber) => _$this._phaseNumber = phaseNumber;

  BuildStepIdBuilder();

  BuildStepIdBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _primaryInput = $v.primaryInput;
      _phaseNumber = $v.phaseNumber;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BuildStepId other) {
    _$v = other as _$BuildStepId;
  }

  @override
  void update(void Function(BuildStepIdBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BuildStepId build() => _build();

  _$BuildStepId _build() {
    final _$result =
        _$v ??
        _$BuildStepId._(
          primaryInput: BuiltValueNullFieldError.checkNotNull(
            primaryInput,
            r'BuildStepId',
            'primaryInput',
          ),
          phaseNumber: BuiltValueNullFieldError.checkNotNull(
            phaseNumber,
            r'BuildStepId',
            'phaseNumber',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
