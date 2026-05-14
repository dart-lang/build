// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_process_build_step_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<PostProcessBuildStepResult> _$postProcessBuildStepResultSerializer =
    _$PostProcessBuildStepResultSerializer();

class _$PostProcessBuildStepResultSerializer
    implements StructuredSerializer<PostProcessBuildStepResult> {
  @override
  final Iterable<Type> types = const [
    PostProcessBuildStepResult,
    _$PostProcessBuildStepResult,
  ];
  @override
  final String wireName = 'PostProcessBuildStepResult';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    PostProcessBuildStepResult object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'hidden',
      serializers.serialize(object.hidden, specifiedType: const FullType(bool)),
      'deletedPrimaryInput',
      serializers.serialize(
        object.deletedPrimaryInput,
        specifiedType: const FullType(bool),
      ),
      'outputs',
      serializers.serialize(
        object.outputs,
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

    return result;
  }

  @override
  PostProcessBuildStepResult deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PostProcessBuildStepResultBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'hidden':
          result.hidden =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )!
                  as bool;
          break;
        case 'deletedPrimaryInput':
          result.deletedPrimaryInput =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )!
                  as bool;
          break;
        case 'outputs':
          result.outputs.replace(
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

class _$PostProcessBuildStepResult extends PostProcessBuildStepResult {
  @override
  final bool hidden;
  @override
  final bool deletedPrimaryInput;
  @override
  final BuiltSet<AssetId> outputs;
  @override
  final BuiltList<String> errors;

  factory _$PostProcessBuildStepResult([
    void Function(PostProcessBuildStepResultBuilder)? updates,
  ]) => (PostProcessBuildStepResultBuilder()..update(updates))._build();

  _$PostProcessBuildStepResult._({
    required this.hidden,
    required this.deletedPrimaryInput,
    required this.outputs,
    required this.errors,
  }) : super._();
  @override
  PostProcessBuildStepResult rebuild(
    void Function(PostProcessBuildStepResultBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PostProcessBuildStepResultBuilder toBuilder() =>
      PostProcessBuildStepResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PostProcessBuildStepResult &&
        hidden == other.hidden &&
        deletedPrimaryInput == other.deletedPrimaryInput &&
        outputs == other.outputs &&
        errors == other.errors;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, hidden.hashCode);
    _$hash = $jc(_$hash, deletedPrimaryInput.hashCode);
    _$hash = $jc(_$hash, outputs.hashCode);
    _$hash = $jc(_$hash, errors.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PostProcessBuildStepResult')
          ..add('hidden', hidden)
          ..add('deletedPrimaryInput', deletedPrimaryInput)
          ..add('outputs', outputs)
          ..add('errors', errors))
        .toString();
  }
}

class PostProcessBuildStepResultBuilder
    implements
        Builder<PostProcessBuildStepResult, PostProcessBuildStepResultBuilder> {
  _$PostProcessBuildStepResult? _$v;

  bool? _hidden;
  bool? get hidden => _$this._hidden;
  set hidden(bool? hidden) => _$this._hidden = hidden;

  bool? _deletedPrimaryInput;
  bool? get deletedPrimaryInput => _$this._deletedPrimaryInput;
  set deletedPrimaryInput(bool? deletedPrimaryInput) =>
      _$this._deletedPrimaryInput = deletedPrimaryInput;

  SetBuilder<AssetId>? _outputs;
  SetBuilder<AssetId> get outputs => _$this._outputs ??= SetBuilder<AssetId>();
  set outputs(SetBuilder<AssetId>? outputs) => _$this._outputs = outputs;

  ListBuilder<String>? _errors;
  ListBuilder<String> get errors => _$this._errors ??= ListBuilder<String>();
  set errors(ListBuilder<String>? errors) => _$this._errors = errors;

  PostProcessBuildStepResultBuilder();

  PostProcessBuildStepResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _hidden = $v.hidden;
      _deletedPrimaryInput = $v.deletedPrimaryInput;
      _outputs = $v.outputs.toBuilder();
      _errors = $v.errors.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PostProcessBuildStepResult other) {
    _$v = other as _$PostProcessBuildStepResult;
  }

  @override
  void update(void Function(PostProcessBuildStepResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PostProcessBuildStepResult build() => _build();

  _$PostProcessBuildStepResult _build() {
    _$PostProcessBuildStepResult _$result;
    try {
      _$result =
          _$v ??
          _$PostProcessBuildStepResult._(
            hidden: BuiltValueNullFieldError.checkNotNull(
              hidden,
              r'PostProcessBuildStepResult',
              'hidden',
            ),
            deletedPrimaryInput: BuiltValueNullFieldError.checkNotNull(
              deletedPrimaryInput,
              r'PostProcessBuildStepResult',
              'deletedPrimaryInput',
            ),
            outputs: outputs.build(),
            errors: errors.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'outputs';
        outputs.build();
        _$failedField = 'errors';
        errors.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PostProcessBuildStepResult',
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
