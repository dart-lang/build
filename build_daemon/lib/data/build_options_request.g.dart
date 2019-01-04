// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_options_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<BuildOptionsRequest> _$buildOptionsRequestSerializer =
    new _$BuildOptionsRequestSerializer();

class _$BuildOptionsRequestSerializer
    implements StructuredSerializer<BuildOptionsRequest> {
  @override
  final Iterable<Type> types = const [
    BuildOptionsRequest,
    _$BuildOptionsRequest
  ];
  @override
  final String wireName = 'BuildOptionsRequest';

  @override
  Iterable serialize(Serializers serializers, BuildOptionsRequest object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'options',
      serializers.serialize(object.options,
          specifiedType:
              const FullType(BuiltList, const [const FullType(String)])),
    ];

    return result;
  }

  @override
  BuildOptionsRequest deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new BuildOptionsRequestBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'options':
          result.options.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(String)]))
              as BuiltList);
          break;
      }
    }

    return result.build();
  }
}

class _$BuildOptionsRequest extends BuildOptionsRequest {
  @override
  final BuiltList<String> options;

  factory _$BuildOptionsRequest([void updates(BuildOptionsRequestBuilder b)]) =>
      (new BuildOptionsRequestBuilder()..update(updates)).build();

  _$BuildOptionsRequest._({this.options}) : super._() {
    if (options == null) {
      throw new BuiltValueNullFieldError('BuildOptionsRequest', 'options');
    }
  }

  @override
  BuildOptionsRequest rebuild(void updates(BuildOptionsRequestBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  BuildOptionsRequestBuilder toBuilder() =>
      new BuildOptionsRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BuildOptionsRequest && options == other.options;
  }

  @override
  int get hashCode {
    return $jf($jc(0, options.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('BuildOptionsRequest')
          ..add('options', options))
        .toString();
  }
}

class BuildOptionsRequestBuilder
    implements Builder<BuildOptionsRequest, BuildOptionsRequestBuilder> {
  _$BuildOptionsRequest _$v;

  ListBuilder<String> _options;
  ListBuilder<String> get options =>
      _$this._options ??= new ListBuilder<String>();
  set options(ListBuilder<String> options) => _$this._options = options;

  BuildOptionsRequestBuilder();

  BuildOptionsRequestBuilder get _$this {
    if (_$v != null) {
      _options = _$v.options?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BuildOptionsRequest other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$BuildOptionsRequest;
  }

  @override
  void update(void updates(BuildOptionsRequestBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$BuildOptionsRequest build() {
    _$BuildOptionsRequest _$result;
    try {
      _$result = _$v ?? new _$BuildOptionsRequest._(options: options.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'options';
        options.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'BuildOptionsRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
