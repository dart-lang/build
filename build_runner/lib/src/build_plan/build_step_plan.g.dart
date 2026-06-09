// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_step_plan.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BuildStepPlan extends BuildStepPlan {
  @override
  final BuildPhases buildPhases;
  @override
  final BuiltMap<AssetId, BuildStepId> buildStepsByDeclaredOutput;
  @override
  final BuiltListMultimap<AssetId, AssetId> declaredOutputsByPrimaryInput;
  @override
  final BuiltList<BuiltList<BuildStepId>> buildStepsByPhase;

  factory _$BuildStepPlan([void Function(BuildStepPlanBuilder)? updates]) =>
      (BuildStepPlanBuilder()..update(updates))._build();

  _$BuildStepPlan._({
    required this.buildPhases,
    required this.buildStepsByDeclaredOutput,
    required this.declaredOutputsByPrimaryInput,
    required this.buildStepsByPhase,
  }) : super._();
  @override
  BuildStepPlan rebuild(void Function(BuildStepPlanBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BuildStepPlanBuilder toBuilder() => BuildStepPlanBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BuildStepPlan &&
        buildPhases == other.buildPhases &&
        buildStepsByDeclaredOutput == other.buildStepsByDeclaredOutput &&
        declaredOutputsByPrimaryInput == other.declaredOutputsByPrimaryInput &&
        buildStepsByPhase == other.buildStepsByPhase;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, buildPhases.hashCode);
    _$hash = $jc(_$hash, buildStepsByDeclaredOutput.hashCode);
    _$hash = $jc(_$hash, declaredOutputsByPrimaryInput.hashCode);
    _$hash = $jc(_$hash, buildStepsByPhase.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BuildStepPlan')
          ..add('buildPhases', buildPhases)
          ..add('buildStepsByDeclaredOutput', buildStepsByDeclaredOutput)
          ..add('declaredOutputsByPrimaryInput', declaredOutputsByPrimaryInput)
          ..add('buildStepsByPhase', buildStepsByPhase))
        .toString();
  }
}

class BuildStepPlanBuilder
    implements Builder<BuildStepPlan, BuildStepPlanBuilder> {
  _$BuildStepPlan? _$v;

  BuildPhases? _buildPhases;
  BuildPhases? get buildPhases => _$this._buildPhases;
  set buildPhases(BuildPhases? buildPhases) =>
      _$this._buildPhases = buildPhases;

  MapBuilder<AssetId, BuildStepId>? _buildStepsByDeclaredOutput;
  MapBuilder<AssetId, BuildStepId> get buildStepsByDeclaredOutput =>
      _$this._buildStepsByDeclaredOutput ??= MapBuilder<AssetId, BuildStepId>();
  set buildStepsByDeclaredOutput(
    MapBuilder<AssetId, BuildStepId>? buildStepsByDeclaredOutput,
  ) => _$this._buildStepsByDeclaredOutput = buildStepsByDeclaredOutput;

  ListMultimapBuilder<AssetId, AssetId>? _declaredOutputsByPrimaryInput;
  ListMultimapBuilder<AssetId, AssetId> get declaredOutputsByPrimaryInput =>
      _$this._declaredOutputsByPrimaryInput ??=
          ListMultimapBuilder<AssetId, AssetId>();
  set declaredOutputsByPrimaryInput(
    ListMultimapBuilder<AssetId, AssetId>? declaredOutputsByPrimaryInput,
  ) => _$this._declaredOutputsByPrimaryInput = declaredOutputsByPrimaryInput;

  ListBuilder<BuiltList<BuildStepId>>? _buildStepsByPhase;
  ListBuilder<BuiltList<BuildStepId>> get buildStepsByPhase =>
      _$this._buildStepsByPhase ??= ListBuilder<BuiltList<BuildStepId>>();
  set buildStepsByPhase(
    ListBuilder<BuiltList<BuildStepId>>? buildStepsByPhase,
  ) => _$this._buildStepsByPhase = buildStepsByPhase;

  BuildStepPlanBuilder();

  BuildStepPlanBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _buildPhases = $v.buildPhases;
      _buildStepsByDeclaredOutput = $v.buildStepsByDeclaredOutput.toBuilder();
      _declaredOutputsByPrimaryInput = $v.declaredOutputsByPrimaryInput
          .toBuilder();
      _buildStepsByPhase = $v.buildStepsByPhase.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BuildStepPlan other) {
    _$v = other as _$BuildStepPlan;
  }

  @override
  void update(void Function(BuildStepPlanBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BuildStepPlan build() => _build();

  _$BuildStepPlan _build() {
    _$BuildStepPlan _$result;
    try {
      _$result =
          _$v ??
          _$BuildStepPlan._(
            buildPhases: BuiltValueNullFieldError.checkNotNull(
              buildPhases,
              r'BuildStepPlan',
              'buildPhases',
            ),
            buildStepsByDeclaredOutput: buildStepsByDeclaredOutput.build(),
            declaredOutputsByPrimaryInput: declaredOutputsByPrimaryInput
                .build(),
            buildStepsByPhase: buildStepsByPhase.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'buildStepsByDeclaredOutput';
        buildStepsByDeclaredOutput.build();
        _$failedField = 'declaredOutputsByPrimaryInput';
        declaredOutputsByPrimaryInput.build();
        _$failedField = 'buildStepsByPhase';
        buildStepsByPhase.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'BuildStepPlan',
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
