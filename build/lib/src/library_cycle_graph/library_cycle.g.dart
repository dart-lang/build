// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_cycle.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LibraryCycle extends LibraryCycle {
  @override
  final BuiltSet<AssetId> ids;

  factory _$LibraryCycle([void Function(LibraryCycleBuilder)? updates]) =>
      (new LibraryCycleBuilder()..update(updates))._build();

  _$LibraryCycle._({required this.ids}) : super._() {
    BuiltValueNullFieldError.checkNotNull(ids, r'LibraryCycle', 'ids');
  }

  @override
  LibraryCycle rebuild(void Function(LibraryCycleBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LibraryCycleBuilder toBuilder() => new LibraryCycleBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LibraryCycle && ids == other.ids;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, ids.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LibraryCycle')
      ..add('ids', ids)).toString();
  }
}

class LibraryCycleBuilder
    implements Builder<LibraryCycle, LibraryCycleBuilder> {
  _$LibraryCycle? _$v;

  SetBuilder<AssetId>? _ids;
  SetBuilder<AssetId> get ids => _$this._ids ??= new SetBuilder<AssetId>();
  set ids(SetBuilder<AssetId>? ids) => _$this._ids = ids;

  LibraryCycleBuilder();

  LibraryCycleBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _ids = $v.ids.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LibraryCycle other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$LibraryCycle;
  }

  @override
  void update(void Function(LibraryCycleBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LibraryCycle build() => _build();

  _$LibraryCycle _build() {
    _$LibraryCycle _$result;
    try {
      _$result = _$v ?? new _$LibraryCycle._(ids: ids.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'ids';
        ids.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'LibraryCycle',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
