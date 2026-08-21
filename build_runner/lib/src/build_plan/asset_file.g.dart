// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_file.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AssetFile extends AssetFile {
  @override
  final AssetId id;
  @override
  final bool hidden;

  factory _$AssetFile([void Function(AssetFileBuilder)? updates]) =>
      (AssetFileBuilder()..update(updates))._build();

  _$AssetFile._({required this.id, required this.hidden}) : super._();
  @override
  AssetFile rebuild(void Function(AssetFileBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AssetFileBuilder toBuilder() => AssetFileBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AssetFile && id == other.id && hidden == other.hidden;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, hidden.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AssetFile')
          ..add('id', id)
          ..add('hidden', hidden))
        .toString();
  }
}

class AssetFileBuilder implements Builder<AssetFile, AssetFileBuilder> {
  _$AssetFile? _$v;

  AssetId? _id;
  AssetId? get id => _$this._id;
  set id(AssetId? id) => _$this._id = id;

  bool? _hidden;
  bool? get hidden => _$this._hidden;
  set hidden(bool? hidden) => _$this._hidden = hidden;

  AssetFileBuilder();

  AssetFileBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _hidden = $v.hidden;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AssetFile other) {
    _$v = other as _$AssetFile;
  }

  @override
  void update(void Function(AssetFileBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AssetFile build() => _build();

  _$AssetFile _build() {
    final _$result =
        _$v ??
        _$AssetFile._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'AssetFile', 'id'),
          hidden: BuiltValueNullFieldError.checkNotNull(
            hidden,
            r'AssetFile',
            'hidden',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
