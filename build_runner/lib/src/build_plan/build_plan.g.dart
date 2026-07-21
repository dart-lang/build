// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_plan.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BuildPlan extends BuildPlan {
  @override
  final BuildSpec buildSpec;
  @override
  final PreviousBuild previousBuild;
  @override
  final BuildStepPlan buildStepPlan;
  @override
  final void Function(AssetId)? onDelete;
  @override
  final BuiltList<AssetId> conflictingOutputs;
  @override
  final BuildInputs buildInputs;
  @override
  final BuiltSet<BuildDirectory> buildDirs;
  @override
  final BuiltSet<BuildFilter> buildFilters;

  factory _$BuildPlan([void Function(BuildPlanBuilder)? updates]) =>
      (BuildPlanBuilder()..update(updates))._build();

  _$BuildPlan._({
    required this.buildSpec,
    required this.previousBuild,
    required this.buildStepPlan,
    this.onDelete,
    required this.conflictingOutputs,
    required this.buildInputs,
    required this.buildDirs,
    required this.buildFilters,
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
        previousBuild == other.previousBuild &&
        buildStepPlan == other.buildStepPlan &&
        onDelete == other.onDelete &&
        conflictingOutputs == other.conflictingOutputs &&
        buildInputs == other.buildInputs &&
        buildDirs == other.buildDirs &&
        buildFilters == other.buildFilters;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, buildSpec.hashCode);
    _$hash = $jc(_$hash, previousBuild.hashCode);
    _$hash = $jc(_$hash, buildStepPlan.hashCode);
    _$hash = $jc(_$hash, onDelete.hashCode);
    _$hash = $jc(_$hash, conflictingOutputs.hashCode);
    _$hash = $jc(_$hash, buildInputs.hashCode);
    _$hash = $jc(_$hash, buildDirs.hashCode);
    _$hash = $jc(_$hash, buildFilters.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BuildPlan')
          ..add('buildSpec', buildSpec)
          ..add('previousBuild', previousBuild)
          ..add('buildStepPlan', buildStepPlan)
          ..add('onDelete', onDelete)
          ..add('conflictingOutputs', conflictingOutputs)
          ..add('buildInputs', buildInputs)
          ..add('buildDirs', buildDirs)
          ..add('buildFilters', buildFilters))
        .toString();
  }
}

class BuildPlanBuilder implements Builder<BuildPlan, BuildPlanBuilder> {
  _$BuildPlan? _$v;

  BuildSpecBuilder? _buildSpec;
  BuildSpecBuilder get buildSpec => _$this._buildSpec ??= BuildSpecBuilder();
  set buildSpec(BuildSpecBuilder? buildSpec) => _$this._buildSpec = buildSpec;

  PreviousBuildBuilder? _previousBuild;
  PreviousBuildBuilder get previousBuild =>
      _$this._previousBuild ??= PreviousBuildBuilder();
  set previousBuild(PreviousBuildBuilder? previousBuild) =>
      _$this._previousBuild = previousBuild;

  BuildStepPlanBuilder? _buildStepPlan;
  BuildStepPlanBuilder get buildStepPlan =>
      _$this._buildStepPlan ??= BuildStepPlanBuilder();
  set buildStepPlan(BuildStepPlanBuilder? buildStepPlan) =>
      _$this._buildStepPlan = buildStepPlan;

  ListBuilder<AssetId>? _conflictingOutputs;
  ListBuilder<AssetId> get conflictingOutputs =>
      _$this._conflictingOutputs ??= ListBuilder<AssetId>();
  set conflictingOutputs(ListBuilder<AssetId>? conflictingOutputs) =>
      _$this._conflictingOutputs = conflictingOutputs;

  BuildInputsBuilder? _buildInputs;
  BuildInputsBuilder get buildInputs =>
      _$this._buildInputs ??= BuildInputsBuilder();
  set buildInputs(BuildInputsBuilder? buildInputs) =>
      _$this._buildInputs = buildInputs;

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

  BuildPlanBuilder();

  BuildPlanBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _buildSpec = $v.buildSpec.toBuilder();
      _previousBuild = $v.previousBuild.toBuilder();
      _buildStepPlan = $v.buildStepPlan.toBuilder();
      _onDelete = $v.onDelete;
      _conflictingOutputs = $v.conflictingOutputs.toBuilder();
      _buildInputs = $v.buildInputs.toBuilder();
      _buildDirs = $v.buildDirs.toBuilder();
      _buildFilters = $v.buildFilters.toBuilder();
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
            previousBuild: previousBuild.build(),
            buildStepPlan: buildStepPlan.build(),
            onDelete: onDelete,
            conflictingOutputs: conflictingOutputs.build(),
            buildInputs: buildInputs.build(),
            buildDirs: buildDirs.build(),
            buildFilters: buildFilters.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'buildSpec';
        buildSpec.build();
        _$failedField = 'previousBuild';
        previousBuild.build();
        _$failedField = 'buildStepPlan';
        buildStepPlan.build();

        _$failedField = 'conflictingOutputs';
        conflictingOutputs.build();
        _$failedField = 'buildInputs';
        buildInputs.build();
        _$failedField = 'buildDirs';
        buildDirs.build();
        _$failedField = 'buildFilters';
        buildFilters.build();
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
