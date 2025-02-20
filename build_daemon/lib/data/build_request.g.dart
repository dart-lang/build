// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<BuildRequest> _$buildRequestSerializer =
    new _$BuildRequestSerializer();

class _$BuildRequestSerializer implements StructuredSerializer<BuildRequest> {
  @override
  final Iterable<Type> types = const [BuildRequest, _$BuildRequest];
  @override
  final String wireName = 'BuildRequest';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    BuildRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return <Object?>[];
  }

  @override
  BuildRequest deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return new BuildRequestBuilder().build();
  }
}

class _$BuildRequest extends BuildRequest {
  factory _$BuildRequest([void Function(BuildRequestBuilder)? updates]) =>
      (new BuildRequestBuilder()..update(updates))._build();

  _$BuildRequest._() : super._();

  @override
  BuildRequest rebuild(void Function(BuildRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BuildRequestBuilder toBuilder() => new BuildRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BuildRequest;
  }

  @override
  int get hashCode {
    return 52408894;
  }

  @override
  String toString() {
    return newBuiltValueToStringHelper(r'BuildRequest').toString();
  }
}

class BuildRequestBuilder
    implements Builder<BuildRequest, BuildRequestBuilder> {
  _$BuildRequest? _$v;

  BuildRequestBuilder();

  @override
  void replace(BuildRequest other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$BuildRequest;
  }

  @override
  void update(void Function(BuildRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BuildRequest build() => _build();

  _$BuildRequest _build() {
    final _$result = _$v ?? new _$BuildRequest._();
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
