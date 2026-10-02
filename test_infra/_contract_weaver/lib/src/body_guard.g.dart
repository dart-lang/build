// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_guard.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BodyGuard extends BodyGuard {
  @override
  final InvariantHooks? invariant;
  @override
  final BuiltList<ThrowClauses> throwClauses;

  factory _$BodyGuard([void Function(BodyGuardBuilder)? updates]) =>
      (BodyGuardBuilder()..update(updates))._build();

  _$BodyGuard._({this.invariant, required this.throwClauses}) : super._();
  @override
  BodyGuard rebuild(void Function(BodyGuardBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BodyGuardBuilder toBuilder() => BodyGuardBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BodyGuard &&
        invariant == other.invariant &&
        throwClauses == other.throwClauses;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, invariant.hashCode);
    _$hash = $jc(_$hash, throwClauses.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BodyGuard')
          ..add('invariant', invariant)
          ..add('throwClauses', throwClauses))
        .toString();
  }
}

class BodyGuardBuilder implements Builder<BodyGuard, BodyGuardBuilder> {
  _$BodyGuard? _$v;

  InvariantHooksBuilder? _invariant;
  InvariantHooksBuilder get invariant =>
      _$this._invariant ??= InvariantHooksBuilder();
  set invariant(InvariantHooksBuilder? invariant) =>
      _$this._invariant = invariant;

  ListBuilder<ThrowClauses>? _throwClauses;
  ListBuilder<ThrowClauses> get throwClauses =>
      _$this._throwClauses ??= ListBuilder<ThrowClauses>();
  set throwClauses(ListBuilder<ThrowClauses>? throwClauses) =>
      _$this._throwClauses = throwClauses;

  BodyGuardBuilder();

  BodyGuardBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _invariant = $v.invariant?.toBuilder();
      _throwClauses = $v.throwClauses.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BodyGuard other) {
    _$v = other as _$BodyGuard;
  }

  @override
  void update(void Function(BodyGuardBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BodyGuard build() => _build();

  _$BodyGuard _build() {
    _$BodyGuard _$result;
    try {
      _$result =
          _$v ??
          _$BodyGuard._(
            invariant: _invariant?.build(),
            throwClauses: throwClauses.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'invariant';
        _invariant?.build();
        _$failedField = 'throwClauses';
        throwClauses.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'BodyGuard',
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
