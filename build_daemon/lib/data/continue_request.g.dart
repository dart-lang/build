// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'continue_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<ContinueRequest> _$continueRequestSerializer =
    new _$ContinueRequestSerializer();

class _$ContinueRequestSerializer
    implements StructuredSerializer<ContinueRequest> {
  @override
  final Iterable<Type> types = const [ContinueRequest, _$ContinueRequest];
  @override
  final String wireName = 'ContinueRequest';

  @override
  Iterable<Object> serialize(Serializers serializers, ContinueRequest object,
      {FullType specifiedType = FullType.unspecified}) {
    return <Object>[];
  }

  @override
  ContinueRequest deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    return new ContinueRequestBuilder().build();
  }
}

class _$ContinueRequest extends ContinueRequest {
  factory _$ContinueRequest([void Function(ContinueRequestBuilder) updates]) =>
      (new ContinueRequestBuilder()..update(updates)).build();

  _$ContinueRequest._() : super._();

  @override
  ContinueRequest rebuild(void Function(ContinueRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ContinueRequestBuilder toBuilder() =>
      new ContinueRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ContinueRequest;
  }

  @override
  int get hashCode {
    return 327097468;
  }

  @override
  String toString() {
    return newBuiltValueToStringHelper('ContinueRequest').toString();
  }
}

class ContinueRequestBuilder
    implements Builder<ContinueRequest, ContinueRequestBuilder> {
  _$ContinueRequest _$v;

  ContinueRequestBuilder();

  @override
  void replace(ContinueRequest other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$ContinueRequest;
  }

  @override
  void update(void Function(ContinueRequestBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$ContinueRequest build() {
    final _$result = _$v ?? new _$ContinueRequest._();
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
