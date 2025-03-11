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
const NodeType _$missingSource = const NodeType._('missingSource');

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
    case 'missingSource':
      return _$missingSource;
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
      _$missingSource,
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

class _$AssetNode extends AssetNode {
  @override
  final AssetId id;
  @override
  final NodeType type;
  @override
  final GeneratedNodeConfiguration? generatedNodeConfiguration;
  @override
  final GeneratedNodeState? generatedNodeState;
  @override
  final GlobNodeConfiguration? globNodeConfiguration;
  @override
  final GlobNodeState? globNodeState;
  @override
  final PostProcessAnchorNodeConfiguration? postProcessAnchorNodeConfiguration;
  @override
  final PostProcessAnchorNodeState? postProcessAnchorNodeState;
  @override
  final BuiltSet<AssetId> primaryOutputs;
  @override
  final BuiltSet<AssetId> outputs;
  @override
  final BuiltSet<AssetId> anchorOutputs;
  @override
  final Digest? lastKnownDigest;
  @override
  final BuiltSet<AssetId> deletedBy;

  factory _$AssetNode([void Function(AssetNodeBuilder)? updates]) =>
      (new AssetNodeBuilder()..update(updates))._build();

  _$AssetNode._({
    required this.id,
    required this.type,
    this.generatedNodeConfiguration,
    this.generatedNodeState,
    this.globNodeConfiguration,
    this.globNodeState,
    this.postProcessAnchorNodeConfiguration,
    this.postProcessAnchorNodeState,
    required this.primaryOutputs,
    required this.outputs,
    required this.anchorOutputs,
    this.lastKnownDigest,
    required this.deletedBy,
  }) : super._() {
    BuiltValueNullFieldError.checkNotNull(id, r'AssetNode', 'id');
    BuiltValueNullFieldError.checkNotNull(type, r'AssetNode', 'type');
    BuiltValueNullFieldError.checkNotNull(
      primaryOutputs,
      r'AssetNode',
      'primaryOutputs',
    );
    BuiltValueNullFieldError.checkNotNull(outputs, r'AssetNode', 'outputs');
    BuiltValueNullFieldError.checkNotNull(
      anchorOutputs,
      r'AssetNode',
      'anchorOutputs',
    );
    BuiltValueNullFieldError.checkNotNull(deletedBy, r'AssetNode', 'deletedBy');
  }

  @override
  AssetNode rebuild(void Function(AssetNodeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AssetNodeBuilder toBuilder() => new AssetNodeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AssetNode &&
        id == other.id &&
        type == other.type &&
        generatedNodeConfiguration == other.generatedNodeConfiguration &&
        generatedNodeState == other.generatedNodeState &&
        globNodeConfiguration == other.globNodeConfiguration &&
        globNodeState == other.globNodeState &&
        postProcessAnchorNodeConfiguration ==
            other.postProcessAnchorNodeConfiguration &&
        postProcessAnchorNodeState == other.postProcessAnchorNodeState &&
        primaryOutputs == other.primaryOutputs &&
        outputs == other.outputs &&
        anchorOutputs == other.anchorOutputs &&
        lastKnownDigest == other.lastKnownDigest &&
        deletedBy == other.deletedBy;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, generatedNodeConfiguration.hashCode);
    _$hash = $jc(_$hash, generatedNodeState.hashCode);
    _$hash = $jc(_$hash, globNodeConfiguration.hashCode);
    _$hash = $jc(_$hash, globNodeState.hashCode);
    _$hash = $jc(_$hash, postProcessAnchorNodeConfiguration.hashCode);
    _$hash = $jc(_$hash, postProcessAnchorNodeState.hashCode);
    _$hash = $jc(_$hash, primaryOutputs.hashCode);
    _$hash = $jc(_$hash, outputs.hashCode);
    _$hash = $jc(_$hash, anchorOutputs.hashCode);
    _$hash = $jc(_$hash, lastKnownDigest.hashCode);
    _$hash = $jc(_$hash, deletedBy.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AssetNode')
          ..add('id', id)
          ..add('type', type)
          ..add('generatedNodeConfiguration', generatedNodeConfiguration)
          ..add('generatedNodeState', generatedNodeState)
          ..add('globNodeConfiguration', globNodeConfiguration)
          ..add('globNodeState', globNodeState)
          ..add(
            'postProcessAnchorNodeConfiguration',
            postProcessAnchorNodeConfiguration,
          )
          ..add('postProcessAnchorNodeState', postProcessAnchorNodeState)
          ..add('primaryOutputs', primaryOutputs)
          ..add('outputs', outputs)
          ..add('anchorOutputs', anchorOutputs)
          ..add('lastKnownDigest', lastKnownDigest)
          ..add('deletedBy', deletedBy))
        .toString();
  }
}

