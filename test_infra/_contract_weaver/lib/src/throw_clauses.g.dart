// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'throw_clauses.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ThrowClauses extends ThrowClauses {
  @override
  final String type;
  @override
  final BuiltList<String> clauses;

  factory _$ThrowClauses([void Function(ThrowClausesBuilder)? updates]) =>
      (ThrowClausesBuilder()..update(updates))._build();

  _$ThrowClauses._({required this.type, required this.clauses}) : super._();
  @override
  ThrowClauses rebuild(void Function(ThrowClausesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ThrowClausesBuilder toBuilder() => ThrowClausesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ThrowClauses &&
        type == other.type &&
        clauses == other.clauses;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, clauses.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ThrowClauses')
          ..add('type', type)
          ..add('clauses', clauses))
        .toString();
  }
}

class ThrowClausesBuilder
    implements Builder<ThrowClauses, ThrowClausesBuilder> {
  _$ThrowClauses? _$v;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  ListBuilder<String>? _clauses;
  ListBuilder<String> get clauses => _$this._clauses ??= ListBuilder<String>();
  set clauses(ListBuilder<String>? clauses) => _$this._clauses = clauses;

  ThrowClausesBuilder();

  ThrowClausesBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _type = $v.type;
      _clauses = $v.clauses.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ThrowClauses other) {
    _$v = other as _$ThrowClauses;
  }

  @override
  void update(void Function(ThrowClausesBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ThrowClauses build() => _build();

  _$ThrowClauses _build() {
    _$ThrowClauses _$result;
    try {
      _$result =
          _$v ??
          _$ThrowClauses._(
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'ThrowClauses',
              'type',
            ),
            clauses: clauses.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'clauses';
        clauses.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ThrowClauses',
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
