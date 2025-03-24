// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deps_node.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DepsNode extends DepsNode {
  @override
  final AssetId id;
  @override
  final bool missing;
  @override
  final int? phase;
  @override
  final BuiltSet<AssetId>? deps;

  factory _$DepsNode([void Function(DepsNodeBuilder)? updates]) =>
      (new DepsNodeBuilder()..update(updates))._build();

  _$DepsNode._({required this.id, required this.missing, this.phase, this.deps})
    : super._() {
    BuiltValueNullFieldError.checkNotNull(id, r'DepsNode', 'id');
    BuiltValueNullFieldError.checkNotNull(missing, r'DepsNode', 'missing');
  }

  @override
  DepsNode rebuild(void Function(DepsNodeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DepsNodeBuilder toBuilder() => new DepsNodeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DepsNode &&
        id == other.id &&
        missing == other.missing &&
        phase == other.phase &&
        deps == other.deps;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, missing.hashCode);
    _$hash = $jc(_$hash, phase.hashCode);
    _$hash = $jc(_$hash, deps.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DepsNode')
          ..add('id', id)
          ..add('missing', missing)
          ..add('phase', phase)
          ..add('deps', deps))
        .toString();
  }
}

class DepsNodeBuilder implements Builder<DepsNode, DepsNodeBuilder> {
  _$DepsNode? _$v;

  AssetId? _id;
  AssetId? get id => _$this._id;
  set id(AssetId? id) => _$this._id = id;

  bool? _missing;
  bool? get missing => _$this._missing;
  set missing(bool? missing) => _$this._missing = missing;

  int? _phase;
  int? get phase => _$this._phase;
  set phase(int? phase) => _$this._phase = phase;

  SetBuilder<AssetId>? _deps;
  SetBuilder<AssetId> get deps => _$this._deps ??= new SetBuilder<AssetId>();
  set deps(SetBuilder<AssetId>? deps) => _$this._deps = deps;

  DepsNodeBuilder();

  DepsNodeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _missing = $v.missing;
      _phase = $v.phase;
      _deps = $v.deps?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DepsNode other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$DepsNode;
  }

  @override
  void update(void Function(DepsNodeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DepsNode build() => _build();

  _$DepsNode _build() {
    _$DepsNode _$result;
    try {
      _$result =
          _$v ??
          new _$DepsNode._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'DepsNode', 'id'),
            missing: BuiltValueNullFieldError.checkNotNull(
              missing,
              r'DepsNode',
              'missing',
            ),
            phase: phase,
            deps: _deps?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'deps';
        _deps?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'DepsNode',
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