class AssetNodeBuilder implements Builder<AssetNode, AssetNodeBuilder> {
  _$AssetNode? _$v;

  AssetId? _id;
  AssetId? get id => _$this._id;
  set id(AssetId? id) => _$this._id = id;

  NodeType? _type;
  NodeType? get type => _$this._type;
  set type(NodeType? type) => _$this._type = type;

  GeneratedNodeConfigurationBuilder? _generatedNodeConfiguration;
  GeneratedNodeConfigurationBuilder get generatedNodeConfiguration =>
      _$this._generatedNodeConfiguration ??=
          new GeneratedNodeConfigurationBuilder();
  set generatedNodeConfiguration(
    GeneratedNodeConfigurationBuilder? generatedNodeConfiguration,
  ) => _$this._generatedNodeConfiguration = generatedNodeConfiguration;

  GeneratedNodeStateBuilder? _generatedNodeState;
  GeneratedNodeStateBuilder get generatedNodeState =>
      _$this._generatedNodeState ??= new GeneratedNodeStateBuilder();
  set generatedNodeState(GeneratedNodeStateBuilder? generatedNodeState) =>
      _$this._generatedNodeState = generatedNodeState;

  GlobNodeConfigurationBuilder? _globNodeConfiguration;
  GlobNodeConfigurationBuilder get globNodeConfiguration =>
      _$this._globNodeConfiguration ??= new GlobNodeConfigurationBuilder();
  set globNodeConfiguration(
    GlobNodeConfigurationBuilder? globNodeConfiguration,
  ) => _$this._globNodeConfiguration = globNodeConfiguration;

  GlobNodeStateBuilder? _globNodeState;
  GlobNodeStateBuilder get globNodeState =>
      _$this._globNodeState ??= new GlobNodeStateBuilder();
  set globNodeState(GlobNodeStateBuilder? globNodeState) =>
      _$this._globNodeState = globNodeState;

  PostProcessAnchorNodeConfigurationBuilder?
  _postProcessAnchorNodeConfiguration;
  PostProcessAnchorNodeConfigurationBuilder
  get postProcessAnchorNodeConfiguration =>
      _$this._postProcessAnchorNodeConfiguration ??=
          new PostProcessAnchorNodeConfigurationBuilder();
  set postProcessAnchorNodeConfiguration(
    PostProcessAnchorNodeConfigurationBuilder?
    postProcessAnchorNodeConfiguration,
  ) =>
      _$this._postProcessAnchorNodeConfiguration =
          postProcessAnchorNodeConfiguration;

  PostProcessAnchorNodeStateBuilder? _postProcessAnchorNodeState;
  PostProcessAnchorNodeStateBuilder get postProcessAnchorNodeState =>
      _$this._postProcessAnchorNodeState ??=
          new PostProcessAnchorNodeStateBuilder();
  set postProcessAnchorNodeState(
    PostProcessAnchorNodeStateBuilder? postProcessAnchorNodeState,
  ) => _$this._postProcessAnchorNodeState = postProcessAnchorNodeState;

  SetBuilder<AssetId>? _primaryOutputs;
  SetBuilder<AssetId> get primaryOutputs =>
      _$this._primaryOutputs ??= new SetBuilder<AssetId>();
  set primaryOutputs(SetBuilder<AssetId>? primaryOutputs) =>
      _$this._primaryOutputs = primaryOutputs;

  SetBuilder<AssetId>? _outputs;
  SetBuilder<AssetId> get outputs =>
      _$this._outputs ??= new SetBuilder<AssetId>();
  set outputs(SetBuilder<AssetId>? outputs) => _$this._outputs = outputs;

  SetBuilder<AssetId>? _anchorOutputs;
  SetBuilder<AssetId> get anchorOutputs =>
      _$this._anchorOutputs ??= new SetBuilder<AssetId>();
  set anchorOutputs(SetBuilder<AssetId>? anchorOutputs) =>
      _$this._anchorOutputs = anchorOutputs;

