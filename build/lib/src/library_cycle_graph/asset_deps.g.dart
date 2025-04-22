// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_deps.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<AssetDeps> _$assetDepsSerializer = new _$AssetDepsSerializer();

class _$AssetDepsSerializer implements StructuredSerializer<AssetDeps> {
  @override
  final Iterable<Type> types = const [AssetDeps, _$AssetDeps];
  @override
  final String wireName = 'AssetDeps';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    AssetDeps object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'deps',
      serializers.serialize(
        object.deps,
        specifiedType: const FullType(BuiltSet, const [
          const FullType(AssetId),
        ]),
      ),
    ];

    return result;
  }

  @override
  AssetDeps deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new AssetDepsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'deps':
          result.deps.replace(
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

class _$AssetDeps extends AssetDeps {
  @override
  final BuiltSet<AssetId> deps;

  factory _$AssetDeps([void Function(AssetDepsBuilder)? updates]) =>
      (new AssetDepsBuilder()..update(updates))._build();

  _$AssetDeps._({required this.deps}) : super._() {
    BuiltValueNullFieldError.checkNotNull(deps, r'AssetDeps', 'deps');
  }

  @override
  AssetDeps rebuild(void Function(AssetDepsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AssetDepsBuilder toBuilder() => new AssetDepsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AssetDeps && deps == other.deps;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, deps.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AssetDeps')
      ..add('deps', deps)).toString();
  }
}

class AssetDepsBuilder implements Builder<AssetDeps, AssetDepsBuilder> {
  _$AssetDeps? _$v;

  SetBuilder<AssetId>? _deps;
  SetBuilder<AssetId> get deps => _$this._deps ??= new SetBuilder<AssetId>();
  set deps(SetBuilder<AssetId>? deps) => _$this._deps = deps;

  AssetDepsBuilder();

  AssetDepsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _deps = $v.deps.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AssetDeps other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$AssetDeps;
  }

  @override
  void update(void Function(AssetDepsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AssetDeps build() => _build();

  _$AssetDeps _build() {
    _$AssetDeps _$result;
    try {
      _$result = _$v ?? new _$AssetDeps._(deps: deps.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'deps';
        deps.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'AssetDeps',
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
