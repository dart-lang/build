// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_log.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const Level _$finest = const Level._('FINEST');
const Level _$finer = const Level._('FINER');
const Level _$fine = const Level._('FINE');
const Level _$config = const Level._('CONFIG');
const Level _$info = const Level._('INFO');
const Level _$warning = const Level._('WARNING');
const Level _$severe = const Level._('SEVERE');
const Level _$shout = const Level._('SHOUT');

Level _$valueOf(String name) {
  switch (name) {
    case 'FINEST':
      return _$finest;
    case 'FINER':
      return _$finer;
    case 'FINE':
      return _$fine;
    case 'CONFIG':
      return _$config;
    case 'INFO':
      return _$info;
    case 'WARNING':
      return _$warning;
    case 'SEVERE':
      return _$severe;
    case 'SHOUT':
      return _$shout;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<Level> _$values = new BuiltSet<Level>(const <Level>[
  _$finest,
  _$finer,
  _$fine,
  _$config,
  _$info,
  _$warning,
  _$severe,
  _$shout,
]);

Serializer<Level> _$levelSerializer = new _$LevelSerializer();
Serializer<ServerLog> _$serverLogSerializer = new _$ServerLogSerializer();

class _$LevelSerializer implements PrimitiveSerializer<Level> {
  @override
  final Iterable<Type> types = const <Type>[Level];
  @override
  final String wireName = 'Level';

  @override
  Object serialize(
    Serializers serializers,
    Level object, {
    FullType specifiedType = FullType.unspecified,
  }) => object.name;

  @override
  Level deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => Level.valueOf(serialized as String);
}

class _$ServerLogSerializer implements StructuredSerializer<ServerLog> {
  @override
  final Iterable<Type> types = const [ServerLog, _$ServerLog];
  @override
  final String wireName = 'ServerLog';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    ServerLog object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'level',
      serializers.serialize(object.level, specifiedType: const FullType(Level)),
      'message',
      serializers.serialize(
        object.message,
        specifiedType: const FullType(String),
      ),
    ];
    Object? value;
    value = object.loggerName;
    if (value != null) {
      result
        ..add('loggerName')
        ..add(
          serializers.serialize(value, specifiedType: const FullType(String)),
        );
    }
    value = object.error;
    if (value != null) {
      result
        ..add('error')
        ..add(
          serializers.serialize(value, specifiedType: const FullType(String)),
        );
    }
    value = object.stackTrace;
    if (value != null) {
      result
        ..add('stackTrace')
        ..add(
          serializers.serialize(value, specifiedType: const FullType(String)),
        );
    }
    return result;
  }

  @override
  ServerLog deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new ServerLogBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'level':
          result.level =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(Level),
                  )!
                  as Level;
          break;
        case 'message':
          result.message =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )!
                  as String;
          break;
        case 'loggerName':
          result.loggerName =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String?;
          break;
        case 'error':
          result.error =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String?;
          break;
        case 'stackTrace':
          result.stackTrace =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String?;
          break;
      }
    }

    return result.build();
  }
}

class _$ServerLog extends ServerLog {
  @override
  final Level level;
  @override
  final String message;
  @override
  final String? loggerName;
  @override
  final String? error;
  @override
  final String? stackTrace;

  factory _$ServerLog([void Function(ServerLogBuilder)? updates]) =>
      (new ServerLogBuilder()..update(updates))._build();

  _$ServerLog._({
    required this.level,
    required this.message,
    this.loggerName,
    this.error,
    this.stackTrace,
  }) : super._() {
    BuiltValueNullFieldError.checkNotNull(level, r'ServerLog', 'level');
    BuiltValueNullFieldError.checkNotNull(message, r'ServerLog', 'message');
  }

  @override
  ServerLog rebuild(void Function(ServerLogBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ServerLogBuilder toBuilder() => new ServerLogBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ServerLog &&
        level == other.level &&
        message == other.message &&
        loggerName == other.loggerName &&
        error == other.error &&
        stackTrace == other.stackTrace;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, level.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, loggerName.hashCode);
    _$hash = $jc(_$hash, error.hashCode);
    _$hash = $jc(_$hash, stackTrace.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ServerLog')
          ..add('level', level)
          ..add('message', message)
          ..add('loggerName', loggerName)
          ..add('error', error)
          ..add('stackTrace', stackTrace))
        .toString();
  }
}

class ServerLogBuilder implements Builder<ServerLog, ServerLogBuilder> {
  _$ServerLog? _$v;

  Level? _level;
  Level? get level => _$this._level;
  set level(Level? level) => _$this._level = level;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  String? _loggerName;
  String? get loggerName => _$this._loggerName;
  set loggerName(String? loggerName) => _$this._loggerName = loggerName;

  String? _error;
  String? get error => _$this._error;
  set error(String? error) => _$this._error = error;

  String? _stackTrace;
  String? get stackTrace => _$this._stackTrace;
  set stackTrace(String? stackTrace) => _$this._stackTrace = stackTrace;

  ServerLogBuilder();

  ServerLogBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _level = $v.level;
      _message = $v.message;
      _loggerName = $v.loggerName;
      _error = $v.error;
      _stackTrace = $v.stackTrace;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ServerLog other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ServerLog;
  }

  @override
  void update(void Function(ServerLogBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ServerLog build() => _build();

  _$ServerLog _build() {
    final _$result =
        _$v ??
        new _$ServerLog._(
          level: BuiltValueNullFieldError.checkNotNull(
            level,
            r'ServerLog',
            'level',
          ),
          message: BuiltValueNullFieldError.checkNotNull(
            message,
            r'ServerLog',
            'message',
          ),
          loggerName: loggerName,
          error: error,
          stackTrace: stackTrace,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
