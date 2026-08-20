// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_location.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<AssetLocation> _$assetLocationSerializer =
    _$AssetLocationSerializer();

class _$AssetLocationSerializer implements StructuredSerializer<AssetLocation> {
  @override
  final Iterable<Type> types = const [AssetLocation, _$AssetLocation];
  @override
  final String wireName = 'AssetLocation';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    AssetLocation object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'id',
      serializers.serialize(object.id, specifiedType: const FullType(AssetId)),
      'hidden',
      serializers.serialize(object.hidden, specifiedType: const FullType(bool)),
    ];

    return result;
  }

  @override
  AssetLocation deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AssetLocationBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'id':
          result.id =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(AssetId),
                  )!
                  as AssetId;
          break;
        case 'hidden':
          result.hidden =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )!
                  as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$AssetLocation extends AssetLocation {
  @override
  final AssetId id;
  @override
  final bool hidden;

  factory _$AssetLocation([void Function(AssetLocationBuilder)? updates]) =>
      (AssetLocationBuilder()..update(updates))._build();

  _$AssetLocation._({required this.id, required this.hidden}) : super._();
  @override
  AssetLocation rebuild(void Function(AssetLocationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AssetLocationBuilder toBuilder() => AssetLocationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AssetLocation && id == other.id && hidden == other.hidden;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, hidden.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AssetLocation')
          ..add('id', id)
          ..add('hidden', hidden))
        .toString();
  }
}

class AssetLocationBuilder
    implements Builder<AssetLocation, AssetLocationBuilder> {
  _$AssetLocation? _$v;

  AssetId? _id;
  AssetId? get id => _$this._id;
  set id(AssetId? id) => _$this._id = id;

  bool? _hidden;
  bool? get hidden => _$this._hidden;
  set hidden(bool? hidden) => _$this._hidden = hidden;

  AssetLocationBuilder();

  AssetLocationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _hidden = $v.hidden;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AssetLocation other) {
    _$v = other as _$AssetLocation;
  }

  @override
  void update(void Function(AssetLocationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AssetLocation build() => _build();

  _$AssetLocation _build() {
    final _$result =
        _$v ??
        _$AssetLocation._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'AssetLocation', 'id'),
          hidden: BuiltValueNullFieldError.checkNotNull(
            hidden,
            r'AssetLocation',
            'hidden',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
