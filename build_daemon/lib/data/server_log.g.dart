// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_log.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<ServerLog> _$serverLogSerializer = new _$ServerLogSerializer();

class _$ServerLogSerializer implements StructuredSerializer<ServerLog> {
  @override
  final Iterable<Type> types = const [ServerLog, _$ServerLog];
  @override
  final String wireName = 'ServerLog';

  @override
  Iterable serialize(Serializers serializers, ServerLog object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'log',
      serializers.serialize(object.log, specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  ServerLog deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ServerLogBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'log':
          result.log = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$ServerLog extends ServerLog {
  @override
  final String log;

  factory _$ServerLog([void updates(ServerLogBuilder b)]) =>
      (new ServerLogBuilder()..update(updates)).build();

  _$ServerLog._({this.log}) : super._() {
    if (log == null) {
      throw new BuiltValueNullFieldError('ServerLog', 'log');
    }
  }

  @override
  ServerLog rebuild(void updates(ServerLogBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  ServerLogBuilder toBuilder() => new ServerLogBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ServerLog && log == other.log;
  }

  @override
  int get hashCode {
    return $jf($jc(0, log.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('ServerLog')..add('log', log))
        .toString();
  }
}

class ServerLogBuilder implements Builder<ServerLog, ServerLogBuilder> {
  _$ServerLog _$v;

  String _log;
  String get log => _$this._log;
  set log(String log) => _$this._log = log;

  ServerLogBuilder();

  ServerLogBuilder get _$this {
    if (_$v != null) {
      _log = _$v.log;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ServerLog other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$ServerLog;
  }

  @override
  void update(void updates(ServerLogBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$ServerLog build() {
    final _$result = _$v ?? new _$ServerLog._(log: log);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
