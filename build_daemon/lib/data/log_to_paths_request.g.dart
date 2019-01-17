// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_to_paths_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<LogToPathsRequest> _$logToPathsRequestSerializer =
    new _$LogToPathsRequestSerializer();

class _$LogToPathsRequestSerializer
    implements StructuredSerializer<LogToPathsRequest> {
  @override
  final Iterable<Type> types = const [LogToPathsRequest, _$LogToPathsRequest];
  @override
  final String wireName = 'LogToPathsRequest';

  @override
  Iterable serialize(Serializers serializers, LogToPathsRequest object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'paths',
      serializers.serialize(object.paths,
          specifiedType:
              const FullType(BuiltList, const [const FullType(String)])),
    ];

    return result;
  }

  @override
  LogToPathsRequest deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new LogToPathsRequestBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'paths':
          result.paths.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(String)]))
              as BuiltList);
          break;
      }
    }

    return result.build();
  }
}

class _$LogToPathsRequest extends LogToPathsRequest {
  @override
  final BuiltList<String> paths;

  factory _$LogToPathsRequest([void updates(LogToPathsRequestBuilder b)]) =>
      (new LogToPathsRequestBuilder()..update(updates)).build();

  _$LogToPathsRequest._({this.paths}) : super._() {
    if (paths == null) {
      throw new BuiltValueNullFieldError('LogToPathsRequest', 'paths');
    }
  }

  @override
  LogToPathsRequest rebuild(void updates(LogToPathsRequestBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  LogToPathsRequestBuilder toBuilder() =>
      new LogToPathsRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LogToPathsRequest && paths == other.paths;
  }

  @override
  int get hashCode {
    return $jf($jc(0, paths.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('LogToPathsRequest')
          ..add('paths', paths))
        .toString();
  }
}

class LogToPathsRequestBuilder
    implements Builder<LogToPathsRequest, LogToPathsRequestBuilder> {
  _$LogToPathsRequest _$v;

  ListBuilder<String> _paths;
  ListBuilder<String> get paths => _$this._paths ??= new ListBuilder<String>();
  set paths(ListBuilder<String> paths) => _$this._paths = paths;

  LogToPathsRequestBuilder();

  LogToPathsRequestBuilder get _$this {
    if (_$v != null) {
      _paths = _$v.paths?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LogToPathsRequest other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$LogToPathsRequest;
  }

  @override
  void update(void updates(LogToPathsRequestBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$LogToPathsRequest build() {
    _$LogToPathsRequest _$result;
    try {
      _$result = _$v ?? new _$LogToPathsRequest._(paths: paths.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'paths';
        paths.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'LogToPathsRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
