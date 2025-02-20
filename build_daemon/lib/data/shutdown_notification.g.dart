// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shutdown_notification.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<ShutdownNotification> _$shutdownNotificationSerializer =
    new _$ShutdownNotificationSerializer();

class _$ShutdownNotificationSerializer
    implements StructuredSerializer<ShutdownNotification> {
  @override
  final Iterable<Type> types = const [
    ShutdownNotification,
    _$ShutdownNotification,
  ];
  @override
  final String wireName = 'ShutdownNotification';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    ShutdownNotification object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'message',
      serializers.serialize(
        object.message,
        specifiedType: const FullType(String),
      ),
      'failureType',
      serializers.serialize(
        object.failureType,
        specifiedType: const FullType(int),
      ),
    ];

    return result;
  }

  @override
  ShutdownNotification deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new ShutdownNotificationBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'message':
          result.message =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )!
                  as String;
          break;
        case 'failureType':
          result.failureType =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(int),
                  )!
                  as int;
          break;
      }
    }

    return result.build();
  }
}

class _$ShutdownNotification extends ShutdownNotification {
  @override
  final String message;
  @override
  final int failureType;

  factory _$ShutdownNotification([
    void Function(ShutdownNotificationBuilder)? updates,
  ]) => (new ShutdownNotificationBuilder()..update(updates))._build();

  _$ShutdownNotification._({required this.message, required this.failureType})
    : super._() {
    BuiltValueNullFieldError.checkNotNull(
      message,
      r'ShutdownNotification',
      'message',
    );
    BuiltValueNullFieldError.checkNotNull(
      failureType,
      r'ShutdownNotification',
      'failureType',
    );
  }

  @override
  ShutdownNotification rebuild(
    void Function(ShutdownNotificationBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ShutdownNotificationBuilder toBuilder() =>
      new ShutdownNotificationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ShutdownNotification &&
        message == other.message &&
        failureType == other.failureType;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, failureType.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ShutdownNotification')
          ..add('message', message)
          ..add('failureType', failureType))
        .toString();
  }
}

class ShutdownNotificationBuilder
    implements Builder<ShutdownNotification, ShutdownNotificationBuilder> {
  _$ShutdownNotification? _$v;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  int? _failureType;
  int? get failureType => _$this._failureType;
  set failureType(int? failureType) => _$this._failureType = failureType;

  ShutdownNotificationBuilder();

  ShutdownNotificationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _message = $v.message;
      _failureType = $v.failureType;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ShutdownNotification other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ShutdownNotification;
  }

  @override
  void update(void Function(ShutdownNotificationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ShutdownNotification build() => _build();

  _$ShutdownNotification _build() {
    final _$result =
        _$v ??
        new _$ShutdownNotification._(
          message: BuiltValueNullFieldError.checkNotNull(
            message,
            r'ShutdownNotification',
            'message',
          ),
          failureType: BuiltValueNullFieldError.checkNotNull(
            failureType,
            r'ShutdownNotification',
            'failureType',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
