// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phased_library_cycle_graphs.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<PhasedLibraryCycleGraphs> _$phasedLibraryCycleGraphsSerializer =
    new _$PhasedLibraryCycleGraphsSerializer();

class _$PhasedLibraryCycleGraphsSerializer
    implements StructuredSerializer<PhasedLibraryCycleGraphs> {
  @override
  final Iterable<Type> types = const [
    PhasedLibraryCycleGraphs,
    _$PhasedLibraryCycleGraphs,
  ];
  @override
  final String wireName = 'PhasedLibraryCycleGraphs';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    PhasedLibraryCycleGraphs object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'graphs',
      serializers.serialize(
        object.graphs,
        specifiedType: const FullType(BuiltMap, const [
          const FullType(AssetId),
          const FullType(PhasedValue, const [
            const FullType(LibraryCycleGraph),
          ]),
        ]),
      ),
    ];

    return result;
  }

  @override
  PhasedLibraryCycleGraphs deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new PhasedLibraryCycleGraphsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'graphs':
          result.graphs.replace(
            serializers.deserialize(
              value,
              specifiedType: const FullType(BuiltMap, const [
                const FullType(AssetId),
                const FullType(PhasedValue, const [
                  const FullType(LibraryCycleGraph),
                ]),
              ]),
            )!,
          );
          break;
      }
    }

    return result.build();
  }
}

class _$PhasedLibraryCycleGraphs extends PhasedLibraryCycleGraphs {
  @override
  final BuiltMap<AssetId, PhasedValue<LibraryCycleGraph>> graphs;
  PhasedLibraryCycleGraphs? __reversed;

  factory _$PhasedLibraryCycleGraphs([
    void Function(PhasedLibraryCycleGraphsBuilder)? updates,
  ]) => (new PhasedLibraryCycleGraphsBuilder()..update(updates))._build();

  _$PhasedLibraryCycleGraphs._({required this.graphs}) : super._() {
    BuiltValueNullFieldError.checkNotNull(
      graphs,
      r'PhasedLibraryCycleGraphs',
      'graphs',
    );
  }

  @override
  PhasedLibraryCycleGraphs get reversed => __reversed ??= super.reversed;

  @override
  PhasedLibraryCycleGraphs rebuild(
    void Function(PhasedLibraryCycleGraphsBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PhasedLibraryCycleGraphsBuilder toBuilder() =>
      new PhasedLibraryCycleGraphsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PhasedLibraryCycleGraphs && graphs == other.graphs;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, graphs.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PhasedLibraryCycleGraphs')
      ..add('graphs', graphs)).toString();
  }
}

class PhasedLibraryCycleGraphsBuilder
    implements
        Builder<PhasedLibraryCycleGraphs, PhasedLibraryCycleGraphsBuilder> {
  _$PhasedLibraryCycleGraphs? _$v;

  MapBuilder<AssetId, PhasedValue<LibraryCycleGraph>>? _graphs;
  MapBuilder<AssetId, PhasedValue<LibraryCycleGraph>> get graphs =>
      _$this._graphs ??=
          new MapBuilder<AssetId, PhasedValue<LibraryCycleGraph>>();
  set graphs(MapBuilder<AssetId, PhasedValue<LibraryCycleGraph>>? graphs) =>
      _$this._graphs = graphs;

  PhasedLibraryCycleGraphsBuilder();

  PhasedLibraryCycleGraphsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _graphs = $v.graphs.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PhasedLibraryCycleGraphs other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$PhasedLibraryCycleGraphs;
  }

  @override
  void update(void Function(PhasedLibraryCycleGraphsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PhasedLibraryCycleGraphs build() => _build();

  _$PhasedLibraryCycleGraphs _build() {
    _$PhasedLibraryCycleGraphs _$result;
    try {
      _$result =
          _$v ?? new _$PhasedLibraryCycleGraphs._(graphs: graphs.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'graphs';
        graphs.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'PhasedLibraryCycleGraphs',
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
