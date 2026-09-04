// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finished_shared_part.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FinishedSharedPart extends FinishedSharedPart {
  @override
  final AssetId libraryId;
  @override
  final String? languageVersion;
  @override
  final BuiltMap<int, BuiltList<String>> imports;
  @override
  final BuiltMap<int, String> contributions;

  factory _$FinishedSharedPart([
    void Function(FinishedSharedPartBuilder)? updates,
  ]) => (FinishedSharedPartBuilder()..update(updates))._build();

  _$FinishedSharedPart._({
    required this.libraryId,
    this.languageVersion,
    required this.imports,
    required this.contributions,
  }) : super._();
  @override
  FinishedSharedPart rebuild(
    void Function(FinishedSharedPartBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  FinishedSharedPartBuilder toBuilder() =>
      FinishedSharedPartBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FinishedSharedPart &&
        libraryId == other.libraryId &&
        languageVersion == other.languageVersion &&
        imports == other.imports &&
        contributions == other.contributions;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, libraryId.hashCode);
    _$hash = $jc(_$hash, languageVersion.hashCode);
    _$hash = $jc(_$hash, imports.hashCode);
    _$hash = $jc(_$hash, contributions.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FinishedSharedPart')
          ..add('libraryId', libraryId)
          ..add('languageVersion', languageVersion)
          ..add('imports', imports)
          ..add('contributions', contributions))
        .toString();
  }
}

class FinishedSharedPartBuilder
    implements Builder<FinishedSharedPart, FinishedSharedPartBuilder> {
  _$FinishedSharedPart? _$v;

  AssetId? _libraryId;
  AssetId? get libraryId => _$this._libraryId;
  set libraryId(AssetId? libraryId) => _$this._libraryId = libraryId;

  String? _languageVersion;
  String? get languageVersion => _$this._languageVersion;
  set languageVersion(String? languageVersion) =>
      _$this._languageVersion = languageVersion;

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

  FinishedSharedPartBuilder();

  FinishedSharedPartBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _libraryId = $v.libraryId;
      _languageVersion = $v.languageVersion;
      _imports = $v.imports.toBuilder();
      _contributions = $v.contributions.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FinishedSharedPart other) {
    _$v = other as _$FinishedSharedPart;
  }

  @override
  void update(void Function(FinishedSharedPartBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FinishedSharedPart build() => _build();

  _$FinishedSharedPart _build() {
    _$FinishedSharedPart _$result;
    try {
      _$result =
          _$v ??
          _$FinishedSharedPart._(
            libraryId: BuiltValueNullFieldError.checkNotNull(
              libraryId,
              r'FinishedSharedPart',
              'libraryId',
            ),
            languageVersion: languageVersion,
            imports: imports.build(),
            contributions: contributions.build(),
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
          r'FinishedSharedPart',
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
