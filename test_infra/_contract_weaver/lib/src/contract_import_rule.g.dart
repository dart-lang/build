// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_import_rule.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ContractImportRule extends ContractImportRule {
  @override
  final BuiltList<String> markers;
  @override
  final String import;

  factory _$ContractImportRule([
    void Function(ContractImportRuleBuilder)? updates,
  ]) => (ContractImportRuleBuilder()..update(updates))._build();

  _$ContractImportRule._({required this.markers, required this.import})
    : super._();
  @override
  ContractImportRule rebuild(
    void Function(ContractImportRuleBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ContractImportRuleBuilder toBuilder() =>
      ContractImportRuleBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ContractImportRule &&
        markers == other.markers &&
        import == other.import;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, markers.hashCode);
    _$hash = $jc(_$hash, import.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ContractImportRule')
          ..add('markers', markers)
          ..add('import', import))
        .toString();
  }
}

class ContractImportRuleBuilder
    implements Builder<ContractImportRule, ContractImportRuleBuilder> {
  _$ContractImportRule? _$v;

  ListBuilder<String>? _markers;
  ListBuilder<String> get markers => _$this._markers ??= ListBuilder<String>();
  set markers(ListBuilder<String>? markers) => _$this._markers = markers;

  String? _import;
  String? get import => _$this._import;
  set import(String? import) => _$this._import = import;

  ContractImportRuleBuilder();

  ContractImportRuleBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _markers = $v.markers.toBuilder();
      _import = $v.import;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ContractImportRule other) {
    _$v = other as _$ContractImportRule;
  }

  @override
  void update(void Function(ContractImportRuleBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ContractImportRule build() => _build();

  _$ContractImportRule _build() {
    _$ContractImportRule _$result;
    try {
      _$result =
          _$v ??
          _$ContractImportRule._(
            markers: markers.build(),
            import: BuiltValueNullFieldError.checkNotNull(
              import,
              r'ContractImportRule',
              'import',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'markers';
        markers.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ContractImportRule',
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
