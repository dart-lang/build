// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_plan.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BuildPlan extends BuildPlan {
  @override
  final BuildSpec buildSpec;
  @override
  final BuiltSet<BuildDirectory> buildDirs;
  @override
  final BuiltSet<BuildFilter> buildFilters;
  @override
  final ReaderWriter readerWriter;
  @override
  final BuildState? previousBuildState;
  @override
  final PhasedAssetDeps? previousPhasedAssetDeps;
  @override
  final BuildStepPlan buildStepPlan;
  @override
  final bool triggersChanged;
  @override
  final BuiltList<bool> phaseOptionsChangedList;
  @override
  final BuiltList<bool> postBuildOptionsChangedList;
  @override
  final BuiltList<AssetId> filesToDelete;
  @override
  final BuiltList<AssetId> foldersToDelete;
  @override
  final BuildInputs buildInputs;

  factory _$BuildPlan([void Function(BuildPlanBuilder)? updates]) =>
      (BuildPlanBuilder()..update(updates))._build();

  _$BuildPlan._({
    required this.buildSpec,
    required this.buildDirs,
    required this.buildFilters,
    required this.readerWriter,
    this.previousBuildState,
    this.previousPhasedAssetDeps,
    required this.buildStepPlan,
    required this.triggersChanged,
    required this.phaseOptionsChangedList,
    required this.postBuildOptionsChangedList,
    required this.filesToDelete,
    required this.foldersToDelete,
    required this.buildInputs,
  }) : super._();
  @override
  BuildPlan rebuild(void Function(BuildPlanBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BuildPlanBuilder toBuilder() => BuildPlanBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BuildPlan &&
        buildSpec == other.buildSpec &&
        buildDirs == other.buildDirs &&
        buildFilters == other.buildFilters &&
        readerWriter == other.readerWriter &&
        previousBuildState == other.previousBuildState &&
        previousPhasedAssetDeps == other.previousPhasedAssetDeps &&
        buildStepPlan == other.buildStepPlan &&
        triggersChanged == other.triggersChanged &&
        phaseOptionsChangedList == other.phaseOptionsChangedList &&
        postBuildOptionsChangedList == other.postBuildOptionsChangedList &&
        filesToDelete == other.filesToDelete &&
        foldersToDelete == other.foldersToDelete &&
        buildInputs == other.buildInputs;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, buildSpec.hashCode);
    _$hash = $jc(_$hash, buildDirs.hashCode);
    _$hash = $jc(_$hash, buildFilters.hashCode);
    _$hash = $jc(_$hash, readerWriter.hashCode);
    _$hash = $jc(_$hash, previousBuildState.hashCode);
    _$hash = $jc(_$hash, previousPhasedAssetDeps.hashCode);
    _$hash = $jc(_$hash, buildStepPlan.hashCode);
    _$hash = $jc(_$hash, triggersChanged.hashCode);
    _$hash = $jc(_$hash, phaseOptionsChangedList.hashCode);
    _$hash = $jc(_$hash, postBuildOptionsChangedList.hashCode);
    _$hash = $jc(_$hash, filesToDelete.hashCode);
    _$hash = $jc(_$hash, foldersToDelete.hashCode);
    _$hash = $jc(_$hash, buildInputs.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BuildPlan')
          ..add('buildSpec', buildSpec)
          ..add('buildDirs', buildDirs)
          ..add('buildFilters', buildFilters)
          ..add('readerWriter', readerWriter)
          ..add('previousBuildState', previousBuildState)
          ..add('previousPhasedAssetDeps', previousPhasedAssetDeps)
          ..add('buildStepPlan', buildStepPlan)
          ..add('triggersChanged', triggersChanged)
          ..add('phaseOptionsChangedList', phaseOptionsChangedList)
          ..add('postBuildOptionsChangedList', postBuildOptionsChangedList)
          ..add('filesToDelete', filesToDelete)
          ..add('foldersToDelete', foldersToDelete)
          ..add('buildInputs', buildInputs))
        .toString();
  }
}

class BuildPlanBuilder implements Builder<BuildPlan, BuildPlanBuilder> {
  _$BuildPlan? _$v;

  BuildSpecBuilder? _buildSpec;
  BuildSpecBuilder get buildSpec => _$this._buildSpec ??= BuildSpecBuilder();
  set buildSpec(BuildSpecBuilder? buildSpec) => _$this._buildSpec = buildSpec;

  SetBuilder<BuildDirectory>? _buildDirs;
  SetBuilder<BuildDirectory> get buildDirs =>
      _$this._buildDirs ??= SetBuilder<BuildDirectory>();
  set buildDirs(SetBuilder<BuildDirectory>? buildDirs) =>
      _$this._buildDirs = buildDirs;

  SetBuilder<BuildFilter>? _buildFilters;
  SetBuilder<BuildFilter> get buildFilters =>
      _$this._buildFilters ??= SetBuilder<BuildFilter>();
  set buildFilters(SetBuilder<BuildFilter>? buildFilters) =>
      _$this._buildFilters = buildFilters;

  ReaderWriter? _readerWriter;
  ReaderWriter? get readerWriter => _$this._readerWriter;
  set readerWriter(ReaderWriter? readerWriter) =>
      _$this._readerWriter = readerWriter;

  BuildState? _previousBuildState;
  BuildState? get previousBuildState => _$this._previousBuildState;
  set previousBuildState(BuildState? previousBuildState) =>
      _$this._previousBuildState = previousBuildState;

