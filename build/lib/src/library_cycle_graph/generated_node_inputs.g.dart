// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generated_node_inputs.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<GeneratedNodeInputs> _$generatedNodeInputsSerializer =
    new _$GeneratedNodeInputsSerializer();

class _$GeneratedNodeInputsSerializer
    implements StructuredSerializer<GeneratedNodeInputs> {
  @override
  final Iterable<Type> types = const [
    GeneratedNodeInputs,
    _$GeneratedNodeInputs,
  ];
  @override
  final String wireName = 'GeneratedNodeInputs';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    GeneratedNodeInputs object, {
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
        specifiedType: const FullType(BuiltSet, const [
          const FullType(AssetId),
        ]),
      ),
      'unused',
      serializers.serialize(
        object.unused,
        specifiedType: const FullType(BuiltSet, const [
          const FullType(AssetId),
        ]),
      ),
    ];

    return result;
  }

  @override
  GeneratedNodeInputs deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new GeneratedNodeInputsBuilder();

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
                  specifiedType: const FullType(BuiltSet, const [
                    const FullType(AssetId),
                  ]),
                )!
                as BuiltSet<Object?>,
          );
          break;
        case 'unused':
          result.unused.replace(
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

class _$GeneratedNodeInputs extends GeneratedNodeInputs {
  @override
  final BuiltSet<AssetId> assets;
  @override
  final BuiltSet<AssetId> graphs;
  @override
  final BuiltSet<AssetId> unused;

  factory _$GeneratedNodeInputs([
    void Function(GeneratedNodeInputsBuilder)? updates,
  ]) => (new GeneratedNodeInputsBuilder()..update(updates))._build();

  _$GeneratedNodeInputs._({
    required this.assets,
    required this.graphs,
    required this.unused,
  }) : super._() {
    BuiltValueNullFieldError.checkNotNull(
      assets,
      r'GeneratedNodeInputs',
      'assets',
    );
    BuiltValueNullFieldError.checkNotNull(
      graphs,
      r'GeneratedNodeInputs',
      'graphs',
    );
    BuiltValueNullFieldError.checkNotNull(
      unused,
      r'GeneratedNodeInputs',
      'unused',
    );
  }

  @override
  GeneratedNodeInputs rebuild(
    void Function(GeneratedNodeInputsBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GeneratedNodeInputsBuilder toBuilder() =>
      new GeneratedNodeInputsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GeneratedNodeInputs &&
        assets == other.assets &&
        graphs == other.graphs &&
        unused == other.unused;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, assets.hashCode);
    _$hash = $jc(_$hash, graphs.hashCode);
    _$hash = $jc(_$hash, unused.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GeneratedNodeInputs')
          ..add('assets', assets)
          ..add('graphs', graphs)
          ..add('unused', unused))
        .toString();
  }
}

class GeneratedNodeInputsBuilder
    implements Builder<GeneratedNodeInputs, GeneratedNodeInputsBuilder> {
  _$GeneratedNodeInputs? _$v;

  SetBuilder<AssetId>? _assets;
  SetBuilder<AssetId> get assets =>
      _$this._assets ??= new SetBuilder<AssetId>();
  set assets(SetBuilder<AssetId>? assets) => _$this._assets = assets;

  SetBuilder<AssetId>? _graphs;
  SetBuilder<AssetId> get graphs =>
      _$this._graphs ??= new SetBuilder<AssetId>();
  set graphs(SetBuilder<AssetId>? graphs) => _$this._graphs = graphs;

  SetBuilder<AssetId>? _unused;
  SetBuilder<AssetId> get unused =>
      _$this._unused ??= new SetBuilder<AssetId>();
  set unused(SetBuilder<AssetId>? unused) => _$this._unused = unused;

  GeneratedNodeInputsBuilder();

  GeneratedNodeInputsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _assets = $v.assets.toBuilder();
      _graphs = $v.graphs.toBuilder();
      _unused = $v.unused.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GeneratedNodeInputs other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$GeneratedNodeInputs;
  }

  @override
  void update(void Function(GeneratedNodeInputsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GeneratedNodeInputs build() => _build();

  _$GeneratedNodeInputs _build() {
    _$GeneratedNodeInputs _$result;
    try {
      _$result =
          _$v ??
          new _$GeneratedNodeInputs._(
            assets: assets.build(),
            graphs: graphs.build(),
            unused: unused.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'assets';
        assets.build();
        _$failedField = 'graphs';
        graphs.build();
        _$failedField = 'unused';
        unused.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'GeneratedNodeInputs',
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
