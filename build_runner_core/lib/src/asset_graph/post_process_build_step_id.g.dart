// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_process_build_step_id.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<PostProcessBuildStepId> _$postProcessBuildStepIdSerializer =
    new _$PostProcessBuildStepIdSerializer();

class _$PostProcessBuildStepIdSerializer
    implements StructuredSerializer<PostProcessBuildStepId> {
  @override
  final Iterable<Type> types = const [
    PostProcessBuildStepId,
    _$PostProcessBuildStepId,
  ];
  @override
  final String wireName = 'PostProcessBuildStepId';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    PostProcessBuildStepId object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'input',
      serializers.serialize(
        object.input,
        specifiedType: const FullType(AssetId),
      ),
      'actionNumber',
      serializers.serialize(
        object.actionNumber,
        specifiedType: const FullType(int),
      ),
    ];

    return result;
  }

  @override
  PostProcessBuildStepId deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new PostProcessBuildStepIdBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'input':
          result.input =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(AssetId),
                  )!
                  as AssetId;
          break;
        case 'actionNumber':
          result.actionNumber =
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

class _$PostProcessBuildStepId extends PostProcessBuildStepId {
  @override
  final AssetId input;
  @override
  final int actionNumber;

  factory _$PostProcessBuildStepId([
    void Function(PostProcessBuildStepIdBuilder)? updates,
  ]) => (new PostProcessBuildStepIdBuilder()..update(updates))._build();

  _$PostProcessBuildStepId._({required this.input, required this.actionNumber})
    : super._() {
    BuiltValueNullFieldError.checkNotNull(
      input,
      r'PostProcessBuildStepId',
      'input',
    );
    BuiltValueNullFieldError.checkNotNull(
      actionNumber,
      r'PostProcessBuildStepId',
      'actionNumber',
    );
  }

  @override
  PostProcessBuildStepId rebuild(
    void Function(PostProcessBuildStepIdBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PostProcessBuildStepIdBuilder toBuilder() =>
      new PostProcessBuildStepIdBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PostProcessBuildStepId &&
        input == other.input &&
        actionNumber == other.actionNumber;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, input.hashCode);
    _$hash = $jc(_$hash, actionNumber.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PostProcessBuildStepId')
          ..add('input', input)
          ..add('actionNumber', actionNumber))
        .toString();
  }
}

class PostProcessBuildStepIdBuilder
    implements Builder<PostProcessBuildStepId, PostProcessBuildStepIdBuilder> {
  _$PostProcessBuildStepId? _$v;

  AssetId? _input;
  AssetId? get input => _$this._input;
  set input(AssetId? input) => _$this._input = input;

  int? _actionNumber;
  int? get actionNumber => _$this._actionNumber;
  set actionNumber(int? actionNumber) => _$this._actionNumber = actionNumber;

  PostProcessBuildStepIdBuilder();

  PostProcessBuildStepIdBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _input = $v.input;
      _actionNumber = $v.actionNumber;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PostProcessBuildStepId other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$PostProcessBuildStepId;
  }

  @override
  void update(void Function(PostProcessBuildStepIdBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PostProcessBuildStepId build() => _build();

  _$PostProcessBuildStepId _build() {
    final _$result =
        _$v ??
        new _$PostProcessBuildStepId._(
          input: BuiltValueNullFieldError.checkNotNull(
            input,
            r'PostProcessBuildStepId',
            'input',
          ),
          actionNumber: BuiltValueNullFieldError.checkNotNull(
            actionNumber,
            r'PostProcessBuildStepId',
            'actionNumber',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
