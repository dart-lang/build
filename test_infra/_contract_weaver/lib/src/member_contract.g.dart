// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_contract.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MemberContract extends MemberContract {
  @override
  final BuiltList<String> preconditions;
  @override
  final BuiltList<String> postconditions;
  @override
  final BuiltList<ThrowClauses> throwClauses;

  factory _$MemberContract([void Function(MemberContractBuilder)? updates]) =>
      (MemberContractBuilder()..update(updates))._build();

  _$MemberContract._({
    required this.preconditions,
    required this.postconditions,
    required this.throwClauses,
  }) : super._();
  @override
  MemberContract rebuild(void Function(MemberContractBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MemberContractBuilder toBuilder() => MemberContractBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MemberContract &&
        preconditions == other.preconditions &&
        postconditions == other.postconditions &&
        throwClauses == other.throwClauses;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, preconditions.hashCode);
    _$hash = $jc(_$hash, postconditions.hashCode);
    _$hash = $jc(_$hash, throwClauses.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MemberContract')
          ..add('preconditions', preconditions)
          ..add('postconditions', postconditions)
          ..add('throwClauses', throwClauses))
        .toString();
  }
}

class MemberContractBuilder
    implements Builder<MemberContract, MemberContractBuilder> {
  _$MemberContract? _$v;

  ListBuilder<String>? _preconditions;
  ListBuilder<String> get preconditions =>
      _$this._preconditions ??= ListBuilder<String>();
  set preconditions(ListBuilder<String>? preconditions) =>
      _$this._preconditions = preconditions;

  ListBuilder<String>? _postconditions;
  ListBuilder<String> get postconditions =>
      _$this._postconditions ??= ListBuilder<String>();
  set postconditions(ListBuilder<String>? postconditions) =>
      _$this._postconditions = postconditions;

  ListBuilder<ThrowClauses>? _throwClauses;
  ListBuilder<ThrowClauses> get throwClauses =>
      _$this._throwClauses ??= ListBuilder<ThrowClauses>();
  set throwClauses(ListBuilder<ThrowClauses>? throwClauses) =>
      _$this._throwClauses = throwClauses;

  MemberContractBuilder();

  MemberContractBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _preconditions = $v.preconditions.toBuilder();
      _postconditions = $v.postconditions.toBuilder();
      _throwClauses = $v.throwClauses.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MemberContract other) {
    _$v = other as _$MemberContract;
  }

  @override
  void update(void Function(MemberContractBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MemberContract build() => _build();

  _$MemberContract _build() {
    _$MemberContract _$result;
    try {
      _$result =
          _$v ??
          _$MemberContract._(
            preconditions: preconditions.build(),
            postconditions: postconditions.build(),
            throwClauses: throwClauses.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'preconditions';
        preconditions.build();
        _$failedField = 'postconditions';
        postconditions.build();
        _$failedField = 'throwClauses';
        throwClauses.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'MemberContract',
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