  PhasedAssetDepsBuilder? _previousPhasedAssetDeps;
  PhasedAssetDepsBuilder get previousPhasedAssetDeps =>
      _$this._previousPhasedAssetDeps ??= PhasedAssetDepsBuilder();
  set previousPhasedAssetDeps(
    PhasedAssetDepsBuilder? previousPhasedAssetDeps,
  ) => _$this._previousPhasedAssetDeps = previousPhasedAssetDeps;

  BuildStepPlanBuilder? _buildStepPlan;
  BuildStepPlanBuilder get buildStepPlan =>
      _$this._buildStepPlan ??= BuildStepPlanBuilder();
  set buildStepPlan(BuildStepPlanBuilder? buildStepPlan) =>
      _$this._buildStepPlan = buildStepPlan;

  bool? _triggersChanged;
  bool? get triggersChanged => _$this._triggersChanged;
  set triggersChanged(bool? triggersChanged) =>
      _$this._triggersChanged = triggersChanged;

  ListBuilder<bool>? _phaseOptionsChangedList;
  ListBuilder<bool> get phaseOptionsChangedList =>
      _$this._phaseOptionsChangedList ??= ListBuilder<bool>();
  set phaseOptionsChangedList(ListBuilder<bool>? phaseOptionsChangedList) =>
      _$this._phaseOptionsChangedList = phaseOptionsChangedList;

  ListBuilder<bool>? _postBuildOptionsChangedList;
  ListBuilder<bool> get postBuildOptionsChangedList =>
      _$this._postBuildOptionsChangedList ??= ListBuilder<bool>();
  set postBuildOptionsChangedList(
    ListBuilder<bool>? postBuildOptionsChangedList,
  ) => _$this._postBuildOptionsChangedList = postBuildOptionsChangedList;

  ListBuilder<AssetId>? _filesToDelete;
  ListBuilder<AssetId> get filesToDelete =>
      _$this._filesToDelete ??= ListBuilder<AssetId>();
  set filesToDelete(ListBuilder<AssetId>? filesToDelete) =>
      _$this._filesToDelete = filesToDelete;

  ListBuilder<AssetId>? _foldersToDelete;
  ListBuilder<AssetId> get foldersToDelete =>
      _$this._foldersToDelete ??= ListBuilder<AssetId>();
  set foldersToDelete(ListBuilder<AssetId>? foldersToDelete) =>
      _$this._foldersToDelete = foldersToDelete;

  BuildInputsBuilder? _buildInputs;
  BuildInputsBuilder get buildInputs =>
      _$this._buildInputs ??= BuildInputsBuilder();
  set buildInputs(BuildInputsBuilder? buildInputs) =>
      _$this._buildInputs = buildInputs;

  BuildPlanBuilder();

  BuildPlanBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _buildSpec = $v.buildSpec.toBuilder();
      _buildDirs = $v.buildDirs.toBuilder();
      _buildFilters = $v.buildFilters.toBuilder();
      _readerWriter = $v.readerWriter;
      _previousBuildState = $v.previousBuildState;
      _previousPhasedAssetDeps = $v.previousPhasedAssetDeps?.toBuilder();
      _buildStepPlan = $v.buildStepPlan.toBuilder();
      _triggersChanged = $v.triggersChanged;
      _phaseOptionsChangedList = $v.phaseOptionsChangedList.toBuilder();
      _postBuildOptionsChangedList = $v.postBuildOptionsChangedList.toBuilder();
      _filesToDelete = $v.filesToDelete.toBuilder();
      _foldersToDelete = $v.foldersToDelete.toBuilder();
      _buildInputs = $v.buildInputs.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BuildPlan other) {
    _$v = other as _$BuildPlan;
  }

  @override
  void update(void Function(BuildPlanBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BuildPlan build() => _build();

  _$BuildPlan _build() {
    _$BuildPlan _$result;
    try {
      _$result =
          _$v ??
          _$BuildPlan._(
            buildSpec: buildSpec.build(),
            buildDirs: buildDirs.build(),
            buildFilters: buildFilters.build(),
            readerWriter: BuiltValueNullFieldError.checkNotNull(
              readerWriter,
              r'BuildPlan',
              'readerWriter',
            ),
            previousBuildState: previousBuildState,
            previousPhasedAssetDeps: _previousPhasedAssetDeps?.build(),
            buildStepPlan: buildStepPlan.build(),
            triggersChanged: BuiltValueNullFieldError.checkNotNull(
              triggersChanged,
              r'BuildPlan',
              'triggersChanged',
            ),
            phaseOptionsChangedList: phaseOptionsChangedList.build(),
            postBuildOptionsChangedList: postBuildOptionsChangedList.build(),
            filesToDelete: filesToDelete.build(),
            foldersToDelete: foldersToDelete.build(),
            buildInputs: buildInputs.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'buildSpec';
        buildSpec.build();
        _$failedField = 'buildDirs';
        buildDirs.build();
        _$failedField = 'buildFilters';
        buildFilters.build();

        _$failedField = 'previousPhasedAssetDeps';
        _previousPhasedAssetDeps?.build();
        _$failedField = 'buildStepPlan';
        buildStepPlan.build();

        _$failedField = 'phaseOptionsChangedList';
        phaseOptionsChangedList.build();
        _$failedField = 'postBuildOptionsChangedList';
        postBuildOptionsChangedList.build();
        _$failedField = 'filesToDelete';
        filesToDelete.build();
        _$failedField = 'foldersToDelete';
        foldersToDelete.build();
        _$failedField = 'buildInputs';
        buildInputs.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'BuildPlan',
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
