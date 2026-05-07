// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glob_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<GlobResult> _$globResultSerializer = _$GlobResultSerializer();

class _$GlobResultSerializer implements StructuredSerializer<GlobResult> {
  @override
  final Iterable<Type> types = const [GlobResult, _$GlobResult];
  @override
  final String wireName = 'GlobResult';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    GlobResult object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'results',
      serializers.serialize(
        object.results,
        specifiedType: const FullType(BuiltSet, const [
          const FullType(AssetId),
        ]),
      ),
      'inputs',
      serializers.serialize(
        object.inputs,
        specifiedType: const FullType(BuiltSet, const [
          const FullType(AssetId),
        ]),
      ),
      'digest',
      serializers.serialize(
        object.digest,
        specifiedType: const FullType(Digest),
      ),
    ];

    return result;
  }

  @override
  GlobResult deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GlobResultBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'results':
          result.results.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltSet, const [
                    const FullType(AssetId),
                  ]),
                )!
                as BuiltSet<Object?>,
          );
          break;
        case 'inputs':
          result.inputs.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltSet, const [
                    const FullType(AssetId),
                  ]),
                )!
                as BuiltSet<Object?>,
          );
          break;
        case 'digest':
          result.digest =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(Digest),
                  )!
                  as Digest;
          break;
      }
    }

    return result.build();
  }
}

class _$GlobResult extends GlobResult {
  @override
  final BuiltSet<AssetId> results;
  @override
  final BuiltSet<AssetId> inputs;
  @override
  final Digest digest;

  factory _$GlobResult([void Function(GlobResultBuilder)? updates]) =>
      (GlobResultBuilder()..update(updates))._build();

  _$GlobResult._({
    required this.results,
    required this.inputs,
    required this.digest,
  }) : super._();
  @override
  GlobResult rebuild(void Function(GlobResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GlobResultBuilder toBuilder() => GlobResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GlobResult &&
        results == other.results &&
        inputs == other.inputs &&
        digest == other.digest;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, results.hashCode);
    _$hash = $jc(_$hash, inputs.hashCode);
    _$hash = $jc(_$hash, digest.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GlobResult')
          ..add('results', results)
          ..add('inputs', inputs)
          ..add('digest', digest))
        .toString();
  }
}

class GlobResultBuilder implements Builder<GlobResult, GlobResultBuilder> {
  _$GlobResult? _$v;

  SetBuilder<AssetId>? _results;
  SetBuilder<AssetId> get results => _$this._results ??= SetBuilder<AssetId>();
  set results(SetBuilder<AssetId>? results) => _$this._results = results;

  SetBuilder<AssetId>? _inputs;
  SetBuilder<AssetId> get inputs => _$this._inputs ??= SetBuilder<AssetId>();
  set inputs(SetBuilder<AssetId>? inputs) => _$this._inputs = inputs;

  Digest? _digest;
  Digest? get digest => _$this._digest;
  set digest(Digest? digest) => _$this._digest = digest;

  GlobResultBuilder();

  GlobResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _results = $v.results.toBuilder();
      _inputs = $v.inputs.toBuilder();
      _digest = $v.digest;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GlobResult other) {
    _$v = other as _$GlobResult;
  }

  @override
  void update(void Function(GlobResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GlobResult build() => _build();

  _$GlobResult _build() {
    _$GlobResult _$result;
    try {
      _$result =
          _$v ??
          _$GlobResult._(
            results: results.build(),
            inputs: inputs.build(),
            digest: BuiltValueNullFieldError.checkNotNull(
              digest,
              r'GlobResult',
              'digest',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'results';
        results.build();
        _$failedField = 'inputs';
        inputs.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'GlobResult',
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
