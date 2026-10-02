// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_edit.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SourceEdit extends SourceEdit {
  @override
  final int offset;
  @override
  final int length;
  @override
  final String text;

  factory _$SourceEdit([void Function(SourceEditBuilder)? updates]) =>
      (SourceEditBuilder()..update(updates))._build();

  _$SourceEdit._({
    required this.offset,
    required this.length,
    required this.text,
  }) : super._();
  @override
  SourceEdit rebuild(void Function(SourceEditBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SourceEditBuilder toBuilder() => SourceEditBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SourceEdit &&
        offset == other.offset &&
        length == other.length &&
        text == other.text;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, offset.hashCode);
    _$hash = $jc(_$hash, length.hashCode);
    _$hash = $jc(_$hash, text.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SourceEdit')
          ..add('offset', offset)
          ..add('length', length)
          ..add('text', text))
        .toString();
  }
}

class SourceEditBuilder implements Builder<SourceEdit, SourceEditBuilder> {
  _$SourceEdit? _$v;

  int? _offset;
  int? get offset => _$this._offset;
  set offset(int? offset) => _$this._offset = offset;

  int? _length;
  int? get length => _$this._length;
  set length(int? length) => _$this._length = length;

  String? _text;
  String? get text => _$this._text;
  set text(String? text) => _$this._text = text;

  SourceEditBuilder();

  SourceEditBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _offset = $v.offset;
      _length = $v.length;
      _text = $v.text;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SourceEdit other) {
    _$v = other as _$SourceEdit;
  }

  @override
  void update(void Function(SourceEditBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SourceEdit build() => _build();

  _$SourceEdit _build() {
    final _$result =
        _$v ??
        _$SourceEdit._(
          offset: BuiltValueNullFieldError.checkNotNull(
            offset,
            r'SourceEdit',
            'offset',
          ),
          length: BuiltValueNullFieldError.checkNotNull(
            length,
            r'SourceEdit',
            'length',
          ),
          text: BuiltValueNullFieldError.checkNotNull(
            text,
            r'SourceEdit',
            'text',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
