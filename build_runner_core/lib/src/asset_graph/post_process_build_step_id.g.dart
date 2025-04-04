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
      'actionNumber',
      serializers.serialize(
        object.actionNumber,
        specifiedType: const FullType(int),
      ),
      'input',
      serializers.serialize(
        object.input,
        specifiedType: const FullType(AssetId),
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
        case 'actionNumber':
          result.actionNumber =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(int),
                  )!
                  as int;
          break;
        case 'input':
          result.input =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(AssetId),
                  )!
                  as AssetId;
          break;
      }
    }

    return result.build();
  }
}

class _$PostProcessBuildStepId extends PostProcessBuildStepId {
  @override
  final int actionNumber;
  @override
  final AssetId input;

  factory _$PostProcessBuildStepId([
    void Function(PostProcessBuildStepIdBuilder)? updates,
  ]) => (new PostProcessBuildStepIdBuilder()..update(updates))._build();

  _$PostProcessBuildStepId._({required this.actionNumber, required this.input})
    : super._() {
    BuiltValueNullFieldError.checkNotNull(
      actionNumber,
      r'PostProcessBuildStepId',
      'actionNumber',
    );
    BuiltValueNullFieldError.checkNotNull(
      input,
      r'PostProcessBuildStepId',
      'input',
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
        actionNumber == other.actionNumber &&
        input == other.input;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, actionNumber.hashCode);
    _$hash = $jc(_$hash, input.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PostProcessBuildStepId')
          ..add('actionNumber', actionNumber)
          ..add('input', input))
        .toString();
  }
}

class PostProcessBuildStepIdBuilder
    implements Builder<PostProcessBuildStepId, PostProcessBuildStepIdBuilder> {
  _$PostProcessBuildStepId? _$v;

  int? _actionNumber;
  int? get actionNumber => _$this._actionNumber;
  set actionNumber(int? actionNumber) => _$this._actionNumber = actionNumber;

  AssetId? _input;
  AssetId? get input => _$this._input;
  set input(AssetId? input) => _$this._input = input;

  PostProcessBuildStepIdBuilder();

  PostProcessBuildStepIdBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _actionNumber = $v.actionNumber;
      _input = $v.input;
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
          actionNumber: BuiltValueNullFieldError.checkNotNull(
            actionNumber,
            r'PostProcessBuildStepId',
            'actionNumber',
          ),
          input: BuiltValueNullFieldError.checkNotNull(
            input,
            r'PostProcessBuildStepId',
            'input',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
