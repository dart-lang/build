// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_set.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<AssetSet> _$assetSetSerializer = new _$AssetSetSerializer();

class _$AssetSetSerializer implements StructuredSerializer<AssetSet> {
  @override
  final Iterable<Type> types = const [AssetSet, _$AssetSet];
  @override
  final String wireName = 'AssetSet';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    AssetSet object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'assets',
      serializers.serialize(
        object.assets,
        specifiedType: const FullType(BuiltSet, const [
          const FullType(AssetId),
        ]),
      ),
      'graphs',
      serializers.serialize(
        object.graphs,
        specifiedType: const FullType(BuiltList, const [
          const FullType(LibraryCycleGraph),
        ]),
      ),
      'removedAssets',
      serializers.serialize(
        object.removedAssets,
        specifiedType: const FullType(BuiltSet, const [
          const FullType(AssetId),
        ]),
      ),
    ];

    return result;
  }

  @override
  AssetSet deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new AssetSetBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'assets':
          result.assets.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltSet, const [
                    const FullType(AssetId),
                  ]),
                )!
                as BuiltSet<Object?>,
          );
          break;
        case 'graphs':
          result.graphs.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltList, const [
                    const FullType(LibraryCycleGraph),
                  ]),
                )!
                as BuiltList<Object?>,
          );
          break;
        case 'removedAssets':
          result.removedAssets.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltSet, const [
                    const FullType(AssetId),
                  ]),
                )!
                as BuiltSet<Object?>,
          );
          break;
      }
    }

    return result.build();
  }
}

class _$AssetSet extends AssetSet {
  @override
  final BuiltSet<AssetId> assets;
  @override
  final BuiltList<LibraryCycleGraph> graphs;
  @override
  final BuiltSet<AssetId> removedAssets;

  factory _$AssetSet([void Function(AssetSetBuilder)? updates]) =>
      (new AssetSetBuilder()..update(updates))._build();

  _$AssetSet._({
    required this.assets,
    required this.graphs,
    required this.removedAssets,
  }) : super._() {
    BuiltValueNullFieldError.checkNotNull(assets, r'AssetSet', 'assets');
    BuiltValueNullFieldError.checkNotNull(graphs, r'AssetSet', 'graphs');
    BuiltValueNullFieldError.checkNotNull(
      removedAssets,
      r'AssetSet',
      'removedAssets',
    );
  }

  @override
  AssetSet rebuild(void Function(AssetSetBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AssetSetBuilder toBuilder() => new AssetSetBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AssetSet &&
        assets == other.assets &&
        graphs == other.graphs &&
        removedAssets == other.removedAssets;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, assets.hashCode);
    _$hash = $jc(_$hash, graphs.hashCode);
    _$hash = $jc(_$hash, removedAssets.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AssetSet')
          ..add('assets', assets)
          ..add('graphs', graphs)
          ..add('removedAssets', removedAssets))
        .toString();
  }
}

class AssetSetBuilder implements Builder<AssetSet, AssetSetBuilder> {
  _$AssetSet? _$v;

  SetBuilder<AssetId>? _assets;
  SetBuilder<AssetId> get assets =>
      _$this._assets ??= new SetBuilder<AssetId>();
  set assets(SetBuilder<AssetId>? assets) => _$this._assets = assets;

  ListBuilder<LibraryCycleGraph>? _graphs;
  ListBuilder<LibraryCycleGraph> get graphs =>
      _$this._graphs ??= new ListBuilder<LibraryCycleGraph>();
  set graphs(ListBuilder<LibraryCycleGraph>? graphs) => _$this._graphs = graphs;

  SetBuilder<AssetId>? _removedAssets;
  SetBuilder<AssetId> get removedAssets =>
      _$this._removedAssets ??= new SetBuilder<AssetId>();
  set removedAssets(SetBuilder<AssetId>? removedAssets) =>
      _$this._removedAssets = removedAssets;

  AssetSetBuilder();

  AssetSetBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _assets = $v.assets.toBuilder();
      _graphs = $v.graphs.toBuilder();
      _removedAssets = $v.removedAssets.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AssetSet other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$AssetSet;
  }

  @override
  void update(void Function(AssetSetBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AssetSet build() => _build();

  _$AssetSet _build() {
    _$AssetSet _$result;
    try {
      _$result =
          _$v ??
          new _$AssetSet._(
            assets: assets.build(),
            graphs: graphs.build(),
            removedAssets: removedAssets.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'assets';
        assets.build();
        _$failedField = 'graphs';
        graphs.build();
        _$failedField = 'removedAssets';
        removedAssets.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'AssetSet',
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
