// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const NodeType _$generated = const NodeType._('generated');
const NodeType _$postGenerated = const NodeType._('postGenerated');
const NodeType _$placeholder = const NodeType._('placeholder');
const NodeType _$source = const NodeType._('source');
const NodeType _$missingSource = const NodeType._('missingSource');

NodeType _$nodeTypeValueOf(String name) {
  switch (name) {
    case 'generated':
      return _$generated;
    case 'postGenerated':
      return _$postGenerated;
    case 'placeholder':
      return _$placeholder;
    case 'source':
      return _$source;
    case 'missingSource':
      return _$missingSource;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<NodeType> _$nodeTypeValues = BuiltSet<NodeType>(const <NodeType>[
  _$generated,
  _$postGenerated,
  _$placeholder,
  _$source,
  _$missingSource,
]);

Serializer<NodeType> _$nodeTypeSerializer = _$NodeTypeSerializer();
Serializer<AssetNode> _$assetNodeSerializer = _$AssetNodeSerializer();
Serializer<GeneratedNodeConfiguration> _$generatedNodeConfigurationSerializer =
    _$GeneratedNodeConfigurationSerializer();

class _$NodeTypeSerializer implements PrimitiveSerializer<NodeType> {
  @override
  final Iterable<Type> types = const <Type>[NodeType];
  @override
  final String wireName = 'NodeType';

  @override
  Object serialize(
    Serializers serializers,
    NodeType object, {
    FullType specifiedType = FullType.unspecified,
  }) => object.name;

  @override
  NodeType deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => NodeType.valueOf(serialized as String);
}

class _$AssetNodeSerializer implements StructuredSerializer<AssetNode> {
  @override
  final Iterable<Type> types = const [AssetNode, _$AssetNode];
  @override
  final String wireName = 'AssetNode';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    AssetNode object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'id',
      serializers.serialize(object.id, specifiedType: const FullType(AssetId)),
      'type',
      serializers.serialize(
        object.type,
        specifiedType: const FullType(NodeType),
      ),
      'primaryOutputs',
      serializers.serialize(
        object.primaryOutputs,
        specifiedType: const FullType(BuiltSet, const [
          const FullType(AssetId),
        ]),
      ),
    ];
    Object? value;
    value = object.generatedNodeConfiguration;
    if (value != null) {
      result
        ..add('generatedNodeConfiguration')
        ..add(
          serializers.serialize(
            value,
            specifiedType: const FullType(GeneratedNodeConfiguration),
          ),
        );
    }
    value = object.digest;
    if (value != null) {
      result
        ..add('digest')
        ..add(
          serializers.serialize(value, specifiedType: const FullType(Digest)),
        );
    }
    return result;
  }

  @override
  AssetNode deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AssetNodeBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'id':
          result.id =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(AssetId),
                  )!
                  as AssetId;
          break;
        case 'type':
          result.type =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(NodeType),
                  )!
                  as NodeType;
          break;
        case 'generatedNodeConfiguration':
          result.generatedNodeConfiguration.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(GeneratedNodeConfiguration),
                )!
                as GeneratedNodeConfiguration,
          );
          break;
        case 'primaryOutputs':
          result.primaryOutputs.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltSet, const [
                    const FullType(AssetId),
                  ]),
                )!
                as BuiltSet<Object?>,
          );
          break;
        case 'digest':
          result.digest =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(Digest),
                  )
                  as Digest?;
          break;
      }
    }

    return result.build();
  }
}

