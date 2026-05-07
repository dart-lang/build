// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_step_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<BuildStepResult> _$buildStepResultSerializer =
    _$BuildStepResultSerializer();

class _$BuildStepResultSerializer
    implements StructuredSerializer<BuildStepResult> {
  @override
  final Iterable<Type> types = const [BuildStepResult, _$BuildStepResult];
  @override
  final String wireName = 'BuildStepResult';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    BuildStepResult object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'inputs',
      serializers.serialize(
        object.inputs,
        specifiedType: const FullType(BuiltSet, const [
          const FullType(AssetId),
        ]),
      ),
      'globsEvaluated',
      serializers.serialize(
        object.globsEvaluated,
        specifiedType: const FullType(BuiltSet, const [const FullType(GlobId)]),
      ),
      'resolverEntrypoints',
      serializers.serialize(
        object.resolverEntrypoints,
        specifiedType: const FullType(BuiltSet, const [
          const FullType(AssetId),
        ]),
      ),
      'errors',
      serializers.serialize(
        object.errors,
        specifiedType: const FullType(BuiltList, const [
          const FullType(String),
        ]),
      ),
    ];
    Object? value;
    value = object.result;
    if (value != null) {
      result
        ..add('result')
        ..add(
          serializers.serialize(value, specifiedType: const FullType(bool)),
        );
    }
    return result;
  }

  @override
  BuildStepResult deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BuildStepResultBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'result':
          result.result =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )
                  as bool?;
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
        case 'globsEvaluated':
          result.globsEvaluated.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltSet, const [
                    const FullType(GlobId),
                  ]),
                )!
                as BuiltSet<Object?>,
          );
          break;
        case 'resolverEntrypoints':
          result.resolverEntrypoints.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltSet, const [
                    const FullType(AssetId),
                  ]),
                )!
                as BuiltSet<Object?>,
          );
          break;
        case 'errors':
          result.errors.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltList, const [
                    const FullType(String),
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

class _$BuildStepResult extends BuildStepResult {
  @override
  final bool? result;
  @override
  final BuiltSet<AssetId> inputs;
  @override
  final BuiltSet<GlobId> globsEvaluated;
  @override
  final BuiltSet<AssetId> resolverEntrypoints;
  @override
  final BuiltList<String> errors;

  factory _$BuildStepResult([void Function(BuildStepResultBuilder)? updates]) =>
      (BuildStepResultBuilder()..update(updates))._build();

  _$BuildStepResult._({
    this.result,
    required this.inputs,
    required this.globsEvaluated,
    required this.resolverEntrypoints,
    required this.errors,
  }) : super._();
  @override
  BuildStepResult rebuild(void Function(BuildStepResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BuildStepResultBuilder toBuilder() => BuildStepResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BuildStepResult &&
        result == other.result &&
        inputs == other.inputs &&
        globsEvaluated == other.globsEvaluated &&
        resolverEntrypoints == other.resolverEntrypoints &&
        errors == other.errors;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, result.hashCode);
    _$hash = $jc(_$hash, inputs.hashCode);
    _$hash = $jc(_$hash, globsEvaluated.hashCode);
    _$hash = $jc(_$hash, resolverEntrypoints.hashCode);
    _$hash = $jc(_$hash, errors.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BuildStepResult')
          ..add('result', result)
          ..add('inputs', inputs)
          ..add('globsEvaluated', globsEvaluated)
          ..add('resolverEntrypoints', resolverEntrypoints)
          ..add('errors', errors))
        .toString();
  }
}

class BuildStepResultBuilder
    implements Builder<BuildStepResult, BuildStepResultBuilder> {
  _$BuildStepResult? _$v;

  bool? _result;
  bool? get result => _$this._result;
  set result(bool? result) => _$this._result = result;

  SetBuilder<AssetId>? _inputs;
  SetBuilder<AssetId> get inputs => _$this._inputs ??= SetBuilder<AssetId>();
  set inputs(SetBuilder<AssetId>? inputs) => _$this._inputs = inputs;

  SetBuilder<GlobId>? _globsEvaluated;
  SetBuilder<GlobId> get globsEvaluated =>
      _$this._globsEvaluated ??= SetBuilder<GlobId>();
  set globsEvaluated(SetBuilder<GlobId>? globsEvaluated) =>
      _$this._globsEvaluated = globsEvaluated;

  SetBuilder<AssetId>? _resolverEntrypoints;
  SetBuilder<AssetId> get resolverEntrypoints =>
      _$this._resolverEntrypoints ??= SetBuilder<AssetId>();
  set resolverEntrypoints(SetBuilder<AssetId>? resolverEntrypoints) =>
      _$this._resolverEntrypoints = resolverEntrypoints;

  ListBuilder<String>? _errors;
  ListBuilder<String> get errors => _$this._errors ??= ListBuilder<String>();
  set errors(ListBuilder<String>? errors) => _$this._errors = errors;

  BuildStepResultBuilder();

  BuildStepResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _result = $v.result;
      _inputs = $v.inputs.toBuilder();
      _globsEvaluated = $v.globsEvaluated.toBuilder();
      _resolverEntrypoints = $v.resolverEntrypoints.toBuilder();
      _errors = $v.errors.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BuildStepResult other) {
    _$v = other as _$BuildStepResult;
  }

  @override
  void update(void Function(BuildStepResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BuildStepResult build() => _build();

  _$BuildStepResult _build() {
    _$BuildStepResult _$result;
    try {
      _$result =
          _$v ??
          _$BuildStepResult._(
            result: result,
            inputs: inputs.build(),
            globsEvaluated: globsEvaluated.build(),
            resolverEntrypoints: resolverEntrypoints.build(),
            errors: errors.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'inputs';
        inputs.build();
        _$failedField = 'globsEvaluated';
        globsEvaluated.build();
        _$failedField = 'resolverEntrypoints';
        resolverEntrypoints.build();
        _$failedField = 'errors';
        errors.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'BuildStepResult',
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
