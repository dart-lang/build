// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stage_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$StageResult extends StageResult {
  @override
  final int transformedCount;
  @override
  final int symlinkCount;

  factory _$StageResult([void Function(StageResultBuilder)? updates]) =>
      (StageResultBuilder()..update(updates))._build();

  _$StageResult._({required this.transformedCount, required this.symlinkCount})
    : super._();
  @override
  StageResult rebuild(void Function(StageResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  StageResultBuilder toBuilder() => StageResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is StageResult &&
        transformedCount == other.transformedCount &&
        symlinkCount == other.symlinkCount;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, transformedCount.hashCode);
    _$hash = $jc(_$hash, symlinkCount.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'StageResult')
          ..add('transformedCount', transformedCount)
          ..add('symlinkCount', symlinkCount))
        .toString();
  }
}

class StageResultBuilder implements Builder<StageResult, StageResultBuilder> {
  _$StageResult? _$v;

  int? _transformedCount;
  int? get transformedCount => _$this._transformedCount;
  set transformedCount(int? transformedCount) =>
      _$this._transformedCount = transformedCount;

  int? _symlinkCount;
  int? get symlinkCount => _$this._symlinkCount;
  set symlinkCount(int? symlinkCount) => _$this._symlinkCount = symlinkCount;

  StageResultBuilder();

  StageResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _transformedCount = $v.transformedCount;
      _symlinkCount = $v.symlinkCount;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(StageResult other) {
    _$v = other as _$StageResult;
  }

  @override
  void update(void Function(StageResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  StageResult build() => _build();

  _$StageResult _build() {
    final _$result =
        _$v ??
        _$StageResult._(
          transformedCount: BuiltValueNullFieldError.checkNotNull(
            transformedCount,
            r'StageResult',
            'transformedCount',
          ),
          symlinkCount: BuiltValueNullFieldError.checkNotNull(
            symlinkCount,
            r'StageResult',
            'symlinkCount',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
