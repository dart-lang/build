// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_part.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SharedPart extends SharedPart {
  @override
  final AssetId primaryInput;
  @override
  final BuiltMap<int, BuiltList<String>> imports;
  @override
  final BuiltMap<int, String> contributions;
  @override
  final String? languageVersion;

  factory _$SharedPart([void Function(SharedPartBuilder)? updates]) =>
      (SharedPartBuilder()..update(updates))._build();

  _$SharedPart._({
    required this.primaryInput,
    required this.imports,
    required this.contributions,
    this.languageVersion,
  }) : super._();
  @override
  SharedPart rebuild(void Function(SharedPartBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SharedPartBuilder toBuilder() => SharedPartBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SharedPart &&
        primaryInput == other.primaryInput &&
        imports == other.imports &&
        contributions == other.contributions &&
        languageVersion == other.languageVersion;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, primaryInput.hashCode);
    _$hash = $jc(_$hash, imports.hashCode);
    _$hash = $jc(_$hash, contributions.hashCode);
    _$hash = $jc(_$hash, languageVersion.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SharedPart')
          ..add('primaryInput', primaryInput)
          ..add('imports', imports)
          ..add('contributions', contributions)
          ..add('languageVersion', languageVersion))
        .toString();
  }
}

class SharedPartBuilder implements Builder<SharedPart, SharedPartBuilder> {
  _$SharedPart? _$v;

  AssetId? _primaryInput;
  AssetId? get primaryInput => _$this._primaryInput;
  set primaryInput(AssetId? primaryInput) =>
      _$this._primaryInput = primaryInput;

  MapBuilder<int, BuiltList<String>>? _imports;
  MapBuilder<int, BuiltList<String>> get imports =>
      _$this._imports ??= MapBuilder<int, BuiltList<String>>();
  set imports(MapBuilder<int, BuiltList<String>>? imports) =>
      _$this._imports = imports;

  MapBuilder<int, String>? _contributions;
  MapBuilder<int, String> get contributions =>
      _$this._contributions ??= MapBuilder<int, String>();
  set contributions(MapBuilder<int, String>? contributions) =>
      _$this._contributions = contributions;

  String? _languageVersion;
  String? get languageVersion => _$this._languageVersion;
  set languageVersion(String? languageVersion) =>
      _$this._languageVersion = languageVersion;

  SharedPartBuilder();

  SharedPartBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _primaryInput = $v.primaryInput;
      _imports = $v.imports.toBuilder();
      _contributions = $v.contributions.toBuilder();
      _languageVersion = $v.languageVersion;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SharedPart other) {
    _$v = other as _$SharedPart;
  }

  @override
  void update(void Function(SharedPartBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SharedPart build() => _build();

  _$SharedPart _build() {
    _$SharedPart _$result;
    try {
      _$result =
          _$v ??
          _$SharedPart._(
            primaryInput: BuiltValueNullFieldError.checkNotNull(
              primaryInput,
              r'SharedPart',
              'primaryInput',
            ),
            imports: imports.build(),
            contributions: contributions.build(),
            languageVersion: languageVersion,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'imports';
        imports.build();
        _$failedField = 'contributions';
        contributions.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'SharedPart',
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
