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
    _$ShutdownNotification
  ];
  @override
  final String wireName = 'ShutdownNotification';

  @override
  Iterable serialize(Serializers serializers, ShutdownNotification object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'message',
      serializers.serialize(object.message,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  ShutdownNotification deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ShutdownNotificationBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'message':
          result.message = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$ShutdownNotification extends ShutdownNotification {
  @override
  final String message;

  factory _$ShutdownNotification(
          [void updates(ShutdownNotificationBuilder b)]) =>
      (new ShutdownNotificationBuilder()..update(updates)).build();

  _$ShutdownNotification._({this.message}) : super._() {
    if (message == null) {
      throw new BuiltValueNullFieldError('ShutdownNotification', 'message');
    }
  }

  @override
  ShutdownNotification rebuild(void updates(ShutdownNotificationBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  ShutdownNotificationBuilder toBuilder() =>
      new ShutdownNotificationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ShutdownNotification && message == other.message;
  }

  @override
  int get hashCode {
    return $jf($jc(0, message.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('ShutdownNotification')
          ..add('message', message))
        .toString();
  }
}

class ShutdownNotificationBuilder
    implements Builder<ShutdownNotification, ShutdownNotificationBuilder> {
  _$ShutdownNotification _$v;

  String _message;
  String get message => _$this._message;
  set message(String message) => _$this._message = message;

  ShutdownNotificationBuilder();

  ShutdownNotificationBuilder get _$this {
    if (_$v != null) {
      _message = _$v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ShutdownNotification other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$ShutdownNotification;
  }

  @override
  void update(void updates(ShutdownNotificationBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$ShutdownNotification build() {
    final _$result = _$v ?? new _$ShutdownNotification._(message: message);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
