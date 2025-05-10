// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_log_messages.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Message extends Message {
  @override
  final String? phaseName;
  @override
  final String? context;
  @override
  final Severity severity;
  @override
  final String text;

  factory _$Message([void Function(MessageBuilder)? updates]) =>
      (MessageBuilder()..update(updates))._build();

  _$Message._({
    this.phaseName,
    this.context,
    required this.severity,
    required this.text,
  }) : super._();
  @override
  Message rebuild(void Function(MessageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MessageBuilder toBuilder() => MessageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Message &&
        phaseName == other.phaseName &&
        context == other.context &&
        severity == other.severity &&
        text == other.text;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, phaseName.hashCode);
    _$hash = $jc(_$hash, context.hashCode);
    _$hash = $jc(_$hash, severity.hashCode);
    _$hash = $jc(_$hash, text.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Message')
          ..add('phaseName', phaseName)
          ..add('context', context)
          ..add('severity', severity)
          ..add('text', text))
        .toString();
  }
}

class MessageBuilder implements Builder<Message, MessageBuilder> {
  _$Message? _$v;

  String? _phaseName;
  String? get phaseName => _$this._phaseName;
  set phaseName(String? phaseName) => _$this._phaseName = phaseName;

  String? _context;
  String? get context => _$this._context;
  set context(String? context) => _$this._context = context;

  Severity? _severity;
  Severity? get severity => _$this._severity;
  set severity(Severity? severity) => _$this._severity = severity;

  String? _text;
  String? get text => _$this._text;
  set text(String? text) => _$this._text = text;

  MessageBuilder();

  MessageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _phaseName = $v.phaseName;
      _context = $v.context;
      _severity = $v.severity;
      _text = $v.text;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Message other) {
    _$v = other as _$Message;
  }

  @override
  void update(void Function(MessageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Message build() => _build();

  _$Message _build() {
    final _$result =
        _$v ??
        _$Message._(
          phaseName: phaseName,
          context: context,
          severity: BuiltValueNullFieldError.checkNotNull(
            severity,
            r'Message',
            'severity',
          ),
          text: BuiltValueNullFieldError.checkNotNull(text, r'Message', 'text'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
