// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_layout.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PackageLayout extends PackageLayout {
  @override
  final String root;
  @override
  final String? member;

  factory _$PackageLayout([void Function(PackageLayoutBuilder)? updates]) =>
      (PackageLayoutBuilder()..update(updates))._build();

  _$PackageLayout._({required this.root, this.member}) : super._();
  @override
  PackageLayout rebuild(void Function(PackageLayoutBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PackageLayoutBuilder toBuilder() => PackageLayoutBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PackageLayout &&
        root == other.root &&
        member == other.member;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, root.hashCode);
    _$hash = $jc(_$hash, member.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PackageLayout')
          ..add('root', root)
          ..add('member', member))
        .toString();
  }
}

class PackageLayoutBuilder
    implements Builder<PackageLayout, PackageLayoutBuilder> {
  _$PackageLayout? _$v;

  String? _root;
  String? get root => _$this._root;
  set root(String? root) => _$this._root = root;

  String? _member;
  String? get member => _$this._member;
  set member(String? member) => _$this._member = member;

  PackageLayoutBuilder();

  PackageLayoutBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _root = $v.root;
      _member = $v.member;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PackageLayout other) {
    _$v = other as _$PackageLayout;
  }

  @override
  void update(void Function(PackageLayoutBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PackageLayout build() => _build();

  _$PackageLayout _build() {
    final _$result =
        _$v ??
        _$PackageLayout._(
          root: BuiltValueNullFieldError.checkNotNull(
            root,
            r'PackageLayout',
            'root',
          ),
          member: member,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
