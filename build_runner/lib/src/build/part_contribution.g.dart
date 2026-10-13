// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'part_contribution.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PartContribution extends PartContribution {
  @override
  final String builderKey;
  @override
  final BuiltList<String> imports;
  @override
  final String contribution;

  factory _$PartContribution([
    void Function(PartContributionBuilder)? updates,
  ]) => (PartContributionBuilder()..update(updates))._build();

  _$PartContribution._({
    required this.builderKey,
    required this.imports,
    required this.contribution,
  }) : super._();
  @override
  PartContribution rebuild(void Function(PartContributionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PartContributionBuilder toBuilder() =>
      PartContributionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PartContribution &&
        builderKey == other.builderKey &&
        imports == other.imports &&
        contribution == other.contribution;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, builderKey.hashCode);
    _$hash = $jc(_$hash, imports.hashCode);
    _$hash = $jc(_$hash, contribution.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PartContribution')
          ..add('builderKey', builderKey)
          ..add('imports', imports)
          ..add('contribution', contribution))
        .toString();
  }
}

class PartContributionBuilder
    implements Builder<PartContribution, PartContributionBuilder> {
  _$PartContribution? _$v;

  String? _builderKey;
  String? get builderKey => _$this._builderKey;
  set builderKey(String? builderKey) => _$this._builderKey = builderKey;

  ListBuilder<String>? _imports;
  ListBuilder<String> get imports => _$this._imports ??= ListBuilder<String>();
  set imports(ListBuilder<String>? imports) => _$this._imports = imports;

  String? _contribution;
  String? get contribution => _$this._contribution;
  set contribution(String? contribution) => _$this._contribution = contribution;

  PartContributionBuilder();

  PartContributionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _builderKey = $v.builderKey;
      _imports = $v.imports.toBuilder();
      _contribution = $v.contribution;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PartContribution other) {
    _$v = other as _$PartContribution;
  }

  @override
  void update(void Function(PartContributionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PartContribution build() => _build();

  _$PartContribution _build() {
    _$PartContribution _$result;
    try {
      _$result =
          _$v ??
          _$PartContribution._(
            builderKey: BuiltValueNullFieldError.checkNotNull(
              builderKey,
              r'PartContribution',
              'builderKey',
            ),
            imports: imports.build(),
            contribution: BuiltValueNullFieldError.checkNotNull(
              contribution,
              r'PartContribution',
              'contribution',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'imports';
        imports.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PartContribution',
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
