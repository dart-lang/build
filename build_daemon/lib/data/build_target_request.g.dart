// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_target_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<BuildTargetRequest> _$buildTargetRequestSerializer =
    new _$BuildTargetRequestSerializer();

class _$BuildTargetRequestSerializer
    implements StructuredSerializer<BuildTargetRequest> {
  @override
  final Iterable<Type> types = const [BuildTargetRequest, _$BuildTargetRequest];
  @override
  final String wireName = 'BuildTargetRequest';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    BuildTargetRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'target',
      serializers.serialize(
        object.target,
        specifiedType: const FullType(BuildTarget),
      ),
    ];

    return result;
  }

  @override
  BuildTargetRequest deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new BuildTargetRequestBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'target':
          result.target =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuildTarget),
                  )!
                  as BuildTarget;
          break;
      }
    }

    return result.build();
  }
}

class _$BuildTargetRequest extends BuildTargetRequest {
  @override
  final BuildTarget target;

  factory _$BuildTargetRequest([
    void Function(BuildTargetRequestBuilder)? updates,
  ]) => (new BuildTargetRequestBuilder()..update(updates))._build();

  _$BuildTargetRequest._({required this.target}) : super._() {
    BuiltValueNullFieldError.checkNotNull(
      target,
      r'BuildTargetRequest',
      'target',
    );
  }

  @override
  BuildTargetRequest rebuild(
    void Function(BuildTargetRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  BuildTargetRequestBuilder toBuilder() =>
      new BuildTargetRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BuildTargetRequest && target == other.target;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, target.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BuildTargetRequest')
      ..add('target', target)).toString();
  }
}

class BuildTargetRequestBuilder
    implements Builder<BuildTargetRequest, BuildTargetRequestBuilder> {
  _$BuildTargetRequest? _$v;

  BuildTarget? _target;
  BuildTarget? get target => _$this._target;
  set target(BuildTarget? target) => _$this._target = target;

  BuildTargetRequestBuilder();

  BuildTargetRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _target = $v.target;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BuildTargetRequest other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$BuildTargetRequest;
  }

  @override
  void update(void Function(BuildTargetRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BuildTargetRequest build() => _build();

  _$BuildTargetRequest _build() {
    final _$result =
        _$v ??
        new _$BuildTargetRequest._(
          target: BuiltValueNullFieldError.checkNotNull(
            target,
            r'BuildTargetRequest',
            'target',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
