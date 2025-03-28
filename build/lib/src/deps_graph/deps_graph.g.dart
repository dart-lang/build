// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deps_graph.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DepsGraph extends DepsGraph {
  @override
  final DepsCycle root;
  @override
  final BuiltList<DepsGraph> children;

  factory _$DepsGraph([void Function(DepsGraphBuilder)? updates]) =>
      (new DepsGraphBuilder()..update(updates))._build();

  _$DepsGraph._({required this.root, required this.children}) : super._() {
    BuiltValueNullFieldError.checkNotNull(root, r'DepsGraph', 'root');
    BuiltValueNullFieldError.checkNotNull(children, r'DepsGraph', 'children');
  }

  @override
  DepsGraph rebuild(void Function(DepsGraphBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DepsGraphBuilder toBuilder() => new DepsGraphBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DepsGraph &&
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
    return (newBuiltValueToStringHelper(r'DepsGraph')
          ..add('root', root)
          ..add('children', children))
        .toString();
  }
}

class DepsGraphBuilder implements Builder<DepsGraph, DepsGraphBuilder> {
  _$DepsGraph? _$v;

  DepsCycleBuilder? _root;
  DepsCycleBuilder get root => _$this._root ??= new DepsCycleBuilder();
  set root(DepsCycleBuilder? root) => _$this._root = root;

  ListBuilder<DepsGraph>? _children;
  ListBuilder<DepsGraph> get children =>
      _$this._children ??= new ListBuilder<DepsGraph>();
  set children(ListBuilder<DepsGraph>? children) => _$this._children = children;

  DepsGraphBuilder();

  DepsGraphBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _root = $v.root.toBuilder();
      _children = $v.children.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DepsGraph other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$DepsGraph;
  }

  @override
  void update(void Function(DepsGraphBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DepsGraph build() => _build();

  _$DepsGraph _build() {
    _$DepsGraph _$result;
    try {
      _$result =
          _$v ??
          new _$DepsGraph._(root: root.build(), children: children.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'root';
        root.build();
        _$failedField = 'children';
        children.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'DepsGraph',
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