  Digest? _lastKnownDigest;
  Digest? get lastKnownDigest => _$this._lastKnownDigest;
  set lastKnownDigest(Digest? lastKnownDigest) =>
      _$this._lastKnownDigest = lastKnownDigest;

  SetBuilder<AssetId>? _deletedBy;
  SetBuilder<AssetId> get deletedBy =>
      _$this._deletedBy ??= new SetBuilder<AssetId>();
  set deletedBy(SetBuilder<AssetId>? deletedBy) =>
      _$this._deletedBy = deletedBy;

  AssetNodeBuilder();

  AssetNodeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _type = $v.type;
      _generatedNodeConfiguration = $v.generatedNodeConfiguration?.toBuilder();
      _generatedNodeState = $v.generatedNodeState?.toBuilder();
      _globNodeConfiguration = $v.globNodeConfiguration?.toBuilder();
      _globNodeState = $v.globNodeState?.toBuilder();
      _postProcessAnchorNodeConfiguration =
          $v.postProcessAnchorNodeConfiguration?.toBuilder();
      _postProcessAnchorNodeState = $v.postProcessAnchorNodeState?.toBuilder();
      _primaryOutputs = $v.primaryOutputs.toBuilder();
      _outputs = $v.outputs.toBuilder();
      _anchorOutputs = $v.anchorOutputs.toBuilder();
      _lastKnownDigest = $v.lastKnownDigest;
      _deletedBy = $v.deletedBy.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AssetNode other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$AssetNode;
  }

  @override
  void update(void Function(AssetNodeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AssetNode build() => _build();

  _$AssetNode _build() {
    _$AssetNode _$result;
    try {
      _$result =
          _$v ??
          new _$AssetNode._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'AssetNode', 'id'),
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'AssetNode',
              'type',
            ),
            generatedNodeConfiguration: _generatedNodeConfiguration?.build(),
            generatedNodeState: _generatedNodeState?.build(),
            globNodeConfiguration: _globNodeConfiguration?.build(),
            globNodeState: _globNodeState?.build(),
            postProcessAnchorNodeConfiguration:
                _postProcessAnchorNodeConfiguration?.build(),
            postProcessAnchorNodeState: _postProcessAnchorNodeState?.build(),
            primaryOutputs: primaryOutputs.build(),
            outputs: outputs.build(),
            anchorOutputs: anchorOutputs.build(),
            lastKnownDigest: lastKnownDigest,
            deletedBy: deletedBy.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'generatedNodeConfiguration';
        _generatedNodeConfiguration?.build();
        _$failedField = 'generatedNodeState';
        _generatedNodeState?.build();
        _$failedField = 'globNodeConfiguration';
        _globNodeConfiguration?.build();
        _$failedField = 'globNodeState';
        _globNodeState?.build();
        _$failedField = 'postProcessAnchorNodeConfiguration';
        _postProcessAnchorNodeConfiguration?.build();
        _$failedField = 'postProcessAnchorNodeState';
        _postProcessAnchorNodeState?.build();
        _$failedField = 'primaryOutputs';
        primaryOutputs.build();
        _$failedField = 'outputs';
        outputs.build();
        _$failedField = 'anchorOutputs';
        anchorOutputs.build();

        _$failedField = 'deletedBy';
        deletedBy.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'AssetNode',
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

class _$GeneratedNodeState extends GeneratedNodeState {
  @override
  final BuiltSet<AssetId> inputs;
  @override
  final PendingBuildAction pendingBuildAction;
  @override
  final bool wasOutput;
  @override
  final bool isFailure;
  @override
  final Digest? previousInputsDigest;

  factory _$GeneratedNodeState([
    void Function(GeneratedNodeStateBuilder)? updates,
  ]) => (new GeneratedNodeStateBuilder()..update(updates))._build();

  _$GeneratedNodeState._({
    required this.inputs,
    required this.pendingBuildAction,
    required this.wasOutput,
    required this.isFailure,
    this.previousInputsDigest,
  }) : super._() {
    BuiltValueNullFieldError.checkNotNull(
      inputs,
      r'GeneratedNodeState',
      'inputs',
    );
    BuiltValueNullFieldError.checkNotNull(
      pendingBuildAction,
      r'GeneratedNodeState',
      'pendingBuildAction',
    );
    BuiltValueNullFieldError.checkNotNull(
      wasOutput,
      r'GeneratedNodeState',
      'wasOutput',
    );
    BuiltValueNullFieldError.checkNotNull(
      isFailure,
      r'GeneratedNodeState',
      'isFailure',
    );
  }

  @override
  GeneratedNodeState rebuild(
    void Function(GeneratedNodeStateBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GeneratedNodeStateBuilder toBuilder() =>
      new GeneratedNodeStateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GeneratedNodeState &&
        inputs == other.inputs &&
        pendingBuildAction == other.pendingBuildAction &&
        wasOutput == other.wasOutput &&
        isFailure == other.isFailure &&
        previousInputsDigest == other.previousInputsDigest;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, inputs.hashCode);
    _$hash = $jc(_$hash, pendingBuildAction.hashCode);
    _$hash = $jc(_$hash, wasOutput.hashCode);
    _$hash = $jc(_$hash, isFailure.hashCode);
    _$hash = $jc(_$hash, previousInputsDigest.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GeneratedNodeState')
          ..add('inputs', inputs)
          ..add('pendingBuildAction', pendingBuildAction)
          ..add('wasOutput', wasOutput)
          ..add('isFailure', isFailure)
          ..add('previousInputsDigest', previousInputsDigest))
        .toString();
  }
}

class GeneratedNodeStateBuilder
    implements Builder<GeneratedNodeState, GeneratedNodeStateBuilder> {
  _$GeneratedNodeState? _$v;

  SetBuilder<AssetId>? _inputs;
  SetBuilder<AssetId> get inputs =>
      _$this._inputs ??= new SetBuilder<AssetId>();
  set inputs(SetBuilder<AssetId>? inputs) => _$this._inputs = inputs;

  PendingBuildAction? _pendingBuildAction;
  PendingBuildAction? get pendingBuildAction => _$this._pendingBuildAction;
  set pendingBuildAction(PendingBuildAction? pendingBuildAction) =>
      _$this._pendingBuildAction = pendingBuildAction;

  bool? _wasOutput;
  bool? get wasOutput => _$this._wasOutput;
  set wasOutput(bool? wasOutput) => _$this._wasOutput = wasOutput;

  bool? _isFailure;
  bool? get isFailure => _$this._isFailure;
  set isFailure(bool? isFailure) => _$this._isFailure = isFailure;

  Digest? _previousInputsDigest;
  Digest? get previousInputsDigest => _$this._previousInputsDigest;
  set previousInputsDigest(Digest? previousInputsDigest) =>
      _$this._previousInputsDigest = previousInputsDigest;

  GeneratedNodeStateBuilder();

  GeneratedNodeStateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _inputs = $v.inputs.toBuilder();
      _pendingBuildAction = $v.pendingBuildAction;
      _wasOutput = $v.wasOutput;
      _isFailure = $v.isFailure;
      _previousInputsDigest = $v.previousInputsDigest;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GeneratedNodeState other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$GeneratedNodeState;
  }

  @override
  void update(void Function(GeneratedNodeStateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GeneratedNodeState build() => _build();

  _$GeneratedNodeState _build() {
    _$GeneratedNodeState _$result;
    try {
      _$result =
          _$v ??
          new _$GeneratedNodeState._(
            inputs: inputs.build(),
            pendingBuildAction: BuiltValueNullFieldError.checkNotNull(
              pendingBuildAction,
              r'GeneratedNodeState',
              'pendingBuildAction',
            ),
            wasOutput: BuiltValueNullFieldError.checkNotNull(
              wasOutput,
              r'GeneratedNodeState',
              'wasOutput',
            ),
            isFailure: BuiltValueNullFieldError.checkNotNull(
              isFailure,
              r'GeneratedNodeState',
              'isFailure',
            ),
            previousInputsDigest: previousInputsDigest,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'inputs';
        inputs.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'GeneratedNodeState',
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

class _$GlobNodeState extends GlobNodeState {
  @override
  final BuiltSet<AssetId> inputs;
  @override
  final PendingBuildAction pendingBuildAction;
  @override
  final BuiltList<AssetId> results;

  factory _$GlobNodeState([void Function(GlobNodeStateBuilder)? updates]) =>
      (new GlobNodeStateBuilder()..update(updates))._build();

  _$GlobNodeState._({
    required this.inputs,
    required this.pendingBuildAction,
    required this.results,
  }) : super._() {
    BuiltValueNullFieldError.checkNotNull(inputs, r'GlobNodeState', 'inputs');
    BuiltValueNullFieldError.checkNotNull(
      pendingBuildAction,
      r'GlobNodeState',
      'pendingBuildAction',
    );
    BuiltValueNullFieldError.checkNotNull(results, r'GlobNodeState', 'results');
  }

  @override
  GlobNodeState rebuild(void Function(GlobNodeStateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GlobNodeStateBuilder toBuilder() => new GlobNodeStateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GlobNodeState &&
        inputs == other.inputs &&
        pendingBuildAction == other.pendingBuildAction &&
        results == other.results;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, inputs.hashCode);
    _$hash = $jc(_$hash, pendingBuildAction.hashCode);
    _$hash = $jc(_$hash, results.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GlobNodeState')
          ..add('inputs', inputs)
          ..add('pendingBuildAction', pendingBuildAction)
          ..add('results', results))
        .toString();
  }
}

class GlobNodeStateBuilder
    implements Builder<GlobNodeState, GlobNodeStateBuilder> {
  _$GlobNodeState? _$v;

  SetBuilder<AssetId>? _inputs;
  SetBuilder<AssetId> get inputs =>
      _$this._inputs ??= new SetBuilder<AssetId>();
  set inputs(SetBuilder<AssetId>? inputs) => _$this._inputs = inputs;

  PendingBuildAction? _pendingBuildAction;
  PendingBuildAction? get pendingBuildAction => _$this._pendingBuildAction;
  set pendingBuildAction(PendingBuildAction? pendingBuildAction) =>
      _$this._pendingBuildAction = pendingBuildAction;

  ListBuilder<AssetId>? _results;
  ListBuilder<AssetId> get results =>
      _$this._results ??= new ListBuilder<AssetId>();
  set results(ListBuilder<AssetId>? results) => _$this._results = results;

  GlobNodeStateBuilder();

  GlobNodeStateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _inputs = $v.inputs.toBuilder();
      _pendingBuildAction = $v.pendingBuildAction;
      _results = $v.results.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GlobNodeState other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$GlobNodeState;
  }

  @override
  void update(void Function(GlobNodeStateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GlobNodeState build() => _build();

  _$GlobNodeState _build() {
    _$GlobNodeState _$result;
    try {
      _$result =
          _$v ??
          new _$GlobNodeState._(
            inputs: inputs.build(),
            pendingBuildAction: BuiltValueNullFieldError.checkNotNull(
              pendingBuildAction,
              r'GlobNodeState',
              'pendingBuildAction',
            ),
            results: results.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'inputs';
        inputs.build();

        _$failedField = 'results';
        results.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'GlobNodeState',
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

class _$PostProcessAnchorNodeState extends PostProcessAnchorNodeState {
  @override
  final Digest? previousInputsDigest;

  factory _$PostProcessAnchorNodeState([
    void Function(PostProcessAnchorNodeStateBuilder)? updates,
  ]) => (new PostProcessAnchorNodeStateBuilder()..update(updates))._build();

  _$PostProcessAnchorNodeState._({this.previousInputsDigest}) : super._();

  @override
  PostProcessAnchorNodeState rebuild(
    void Function(PostProcessAnchorNodeStateBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PostProcessAnchorNodeStateBuilder toBuilder() =>
      new PostProcessAnchorNodeStateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PostProcessAnchorNodeState &&
        previousInputsDigest == other.previousInputsDigest;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, previousInputsDigest.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PostProcessAnchorNodeState')
      ..add('previousInputsDigest', previousInputsDigest)).toString();
  }
}

class PostProcessAnchorNodeStateBuilder
    implements
        Builder<PostProcessAnchorNodeState, PostProcessAnchorNodeStateBuilder> {
  _$PostProcessAnchorNodeState? _$v;

  Digest? _previousInputsDigest;
  Digest? get previousInputsDigest => _$this._previousInputsDigest;
  set previousInputsDigest(Digest? previousInputsDigest) =>
      _$this._previousInputsDigest = previousInputsDigest;

  PostProcessAnchorNodeStateBuilder();

  PostProcessAnchorNodeStateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _previousInputsDigest = $v.previousInputsDigest;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PostProcessAnchorNodeState other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$PostProcessAnchorNodeState;
  }

  @override
  void update(void Function(PostProcessAnchorNodeStateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PostProcessAnchorNodeState build() => _build();

  _$PostProcessAnchorNodeState _build() {
    final _$result =
        _$v ??
        new _$PostProcessAnchorNodeState._(
          previousInputsDigest: previousInputsDigest,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
