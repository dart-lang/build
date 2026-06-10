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
  final BuildStepPlan buildStepPlan;
  @override
  final PreviousBuild previousBuild;
  @override
  final BuiltList<AssetId> conflictingOutputs;
  @override
  final BuildInputs buildInputs;

  factory _$BuildPlan([void Function(BuildPlanBuilder)? updates]) =>
      (BuildPlanBuilder()..update(updates))._build();

  _$BuildPlan._({
    required this.buildSpec,
    required this.buildDirs,
    required this.buildFilters,
    required this.readerWriter,
    required this.buildStepPlan,
    required this.previousBuild,
    required this.conflictingOutputs,
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
        buildStepPlan == other.buildStepPlan &&
        previousBuild == other.previousBuild &&
        conflictingOutputs == other.conflictingOutputs &&
        buildInputs == other.buildInputs;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, buildSpec.hashCode);
    _$hash = $jc(_$hash, buildDirs.hashCode);
    _$hash = $jc(_$hash, buildFilters.hashCode);
    _$hash = $jc(_$hash, readerWriter.hashCode);
    _$hash = $jc(_$hash, buildStepPlan.hashCode);
    _$hash = $jc(_$hash, previousBuild.hashCode);
    _$hash = $jc(_$hash, conflictingOutputs.hashCode);
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
          ..add('buildStepPlan', buildStepPlan)
          ..add('previousBuild', previousBuild)
          ..add('conflictingOutputs', conflictingOutputs)
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

  BuildStepPlanBuilder? _buildStepPlan;
  BuildStepPlanBuilder get buildStepPlan =>
      _$this._buildStepPlan ??= BuildStepPlanBuilder();
  set buildStepPlan(BuildStepPlanBuilder? buildStepPlan) =>
      _$this._buildStepPlan = buildStepPlan;

  PreviousBuildBuilder? _previousBuild;
  PreviousBuildBuilder get previousBuild =>
      _$this._previousBuild ??= PreviousBuildBuilder();
  set previousBuild(PreviousBuildBuilder? previousBuild) =>
      _$this._previousBuild = previousBuild;

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

  BuildPlanBuilder();

  BuildPlanBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _buildSpec = $v.buildSpec.toBuilder();
      _buildDirs = $v.buildDirs.toBuilder();
      _buildFilters = $v.buildFilters.toBuilder();
      _readerWriter = $v.readerWriter;
      _buildStepPlan = $v.buildStepPlan.toBuilder();
      _previousBuild = $v.previousBuild.toBuilder();
      _conflictingOutputs = $v.conflictingOutputs.toBuilder();
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
            buildStepPlan: buildStepPlan.build(),
            previousBuild: previousBuild.build(),
            conflictingOutputs: conflictingOutputs.build(),
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

        _$failedField = 'buildStepPlan';
        buildStepPlan.build();
        _$failedField = 'previousBuild';
        previousBuild.build();
        _$failedField = 'conflictingOutputs';
        conflictingOutputs.build();
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
