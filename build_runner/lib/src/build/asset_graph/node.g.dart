// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const NodeType _$postGenerated = const NodeType._('postGenerated');
const NodeType _$placeholder = const NodeType._('placeholder');
const NodeType _$source = const NodeType._('source');
const NodeType _$missingSource = const NodeType._('missingSource');

NodeType _$nodeTypeValueOf(String name) {
  switch (name) {
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
  _$postGenerated,
  _$placeholder,
  _$source,
  _$missingSource,
]);

Serializer<NodeType> _$nodeTypeSerializer = _$NodeTypeSerializer();
Serializer<AssetNode> _$assetNodeSerializer = _$AssetNodeSerializer();

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
    ];
    Object? value;
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

class _$AssetNode extends AssetNode {
  @override
  final AssetId id;
  @override
  final NodeType type;
  @override
  final Digest? digest;

  factory _$AssetNode([void Function(AssetNodeBuilder)? updates]) =>
      (AssetNodeBuilder()..update(updates))._build();

  _$AssetNode._({required this.id, required this.type, this.digest})
    : super._();
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
        digest == other.digest;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, digest.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AssetNode')
          ..add('id', id)
          ..add('type', type)
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

  Digest? _digest;
  Digest? get digest => _$this._digest;
  set digest(Digest? digest) => _$this._digest = digest;

  AssetNodeBuilder();

  AssetNodeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _type = $v.type;
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
    final _$result =
        _$v ??
        _$AssetNode._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'AssetNode', 'id'),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'AssetNode',
            'type',
          ),
          digest: digest,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
