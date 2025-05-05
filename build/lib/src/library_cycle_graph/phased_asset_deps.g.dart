// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phased_asset_deps.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<PhasedAssetDeps> _$phasedAssetDepsSerializer =
    new _$PhasedAssetDepsSerializer();

class _$PhasedAssetDepsSerializer
    implements StructuredSerializer<PhasedAssetDeps> {
  @override
  final Iterable<Type> types = const [PhasedAssetDeps, _$PhasedAssetDeps];
  @override
  final String wireName = 'PhasedAssetDeps';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    PhasedAssetDeps object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'assetDeps',
      serializers.serialize(
        object.assetDeps,
        specifiedType: const FullType(BuiltMap, const [
          const FullType(AssetId),
          const FullType(PhasedValue, const [const FullType(AssetDeps)]),
        ]),
      ),
    ];

    return result;
  }

  @override
  PhasedAssetDeps deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new PhasedAssetDepsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'assetDeps':
          result.assetDeps.replace(
            serializers.deserialize(
              value,
              specifiedType: const FullType(BuiltMap, const [
                const FullType(AssetId),
                const FullType(PhasedValue, const [const FullType(AssetDeps)]),
              ]),
            )!,
          );
          break;
      }
    }

    return result.build();
  }
}

class _$PhasedAssetDeps extends PhasedAssetDeps {
  @override
  final BuiltMap<AssetId, PhasedValue<AssetDeps>> assetDeps;
  int? __phase;

  factory _$PhasedAssetDeps([void Function(PhasedAssetDepsBuilder)? updates]) =>
      (new PhasedAssetDepsBuilder()..update(updates))._build();

  _$PhasedAssetDeps._({required this.assetDeps}) : super._() {
    BuiltValueNullFieldError.checkNotNull(
      assetDeps,
      r'PhasedAssetDeps',
      'assetDeps',
    );
  }

  @override
  int get phase => __phase ??= super.phase;

  @override
  PhasedAssetDeps rebuild(void Function(PhasedAssetDepsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PhasedAssetDepsBuilder toBuilder() =>
      new PhasedAssetDepsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PhasedAssetDeps && assetDeps == other.assetDeps;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, assetDeps.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PhasedAssetDeps')
      ..add('assetDeps', assetDeps)).toString();
  }
}

class PhasedAssetDepsBuilder
    implements Builder<PhasedAssetDeps, PhasedAssetDepsBuilder> {
  _$PhasedAssetDeps? _$v;

  MapBuilder<AssetId, PhasedValue<AssetDeps>>? _assetDeps;
  MapBuilder<AssetId, PhasedValue<AssetDeps>> get assetDeps =>
      _$this._assetDeps ??= new MapBuilder<AssetId, PhasedValue<AssetDeps>>();
  set assetDeps(MapBuilder<AssetId, PhasedValue<AssetDeps>>? assetDeps) =>
      _$this._assetDeps = assetDeps;

  PhasedAssetDepsBuilder();

  PhasedAssetDepsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _assetDeps = $v.assetDeps.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PhasedAssetDeps other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$PhasedAssetDeps;
  }

  @override
  void update(void Function(PhasedAssetDepsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PhasedAssetDeps build() => _build();

  _$PhasedAssetDeps _build() {
    _$PhasedAssetDeps _$result;
    try {
      _$result = _$v ?? new _$PhasedAssetDeps._(assetDeps: assetDeps.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'assetDeps';
        assetDeps.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'PhasedAssetDeps',
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

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
