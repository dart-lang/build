// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_client_options_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<SetClientOptionsRequest> _$setClientOptionsRequestSerializer =
    new _$SetClientOptionsRequestSerializer();

class _$SetClientOptionsRequestSerializer
    implements StructuredSerializer<SetClientOptionsRequest> {
  @override
  final Iterable<Type> types = const [
    SetClientOptionsRequest,
    _$SetClientOptionsRequest
  ];
  @override
  final String wireName = 'SetClientOptionsRequest';

  @override
  Iterable serialize(Serializers serializers, SetClientOptionsRequest object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'options',
      serializers.serialize(object.options,
          specifiedType: const FullType(ClientOptions)),
    ];

    return result;
  }

  @override
  SetClientOptionsRequest deserialize(
      Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new SetClientOptionsRequestBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'options':
          result.options = serializers.deserialize(value,
              specifiedType: const FullType(ClientOptions)) as ClientOptions;
          break;
      }
    }

    return result.build();
  }
}

class _$SetClientOptionsRequest extends SetClientOptionsRequest {
  @override
  final ClientOptions options;

  factory _$SetClientOptionsRequest(
          [void updates(SetClientOptionsRequestBuilder b)]) =>
      (new SetClientOptionsRequestBuilder()..update(updates)).build();

  _$SetClientOptionsRequest._({this.options}) : super._() {
    if (options == null) {
      throw new BuiltValueNullFieldError('SetClientOptionsRequest', 'options');
    }
  }

  @override
  SetClientOptionsRequest rebuild(
          void updates(SetClientOptionsRequestBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  SetClientOptionsRequestBuilder toBuilder() =>
      new SetClientOptionsRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SetClientOptionsRequest && options == other.options;
  }

  @override
  int get hashCode {
    return $jf($jc(0, options.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('SetClientOptionsRequest')
          ..add('options', options))
        .toString();
  }
}

class SetClientOptionsRequestBuilder
    implements
        Builder<SetClientOptionsRequest, SetClientOptionsRequestBuilder> {
  _$SetClientOptionsRequest _$v;

  ClientOptions _options;
  ClientOptions get options => _$this._options;
  set options(ClientOptions options) => _$this._options = options;

  SetClientOptionsRequestBuilder();

  SetClientOptionsRequestBuilder get _$this {
    if (_$v != null) {
      _options = _$v.options;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SetClientOptionsRequest other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$SetClientOptionsRequest;
  }

  @override
  void update(void updates(SetClientOptionsRequestBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$SetClientOptionsRequest build() {
    final _$result = _$v ?? new _$SetClientOptionsRequest._(options: options);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
