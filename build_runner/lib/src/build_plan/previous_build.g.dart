// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'previous_build.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PreviousBuild extends PreviousBuild {
  @override
  final BuildState? buildState;
  @override
  final PhasedAssetDeps? phasedAssetDeps;
  @override
  final bool triggersChanged;
  @override
  final BuiltList<bool> phaseOptionsChangedList;
  @override
  final BuiltList<bool> postBuildOptionsChangedList;
  @override
  final BuiltList<AssetId> incompatibleBuildOutputsToDelete;

  factory _$PreviousBuild([void Function(PreviousBuildBuilder)? updates]) =>
      (PreviousBuildBuilder()..update(updates))._build();

  _$PreviousBuild._({
    this.buildState,
    this.phasedAssetDeps,
    required this.triggersChanged,
    required this.phaseOptionsChangedList,
    required this.postBuildOptionsChangedList,
    required this.incompatibleBuildOutputsToDelete,
  }) : super._();
  @override
  PreviousBuild rebuild(void Function(PreviousBuildBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PreviousBuildBuilder toBuilder() => PreviousBuildBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PreviousBuild &&
        buildState == other.buildState &&
        phasedAssetDeps == other.phasedAssetDeps &&
        triggersChanged == other.triggersChanged &&
        phaseOptionsChangedList == other.phaseOptionsChangedList &&
        postBuildOptionsChangedList == other.postBuildOptionsChangedList &&
        incompatibleBuildOutputsToDelete ==
            other.incompatibleBuildOutputsToDelete;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, buildState.hashCode);
    _$hash = $jc(_$hash, phasedAssetDeps.hashCode);
    _$hash = $jc(_$hash, triggersChanged.hashCode);
    _$hash = $jc(_$hash, phaseOptionsChangedList.hashCode);
    _$hash = $jc(_$hash, postBuildOptionsChangedList.hashCode);
    _$hash = $jc(_$hash, incompatibleBuildOutputsToDelete.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PreviousBuild')
          ..add('buildState', buildState)
          ..add('phasedAssetDeps', phasedAssetDeps)
          ..add('triggersChanged', triggersChanged)
          ..add('phaseOptionsChangedList', phaseOptionsChangedList)
          ..add('postBuildOptionsChangedList', postBuildOptionsChangedList)
          ..add(
            'incompatibleBuildOutputsToDelete',
            incompatibleBuildOutputsToDelete,
          ))
        .toString();
  }
}

class PreviousBuildBuilder
    implements Builder<PreviousBuild, PreviousBuildBuilder> {
  _$PreviousBuild? _$v;

  BuildState? _buildState;
  BuildState? get buildState => _$this._buildState;
  set buildState(BuildState? buildState) => _$this._buildState = buildState;

  PhasedAssetDepsBuilder? _phasedAssetDeps;
  PhasedAssetDepsBuilder get phasedAssetDeps =>
      _$this._phasedAssetDeps ??= PhasedAssetDepsBuilder();
  set phasedAssetDeps(PhasedAssetDepsBuilder? phasedAssetDeps) =>
      _$this._phasedAssetDeps = phasedAssetDeps;

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

  ListBuilder<AssetId>? _incompatibleBuildOutputsToDelete;
  ListBuilder<AssetId> get incompatibleBuildOutputsToDelete =>
      _$this._incompatibleBuildOutputsToDelete ??= ListBuilder<AssetId>();
  set incompatibleBuildOutputsToDelete(
    ListBuilder<AssetId>? incompatibleBuildOutputsToDelete,
  ) => _$this._incompatibleBuildOutputsToDelete =
      incompatibleBuildOutputsToDelete;

  PreviousBuildBuilder();

  PreviousBuildBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _buildState = $v.buildState;
      _phasedAssetDeps = $v.phasedAssetDeps?.toBuilder();
      _triggersChanged = $v.triggersChanged;
      _phaseOptionsChangedList = $v.phaseOptionsChangedList.toBuilder();
      _postBuildOptionsChangedList = $v.postBuildOptionsChangedList.toBuilder();
      _incompatibleBuildOutputsToDelete = $v.incompatibleBuildOutputsToDelete
          .toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PreviousBuild other) {
    _$v = other as _$PreviousBuild;
  }

  @override
  void update(void Function(PreviousBuildBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PreviousBuild build() => _build();

  _$PreviousBuild _build() {
    _$PreviousBuild _$result;
    try {
      _$result =
          _$v ??
          _$PreviousBuild._(
            buildState: buildState,
            phasedAssetDeps: _phasedAssetDeps?.build(),
            triggersChanged: BuiltValueNullFieldError.checkNotNull(
              triggersChanged,
              r'PreviousBuild',
              'triggersChanged',
            ),
            phaseOptionsChangedList: phaseOptionsChangedList.build(),
            postBuildOptionsChangedList: postBuildOptionsChangedList.build(),
            incompatibleBuildOutputsToDelete: incompatibleBuildOutputsToDelete
                .build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'phasedAssetDeps';
        _phasedAssetDeps?.build();

        _$failedField = 'phaseOptionsChangedList';
        phaseOptionsChangedList.build();
        _$failedField = 'postBuildOptionsChangedList';
        postBuildOptionsChangedList.build();
        _$failedField = 'incompatibleBuildOutputsToDelete';
        incompatibleBuildOutputsToDelete.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PreviousBuild',
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
