// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_plan.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BuildPlan extends BuildPlan {
  @override
  final BuiltSet<AssetId> changedInputs;
  @override
  final BuiltSet<AssetId> outputsToBuild;
  @override
  final BuiltSet<AssetId> outputsToCheck;
  @override
  final BuiltSet<AssetId> globsToEvaluate;

  factory _$BuildPlan([void Function(BuildPlanBuilder)? updates]) =>
      (new BuildPlanBuilder()..update(updates))._build();

  _$BuildPlan._({
    required this.changedInputs,
    required this.outputsToBuild,
    required this.outputsToCheck,
    required this.globsToEvaluate,
  }) : super._() {
    BuiltValueNullFieldError.checkNotNull(
      changedInputs,
      r'BuildPlan',
      'changedInputs',
    );
    BuiltValueNullFieldError.checkNotNull(
      outputsToBuild,
      r'BuildPlan',
      'outputsToBuild',
    );
    BuiltValueNullFieldError.checkNotNull(
      outputsToCheck,
      r'BuildPlan',
      'outputsToCheck',
    );
    BuiltValueNullFieldError.checkNotNull(
      globsToEvaluate,
      r'BuildPlan',
      'globsToEvaluate',
    );
  }

  @override
  BuildPlan rebuild(void Function(BuildPlanBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BuildPlanBuilder toBuilder() => new BuildPlanBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BuildPlan &&
        changedInputs == other.changedInputs &&
        outputsToBuild == other.outputsToBuild &&
        outputsToCheck == other.outputsToCheck &&
        globsToEvaluate == other.globsToEvaluate;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, changedInputs.hashCode);
    _$hash = $jc(_$hash, outputsToBuild.hashCode);
    _$hash = $jc(_$hash, outputsToCheck.hashCode);
    _$hash = $jc(_$hash, globsToEvaluate.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BuildPlan')
          ..add('changedInputs', changedInputs)
          ..add('outputsToBuild', outputsToBuild)
          ..add('outputsToCheck', outputsToCheck)
          ..add('globsToEvaluate', globsToEvaluate))
        .toString();
  }
}

class BuildPlanBuilder implements Builder<BuildPlan, BuildPlanBuilder> {
  _$BuildPlan? _$v;

  SetBuilder<AssetId>? _changedInputs;
  SetBuilder<AssetId> get changedInputs =>
      _$this._changedInputs ??= new SetBuilder<AssetId>();
  set changedInputs(SetBuilder<AssetId>? changedInputs) =>
      _$this._changedInputs = changedInputs;

  SetBuilder<AssetId>? _outputsToBuild;
  SetBuilder<AssetId> get outputsToBuild =>
      _$this._outputsToBuild ??= new SetBuilder<AssetId>();
  set outputsToBuild(SetBuilder<AssetId>? outputsToBuild) =>
      _$this._outputsToBuild = outputsToBuild;

  SetBuilder<AssetId>? _outputsToCheck;
  SetBuilder<AssetId> get outputsToCheck =>
      _$this._outputsToCheck ??= new SetBuilder<AssetId>();
  set outputsToCheck(SetBuilder<AssetId>? outputsToCheck) =>
      _$this._outputsToCheck = outputsToCheck;

  SetBuilder<AssetId>? _globsToEvaluate;
  SetBuilder<AssetId> get globsToEvaluate =>
      _$this._globsToEvaluate ??= new SetBuilder<AssetId>();
  set globsToEvaluate(SetBuilder<AssetId>? globsToEvaluate) =>
      _$this._globsToEvaluate = globsToEvaluate;

  BuildPlanBuilder();

  BuildPlanBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _changedInputs = $v.changedInputs.toBuilder();
      _outputsToBuild = $v.outputsToBuild.toBuilder();
      _outputsToCheck = $v.outputsToCheck.toBuilder();
      _globsToEvaluate = $v.globsToEvaluate.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BuildPlan other) {
    ArgumentError.checkNotNull(other, 'other');
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
          new _$BuildPlan._(
            changedInputs: changedInputs.build(),
            outputsToBuild: outputsToBuild.build(),
            outputsToCheck: outputsToCheck.build(),
            globsToEvaluate: globsToEvaluate.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'changedInputs';
        changedInputs.build();
        _$failedField = 'outputsToBuild';
        outputsToBuild.build();
        _$failedField = 'outputsToCheck';
        outputsToCheck.build();
        _$failedField = 'globsToEvaluate';
        globsToEvaluate.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
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
