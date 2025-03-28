// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deps_cycle.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DepsCycle extends DepsCycle {
  @override
  final BuiltSet<DepsNode> nodes;

  factory _$DepsCycle([void Function(DepsCycleBuilder)? updates]) =>
      (new DepsCycleBuilder()..update(updates))._build();

  _$DepsCycle._({required this.nodes}) : super._() {
    BuiltValueNullFieldError.checkNotNull(nodes, r'DepsCycle', 'nodes');
  }

  @override
  DepsCycle rebuild(void Function(DepsCycleBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DepsCycleBuilder toBuilder() => new DepsCycleBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DepsCycle && nodes == other.nodes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, nodes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DepsCycle')
      ..add('nodes', nodes)).toString();
  }
}

class DepsCycleBuilder implements Builder<DepsCycle, DepsCycleBuilder> {
  _$DepsCycle? _$v;

  SetBuilder<DepsNode>? _nodes;
  SetBuilder<DepsNode> get nodes =>
      _$this._nodes ??= new SetBuilder<DepsNode>();
  set nodes(SetBuilder<DepsNode>? nodes) => _$this._nodes = nodes;

  DepsCycleBuilder();

  DepsCycleBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _nodes = $v.nodes.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DepsCycle other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$DepsCycle;
  }

  @override
  void update(void Function(DepsCycleBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DepsCycle build() => _build();

  _$DepsCycle _build() {
    _$DepsCycle _$result;
    try {
      _$result = _$v ?? new _$DepsCycle._(nodes: nodes.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'nodes';
        nodes.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'DepsCycle',
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
