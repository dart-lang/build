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
  Iterable serialize(Serializers serializers, BuildTargetRequest object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'blackListPattern',
      serializers.serialize(object.blackListPattern,
          specifiedType:
              const FullType(BuiltList, const [const FullType(String)])),
      'target',
      serializers.serialize(object.target,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  BuildTargetRequest deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new BuildTargetRequestBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'blackListPattern':
          result.blackListPattern.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(String)]))
              as BuiltList);
          break;
        case 'target':
          result.target = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$BuildTargetRequest extends BuildTargetRequest {
  @override
  final BuiltList<String> blackListPattern;
  @override
  final String target;

  factory _$BuildTargetRequest([void updates(BuildTargetRequestBuilder b)]) =>
      (new BuildTargetRequestBuilder()..update(updates)).build();

  _$BuildTargetRequest._({this.blackListPattern, this.target}) : super._() {
    if (blackListPattern == null) {
      throw new BuiltValueNullFieldError(
          'BuildTargetRequest', 'blackListPattern');
    }
    if (target == null) {
      throw new BuiltValueNullFieldError('BuildTargetRequest', 'target');
    }
  }

  @override
  BuildTargetRequest rebuild(void updates(BuildTargetRequestBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  BuildTargetRequestBuilder toBuilder() =>
      new BuildTargetRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BuildTargetRequest &&
        blackListPattern == other.blackListPattern &&
        target == other.target;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, blackListPattern.hashCode), target.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('BuildTargetRequest')
          ..add('blackListPattern', blackListPattern)
          ..add('target', target))
        .toString();
  }
}

class BuildTargetRequestBuilder
    implements Builder<BuildTargetRequest, BuildTargetRequestBuilder> {
  _$BuildTargetRequest _$v;

  ListBuilder<String> _blackListPattern;
  ListBuilder<String> get blackListPattern =>
      _$this._blackListPattern ??= new ListBuilder<String>();
  set blackListPattern(ListBuilder<String> blackListPattern) =>
      _$this._blackListPattern = blackListPattern;

  String _target;
  String get target => _$this._target;
  set target(String target) => _$this._target = target;

  BuildTargetRequestBuilder();

  BuildTargetRequestBuilder get _$this {
    if (_$v != null) {
      _blackListPattern = _$v.blackListPattern?.toBuilder();
      _target = _$v.target;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BuildTargetRequest other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$BuildTargetRequest;
  }

  @override
  void update(void updates(BuildTargetRequestBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$BuildTargetRequest build() {
    _$BuildTargetRequest _$result;
    try {
      _$result = _$v ??
          new _$BuildTargetRequest._(
              blackListPattern: blackListPattern.build(), target: target);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'blackListPattern';
        blackListPattern.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'BuildTargetRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
