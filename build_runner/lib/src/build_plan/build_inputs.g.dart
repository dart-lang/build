// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_inputs.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BuildInputs extends BuildInputs {
  @override
  final bool cleanBuild;
  @override
  final BuiltSet<AssetId> sources;
  @override
  final BuiltMap<AssetId, AssetContent> sourceContents;
  @override
  final BuiltSet<AssetId> addedSources;
  @override
  final BuiltSet<AssetId> deletedSources;
  @override
  final BuiltSet<AssetId> modifiedSources;
  @override
  final BuiltSet<AssetId> deletedOutputs;

  factory _$BuildInputs([void Function(BuildInputsBuilder)? updates]) =>
      (BuildInputsBuilder()..update(updates))._build();

  _$BuildInputs._({
    required this.cleanBuild,
    required this.sources,
    required this.sourceContents,
    required this.addedSources,
    required this.deletedSources,
    required this.modifiedSources,
    required this.deletedOutputs,
  }) : super._();
  @override
  BuildInputs rebuild(void Function(BuildInputsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BuildInputsBuilder toBuilder() => BuildInputsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BuildInputs &&
        cleanBuild == other.cleanBuild &&
        sources == other.sources &&
        sourceContents == other.sourceContents &&
        addedSources == other.addedSources &&
        deletedSources == other.deletedSources &&
        modifiedSources == other.modifiedSources &&
        deletedOutputs == other.deletedOutputs;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, cleanBuild.hashCode);
    _$hash = $jc(_$hash, sources.hashCode);
    _$hash = $jc(_$hash, sourceContents.hashCode);
    _$hash = $jc(_$hash, addedSources.hashCode);
    _$hash = $jc(_$hash, deletedSources.hashCode);
    _$hash = $jc(_$hash, modifiedSources.hashCode);
    _$hash = $jc(_$hash, deletedOutputs.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BuildInputs')
          ..add('cleanBuild', cleanBuild)
          ..add('sources', sources)
          ..add('sourceContents', sourceContents)
          ..add('addedSources', addedSources)
          ..add('deletedSources', deletedSources)
          ..add('modifiedSources', modifiedSources)
          ..add('deletedOutputs', deletedOutputs))
        .toString();
  }
}

class BuildInputsBuilder implements Builder<BuildInputs, BuildInputsBuilder> {
  _$BuildInputs? _$v;

  bool? _cleanBuild;
  bool? get cleanBuild => _$this._cleanBuild;
  set cleanBuild(bool? cleanBuild) => _$this._cleanBuild = cleanBuild;

  SetBuilder<AssetId>? _sources;
  SetBuilder<AssetId> get sources => _$this._sources ??= SetBuilder<AssetId>();
  set sources(SetBuilder<AssetId>? sources) => _$this._sources = sources;

  MapBuilder<AssetId, AssetContent>? _sourceContents;
  MapBuilder<AssetId, AssetContent> get sourceContents =>
      _$this._sourceContents ??= MapBuilder<AssetId, AssetContent>();
  set sourceContents(MapBuilder<AssetId, AssetContent>? sourceContents) =>
      _$this._sourceContents = sourceContents;

  SetBuilder<AssetId>? _addedSources;
  SetBuilder<AssetId> get addedSources =>
      _$this._addedSources ??= SetBuilder<AssetId>();
  set addedSources(SetBuilder<AssetId>? addedSources) =>
      _$this._addedSources = addedSources;

  SetBuilder<AssetId>? _deletedSources;
  SetBuilder<AssetId> get deletedSources =>
      _$this._deletedSources ??= SetBuilder<AssetId>();
  set deletedSources(SetBuilder<AssetId>? deletedSources) =>
      _$this._deletedSources = deletedSources;

  SetBuilder<AssetId>? _modifiedSources;
  SetBuilder<AssetId> get modifiedSources =>
      _$this._modifiedSources ??= SetBuilder<AssetId>();
  set modifiedSources(SetBuilder<AssetId>? modifiedSources) =>
      _$this._modifiedSources = modifiedSources;

  SetBuilder<AssetId>? _deletedOutputs;
  SetBuilder<AssetId> get deletedOutputs =>
      _$this._deletedOutputs ??= SetBuilder<AssetId>();
  set deletedOutputs(SetBuilder<AssetId>? deletedOutputs) =>
      _$this._deletedOutputs = deletedOutputs;

  BuildInputsBuilder();

  BuildInputsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _cleanBuild = $v.cleanBuild;
      _sources = $v.sources.toBuilder();
      _sourceContents = $v.sourceContents.toBuilder();
      _addedSources = $v.addedSources.toBuilder();
      _deletedSources = $v.deletedSources.toBuilder();
      _modifiedSources = $v.modifiedSources.toBuilder();
      _deletedOutputs = $v.deletedOutputs.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BuildInputs other) {
    _$v = other as _$BuildInputs;
  }

  @override
  void update(void Function(BuildInputsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BuildInputs build() => _build();

  _$BuildInputs _build() {
    _$BuildInputs _$result;
    try {
      _$result =
          _$v ??
          _$BuildInputs._(
            cleanBuild: BuiltValueNullFieldError.checkNotNull(
              cleanBuild,
              r'BuildInputs',
              'cleanBuild',
            ),
            sources: sources.build(),
            sourceContents: sourceContents.build(),
            addedSources: addedSources.build(),
            deletedSources: deletedSources.build(),
            modifiedSources: modifiedSources.build(),
            deletedOutputs: deletedOutputs.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'sources';
        sources.build();
        _$failedField = 'sourceContents';
        sourceContents.build();
        _$failedField = 'addedSources';
        addedSources.build();
        _$failedField = 'deletedSources';
        deletedSources.build();
        _$failedField = 'modifiedSources';
        modifiedSources.build();
        _$failedField = 'deletedOutputs';
        deletedOutputs.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'BuildInputs',
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
