// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const NodeType _$builderOptions = const NodeType._('builderOptions');
const NodeType _$generated = const NodeType._('generated');
const NodeType _$glob = const NodeType._('glob');
const NodeType _$internal = const NodeType._('internal');
const NodeType _$placeholder = const NodeType._('placeholder');
const NodeType _$postProcessAnchor = const NodeType._('postProcessAnchor');
const NodeType _$source = const NodeType._('source');
const NodeType _$syntheticSource = const NodeType._('syntheticSource');

NodeType _$nodeTypeValueOf(String name) {
  switch (name) {
    case 'builderOptions':
      return _$builderOptions;
    case 'generated':
      return _$generated;
    case 'glob':
      return _$glob;
    case 'internal':
      return _$internal;
    case 'placeholder':
      return _$placeholder;
    case 'postProcessAnchor':
      return _$postProcessAnchor;
    case 'source':
      return _$source;
    case 'syntheticSource':
      return _$syntheticSource;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<NodeType> _$nodeTypeValues =
    new BuiltSet<NodeType>(const <NodeType>[
      _$builderOptions,
      _$generated,
      _$glob,
      _$internal,
      _$placeholder,
      _$postProcessAnchor,
      _$source,
      _$syntheticSource,
    ]);

const PendingBuildAction _$none = const PendingBuildAction._('none');
const PendingBuildAction _$buildIfInputsChanged = const PendingBuildAction._(
  'buildIfInputsChanged',
);
const PendingBuildAction _$build = const PendingBuildAction._('build');

PendingBuildAction _$pendingBuildActionValueOf(String name) {
  switch (name) {
    case 'none':
      return _$none;
    case 'buildIfInputsChanged':
      return _$buildIfInputsChanged;
    case 'build':
      return _$build;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<PendingBuildAction> _$pendingBuildActionValues =
    new BuiltSet<PendingBuildAction>(const <PendingBuildAction>[
      _$none,
      _$buildIfInputsChanged,
      _$build,
    ]);

class _$GeneratedNodeConfiguration extends GeneratedNodeConfiguration {
  @override
  final AssetId primaryInput;
  @override
  final AssetId builderOptionsId;
  @override
  final int phaseNumber;
  @override
  final bool isHidden;

  factory _$GeneratedNodeConfiguration([
    void Function(GeneratedNodeConfigurationBuilder)? updates,
  ]) => (new GeneratedNodeConfigurationBuilder()..update(updates))._build();

  _$GeneratedNodeConfiguration._({
    required this.primaryInput,
    required this.builderOptionsId,
    required this.phaseNumber,
    required this.isHidden,
  }) : super._() {
    BuiltValueNullFieldError.checkNotNull(
      primaryInput,
      r'GeneratedNodeConfiguration',
      'primaryInput',
    );
    BuiltValueNullFieldError.checkNotNull(
      builderOptionsId,
      r'GeneratedNodeConfiguration',
      'builderOptionsId',
    );
    BuiltValueNullFieldError.checkNotNull(
      phaseNumber,
      r'GeneratedNodeConfiguration',
      'phaseNumber',
    );
    BuiltValueNullFieldError.checkNotNull(
      isHidden,
      r'GeneratedNodeConfiguration',
      'isHidden',
    );
  }

  @override
  GeneratedNodeConfiguration rebuild(
    void Function(GeneratedNodeConfigurationBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GeneratedNodeConfigurationBuilder toBuilder() =>
      new GeneratedNodeConfigurationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GeneratedNodeConfiguration &&
        primaryInput == other.primaryInput &&
        builderOptionsId == other.builderOptionsId &&
        phaseNumber == other.phaseNumber &&
        isHidden == other.isHidden;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, primaryInput.hashCode);
    _$hash = $jc(_$hash, builderOptionsId.hashCode);
    _$hash = $jc(_$hash, phaseNumber.hashCode);
    _$hash = $jc(_$hash, isHidden.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GeneratedNodeConfiguration')
          ..add('primaryInput', primaryInput)
          ..add('builderOptionsId', builderOptionsId)
          ..add('phaseNumber', phaseNumber)
          ..add('isHidden', isHidden))
        .toString();
  }
}

class GeneratedNodeConfigurationBuilder
    implements
        Builder<GeneratedNodeConfiguration, GeneratedNodeConfigurationBuilder> {
  _$GeneratedNodeConfiguration? _$v;

  AssetId? _primaryInput;
  AssetId? get primaryInput => _$this._primaryInput;
  set primaryInput(AssetId? primaryInput) =>
      _$this._primaryInput = primaryInput;

  AssetId? _builderOptionsId;
  AssetId? get builderOptionsId => _$this._builderOptionsId;
  set builderOptionsId(AssetId? builderOptionsId) =>
      _$this._builderOptionsId = builderOptionsId;

  int? _phaseNumber;
  int? get phaseNumber => _$this._phaseNumber;
  set phaseNumber(int? phaseNumber) => _$this._phaseNumber = phaseNumber;

  bool? _isHidden;
  bool? get isHidden => _$this._isHidden;
  set isHidden(bool? isHidden) => _$this._isHidden = isHidden;

  GeneratedNodeConfigurationBuilder();

  GeneratedNodeConfigurationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _primaryInput = $v.primaryInput;
      _builderOptionsId = $v.builderOptionsId;
      _phaseNumber = $v.phaseNumber;
      _isHidden = $v.isHidden;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GeneratedNodeConfiguration other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$GeneratedNodeConfiguration;
  }

  @override
  void update(void Function(GeneratedNodeConfigurationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GeneratedNodeConfiguration build() => _build();

  _$GeneratedNodeConfiguration _build() {
    final _$result =
        _$v ??
        new _$GeneratedNodeConfiguration._(
          primaryInput: BuiltValueNullFieldError.checkNotNull(
            primaryInput,
            r'GeneratedNodeConfiguration',
            'primaryInput',
          ),
          builderOptionsId: BuiltValueNullFieldError.checkNotNull(
            builderOptionsId,
            r'GeneratedNodeConfiguration',
            'builderOptionsId',
          ),
          phaseNumber: BuiltValueNullFieldError.checkNotNull(
            phaseNumber,
            r'GeneratedNodeConfiguration',
            'phaseNumber',
          ),
          isHidden: BuiltValueNullFieldError.checkNotNull(
            isHidden,
            r'GeneratedNodeConfiguration',
            'isHidden',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

class _$GlobNodeConfiguration extends GlobNodeConfiguration {
  @override
  final Glob glob;
  @override
  final int phaseNumber;

  factory _$GlobNodeConfiguration([
    void Function(GlobNodeConfigurationBuilder)? updates,
  ]) => (new GlobNodeConfigurationBuilder()..update(updates))._build();

  _$GlobNodeConfiguration._({required this.glob, required this.phaseNumber})
    : super._() {
    BuiltValueNullFieldError.checkNotNull(
      glob,
      r'GlobNodeConfiguration',
      'glob',
    );
    BuiltValueNullFieldError.checkNotNull(
      phaseNumber,
      r'GlobNodeConfiguration',
      'phaseNumber',
    );
  }

  @override
  GlobNodeConfiguration rebuild(
    void Function(GlobNodeConfigurationBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GlobNodeConfigurationBuilder toBuilder() =>
      new GlobNodeConfigurationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GlobNodeConfiguration &&
        glob == other.glob &&
        phaseNumber == other.phaseNumber;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, glob.hashCode);
    _$hash = $jc(_$hash, phaseNumber.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GlobNodeConfiguration')
          ..add('glob', glob)
          ..add('phaseNumber', phaseNumber))
        .toString();
  }
}

class GlobNodeConfigurationBuilder
    implements Builder<GlobNodeConfiguration, GlobNodeConfigurationBuilder> {
  _$GlobNodeConfiguration? _$v;

  Glob? _glob;
  Glob? get glob => _$this._glob;
  set glob(Glob? glob) => _$this._glob = glob;

  int? _phaseNumber;
  int? get phaseNumber => _$this._phaseNumber;
  set phaseNumber(int? phaseNumber) => _$this._phaseNumber = phaseNumber;

  GlobNodeConfigurationBuilder();

  GlobNodeConfigurationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _glob = $v.glob;
      _phaseNumber = $v.phaseNumber;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GlobNodeConfiguration other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$GlobNodeConfiguration;
  }

  @override
  void update(void Function(GlobNodeConfigurationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GlobNodeConfiguration build() => _build();

  _$GlobNodeConfiguration _build() {
    final _$result =
        _$v ??
        new _$GlobNodeConfiguration._(
          glob: BuiltValueNullFieldError.checkNotNull(
            glob,
            r'GlobNodeConfiguration',
            'glob',
          ),
          phaseNumber: BuiltValueNullFieldError.checkNotNull(
            phaseNumber,
            r'GlobNodeConfiguration',
            'phaseNumber',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

class _$PostProcessAnchorNodeConfiguration
    extends PostProcessAnchorNodeConfiguration {
  @override
  final int actionNumber;
  @override
  final AssetId builderOptionsId;
  @override
  final AssetId primaryInput;

  factory _$PostProcessAnchorNodeConfiguration([
    void Function(PostProcessAnchorNodeConfigurationBuilder)? updates,
  ]) =>
      (new PostProcessAnchorNodeConfigurationBuilder()..update(updates))
          ._build();

  _$PostProcessAnchorNodeConfiguration._({
    required this.actionNumber,
    required this.builderOptionsId,
    required this.primaryInput,
  }) : super._() {
    BuiltValueNullFieldError.checkNotNull(
      actionNumber,
      r'PostProcessAnchorNodeConfiguration',
      'actionNumber',
    );
    BuiltValueNullFieldError.checkNotNull(
      builderOptionsId,
      r'PostProcessAnchorNodeConfiguration',
      'builderOptionsId',
    );
    BuiltValueNullFieldError.checkNotNull(
      primaryInput,
      r'PostProcessAnchorNodeConfiguration',
      'primaryInput',
    );
  }

  @override
  PostProcessAnchorNodeConfiguration rebuild(
    void Function(PostProcessAnchorNodeConfigurationBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PostProcessAnchorNodeConfigurationBuilder toBuilder() =>
      new PostProcessAnchorNodeConfigurationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PostProcessAnchorNodeConfiguration &&
        actionNumber == other.actionNumber &&
        builderOptionsId == other.builderOptionsId &&
        primaryInput == other.primaryInput;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, actionNumber.hashCode);
    _$hash = $jc(_$hash, builderOptionsId.hashCode);
    _$hash = $jc(_$hash, primaryInput.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PostProcessAnchorNodeConfiguration')
          ..add('actionNumber', actionNumber)
          ..add('builderOptionsId', builderOptionsId)
          ..add('primaryInput', primaryInput))
        .toString();
  }
}

class PostProcessAnchorNodeConfigurationBuilder
    implements
        Builder<
          PostProcessAnchorNodeConfiguration,
          PostProcessAnchorNodeConfigurationBuilder
        > {
  _$PostProcessAnchorNodeConfiguration? _$v;

  int? _actionNumber;
  int? get actionNumber => _$this._actionNumber;
  set actionNumber(int? actionNumber) => _$this._actionNumber = actionNumber;

  AssetId? _builderOptionsId;
  AssetId? get builderOptionsId => _$this._builderOptionsId;
  set builderOptionsId(AssetId? builderOptionsId) =>
      _$this._builderOptionsId = builderOptionsId;

  AssetId? _primaryInput;
  AssetId? get primaryInput => _$this._primaryInput;
  set primaryInput(AssetId? primaryInput) =>
      _$this._primaryInput = primaryInput;

  PostProcessAnchorNodeConfigurationBuilder();

  PostProcessAnchorNodeConfigurationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _actionNumber = $v.actionNumber;
      _builderOptionsId = $v.builderOptionsId;
      _primaryInput = $v.primaryInput;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PostProcessAnchorNodeConfiguration other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$PostProcessAnchorNodeConfiguration;
  }

  @override
  void update(
    void Function(PostProcessAnchorNodeConfigurationBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  PostProcessAnchorNodeConfiguration build() => _build();

  _$PostProcessAnchorNodeConfiguration _build() {
    final _$result =
        _$v ??
        new _$PostProcessAnchorNodeConfiguration._(
          actionNumber: BuiltValueNullFieldError.checkNotNull(
            actionNumber,
            r'PostProcessAnchorNodeConfiguration',
            'actionNumber',
          ),
          builderOptionsId: BuiltValueNullFieldError.checkNotNull(
            builderOptionsId,
            r'PostProcessAnchorNodeConfiguration',
            'builderOptionsId',
          ),
          primaryInput: BuiltValueNullFieldError.checkNotNull(
            primaryInput,
            r'PostProcessAnchorNodeConfiguration',
            'primaryInput',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