class _$GeneratedNodeConfigurationSerializer
    implements StructuredSerializer<GeneratedNodeConfiguration> {
  @override
  final Iterable<Type> types = const [
    GeneratedNodeConfiguration,
    _$GeneratedNodeConfiguration,
  ];
  @override
  final String wireName = 'GeneratedNodeConfiguration';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    GeneratedNodeConfiguration object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'primaryInput',
      serializers.serialize(
        object.primaryInput,
        specifiedType: const FullType(AssetId),
      ),
      'phaseNumber',
      serializers.serialize(
        object.phaseNumber,
        specifiedType: const FullType(int),
      ),
      'isHidden',
      serializers.serialize(
        object.isHidden,
        specifiedType: const FullType(bool),
      ),
    ];

    return result;
  }

  @override
  GeneratedNodeConfiguration deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GeneratedNodeConfigurationBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'primaryInput':
          result.primaryInput =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(AssetId),
                  )!
                  as AssetId;
          break;
        case 'phaseNumber':
          result.phaseNumber =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(int),
                  )!
                  as int;
          break;
        case 'isHidden':
          result.isHidden =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )!
                  as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$AssetNode extends AssetNode {
  @override
  final AssetId id;
  @override
  final NodeType type;
  @override
  final GeneratedNodeConfiguration? generatedNodeConfiguration;
  @override
  final BuiltSet<AssetId> primaryOutputs;
  @override
  final Digest? digest;

  factory _$AssetNode([void Function(AssetNodeBuilder)? updates]) =>
      (AssetNodeBuilder()..update(updates))._build();

  _$AssetNode._({
    required this.id,
    required this.type,
    this.generatedNodeConfiguration,
    required this.primaryOutputs,
    this.digest,
  }) : super._();
  @override
  AssetNode rebuild(void Function(AssetNodeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AssetNodeBuilder toBuilder() => AssetNodeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AssetNode &&
        id == other.id &&
        type == other.type &&
        generatedNodeConfiguration == other.generatedNodeConfiguration &&
        primaryOutputs == other.primaryOutputs &&
        digest == other.digest;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, generatedNodeConfiguration.hashCode);
    _$hash = $jc(_$hash, primaryOutputs.hashCode);
    _$hash = $jc(_$hash, digest.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AssetNode')
          ..add('id', id)
          ..add('type', type)
          ..add('generatedNodeConfiguration', generatedNodeConfiguration)
          ..add('primaryOutputs', primaryOutputs)
          ..add('digest', digest))
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
          GeneratedNodeConfigurationBuilder();
  set generatedNodeConfiguration(
    GeneratedNodeConfigurationBuilder? generatedNodeConfiguration,
  ) => _$this._generatedNodeConfiguration = generatedNodeConfiguration;

  SetBuilder<AssetId>? _primaryOutputs;
  SetBuilder<AssetId> get primaryOutputs =>
      _$this._primaryOutputs ??= SetBuilder<AssetId>();
  set primaryOutputs(SetBuilder<AssetId>? primaryOutputs) =>
      _$this._primaryOutputs = primaryOutputs;

  Digest? _digest;
  Digest? get digest => _$this._digest;
  set digest(Digest? digest) => _$this._digest = digest;

  AssetNodeBuilder();

  AssetNodeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _type = $v.type;
      _generatedNodeConfiguration = $v.generatedNodeConfiguration?.toBuilder();
      _primaryOutputs = $v.primaryOutputs.toBuilder();
      _digest = $v.digest;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AssetNode other) {
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
          _$AssetNode._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'AssetNode', 'id'),
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'AssetNode',
              'type',
            ),
            generatedNodeConfiguration: _generatedNodeConfiguration?.build(),
            primaryOutputs: primaryOutputs.build(),
            digest: digest,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'generatedNodeConfiguration';
        _generatedNodeConfiguration?.build();
        _$failedField = 'primaryOutputs';
        primaryOutputs.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
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
  final int phaseNumber;
  @override
  final bool isHidden;

  factory _$GeneratedNodeConfiguration([
    void Function(GeneratedNodeConfigurationBuilder)? updates,
  ]) => (GeneratedNodeConfigurationBuilder()..update(updates))._build();

  _$GeneratedNodeConfiguration._({
    required this.primaryInput,
    required this.phaseNumber,
    required this.isHidden,
  }) : super._();
  @override
  GeneratedNodeConfiguration rebuild(
    void Function(GeneratedNodeConfigurationBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GeneratedNodeConfigurationBuilder toBuilder() =>
      GeneratedNodeConfigurationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GeneratedNodeConfiguration &&
        primaryInput == other.primaryInput &&
        phaseNumber == other.phaseNumber &&
        isHidden == other.isHidden;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, primaryInput.hashCode);
    _$hash = $jc(_$hash, phaseNumber.hashCode);
    _$hash = $jc(_$hash, isHidden.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GeneratedNodeConfiguration')
          ..add('primaryInput', primaryInput)
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
      _phaseNumber = $v.phaseNumber;
      _isHidden = $v.isHidden;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GeneratedNodeConfiguration other) {
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
        _$GeneratedNodeConfiguration._(
          primaryInput: BuiltValueNullFieldError.checkNotNull(
            primaryInput,
            r'GeneratedNodeConfiguration',
            'primaryInput',
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

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
