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
  Iterable serialize(Serializers serializers, BuildRequest object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.invalidatedFiles != null) {
      result
        ..add('invalidatedFiles')
        ..add(serializers.serialize(object.invalidatedFiles,
            specifiedType:
                const FullType(List, const [const FullType(String)])));
    }
    return result;
  }

  @override
  BuildRequest deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new BuildRequestBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'invalidatedFiles':
          result.invalidatedFiles = serializers.deserialize(value,
                  specifiedType:
                      const FullType(List, const [const FullType(String)]))
              as List<String>;
          break;
      }
    }

    return result.build();
  }
}

class _$BuildRequest extends BuildRequest {
  @override
  final List<String> invalidatedFiles;

  factory _$BuildRequest([void Function(BuildRequestBuilder) updates]) =>
      (new BuildRequestBuilder()..update(updates)).build();

  _$BuildRequest._({this.invalidatedFiles}) : super._();

  @override
  BuildRequest rebuild(void Function(BuildRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BuildRequestBuilder toBuilder() => new BuildRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BuildRequest && invalidatedFiles == other.invalidatedFiles;
  }

  @override
  int get hashCode {
    return $jf($jc(0, invalidatedFiles.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('BuildRequest')
          ..add('invalidatedFiles', invalidatedFiles))
        .toString();
  }
}

class BuildRequestBuilder
    implements Builder<BuildRequest, BuildRequestBuilder> {
  _$BuildRequest _$v;

  List<String> _invalidatedFiles;
  List<String> get invalidatedFiles => _$this._invalidatedFiles;
  set invalidatedFiles(List<String> invalidatedFiles) =>
      _$this._invalidatedFiles = invalidatedFiles;

  BuildRequestBuilder();

  BuildRequestBuilder get _$this {
    if (_$v != null) {
      _invalidatedFiles = _$v.invalidatedFiles;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BuildRequest other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$BuildRequest;
  }

  @override
  void update(void Function(BuildRequestBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$BuildRequest build() {
    final _$result =
        _$v ?? new _$BuildRequest._(invalidatedFiles: invalidatedFiles);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
