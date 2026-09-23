// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invariant_hooks.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$InvariantHooks extends InvariantHooks {
  @override
  final String className;
  @override
  final bool mightMutate;

  factory _$InvariantHooks([void Function(InvariantHooksBuilder)? updates]) =>
      (InvariantHooksBuilder()..update(updates))._build();

  _$InvariantHooks._({required this.className, required this.mightMutate})
    : super._();
  @override
  InvariantHooks rebuild(void Function(InvariantHooksBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  InvariantHooksBuilder toBuilder() => InvariantHooksBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is InvariantHooks &&
        className == other.className &&
        mightMutate == other.mightMutate;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, className.hashCode);
    _$hash = $jc(_$hash, mightMutate.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'InvariantHooks')
          ..add('className', className)
          ..add('mightMutate', mightMutate))
        .toString();
  }
}

class InvariantHooksBuilder
    implements Builder<InvariantHooks, InvariantHooksBuilder> {
  _$InvariantHooks? _$v;

  String? _className;
  String? get className => _$this._className;
  set className(String? className) => _$this._className = className;

  bool? _mightMutate;
  bool? get mightMutate => _$this._mightMutate;
  set mightMutate(bool? mightMutate) => _$this._mightMutate = mightMutate;

  InvariantHooksBuilder();

  InvariantHooksBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _className = $v.className;
      _mightMutate = $v.mightMutate;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(InvariantHooks other) {
    _$v = other as _$InvariantHooks;
  }

  @override
  void update(void Function(InvariantHooksBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  InvariantHooks build() => _build();

  _$InvariantHooks _build() {
    final _$result =
        _$v ??
        _$InvariantHooks._(
          className: BuiltValueNullFieldError.checkNotNull(
            className,
            r'InvariantHooks',
            'className',
          ),
          mightMutate: BuiltValueNullFieldError.checkNotNull(
            mightMutate,
            r'InvariantHooks',
            'mightMutate',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
