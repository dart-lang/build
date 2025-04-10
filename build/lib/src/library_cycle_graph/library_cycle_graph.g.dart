// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_cycle_graph.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<LibraryCycleGraph> _$libraryCycleGraphSerializer =
    new _$LibraryCycleGraphSerializer();

class _$LibraryCycleGraphSerializer
    implements StructuredSerializer<LibraryCycleGraph> {
  @override
  final Iterable<Type> types = const [LibraryCycleGraph, _$LibraryCycleGraph];
  @override
  final String wireName = 'LibraryCycleGraph';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    LibraryCycleGraph object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'root',
      serializers.serialize(
        object.root,
        specifiedType: const FullType(LibraryCycle),
      ),
      'children',
      serializers.serialize(
        object.children,
        specifiedType: const FullType(BuiltList, const [
          const FullType(LibraryCycleGraph),
        ]),
      ),
    ];

    return result;
  }

  @override
  LibraryCycleGraph deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new LibraryCycleGraphBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'root':
          result.root.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(LibraryCycle),
                )!
                as LibraryCycle,
          );
          break;
        case 'children':
          result.children.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltList, const [
                    const FullType(LibraryCycleGraph),
                  ]),
                )!
                as BuiltList<Object?>,
          );
          break;
      }
    }

    return result.build();
  }
}

class _$LibraryCycleGraph extends LibraryCycleGraph {
  @override
  final LibraryCycle root;
  @override
  final BuiltList<LibraryCycleGraph> children;

  factory _$LibraryCycleGraph([
    void Function(LibraryCycleGraphBuilder)? updates,
  ]) => (new LibraryCycleGraphBuilder()..update(updates))._build();

  _$LibraryCycleGraph._({required this.root, required this.children})
    : super._() {
    BuiltValueNullFieldError.checkNotNull(root, r'LibraryCycleGraph', 'root');
    BuiltValueNullFieldError.checkNotNull(
      children,
      r'LibraryCycleGraph',
      'children',
    );
  }

  @override
  LibraryCycleGraph rebuild(void Function(LibraryCycleGraphBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LibraryCycleGraphBuilder toBuilder() =>
      new LibraryCycleGraphBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LibraryCycleGraph &&
        root == other.root &&
        children == other.children;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, root.hashCode);
    _$hash = $jc(_$hash, children.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LibraryCycleGraph')
          ..add('root', root)
          ..add('children', children))
        .toString();
  }
}

class LibraryCycleGraphBuilder
    implements Builder<LibraryCycleGraph, LibraryCycleGraphBuilder> {
  _$LibraryCycleGraph? _$v;

  LibraryCycleBuilder? _root;
  LibraryCycleBuilder get root => _$this._root ??= new LibraryCycleBuilder();
  set root(LibraryCycleBuilder? root) => _$this._root = root;

  ListBuilder<LibraryCycleGraph>? _children;
  ListBuilder<LibraryCycleGraph> get children =>
      _$this._children ??= new ListBuilder<LibraryCycleGraph>();
  set children(ListBuilder<LibraryCycleGraph>? children) =>
      _$this._children = children;

  LibraryCycleGraphBuilder();

  LibraryCycleGraphBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _root = $v.root.toBuilder();
      _children = $v.children.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LibraryCycleGraph other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$LibraryCycleGraph;
  }

  @override
  void update(void Function(LibraryCycleGraphBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LibraryCycleGraph build() => _build();

  _$LibraryCycleGraph _build() {
    _$LibraryCycleGraph _$result;
    try {
      _$result =
          _$v ??
          new _$LibraryCycleGraph._(
            root: root.build(),
            children: children.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'root';
        root.build();
        _$failedField = 'children';
        children.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'LibraryCycleGraph',
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
