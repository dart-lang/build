// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glob_id.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<GlobId> _$globIdSerializer = _$GlobIdSerializer();

class _$GlobIdSerializer implements StructuredSerializer<GlobId> {
  @override
  final Iterable<Type> types = const [GlobId, _$GlobId];
  @override
  final String wireName = 'GlobId';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    GlobId object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'package',
      serializers.serialize(
        object.package,
        specifiedType: const FullType(String),
      ),
      'glob',
      serializers.serialize(object.glob, specifiedType: const FullType(String)),
      'phaseNumber',
      serializers.serialize(
        object.phaseNumber,
        specifiedType: const FullType(int),
      ),
    ];

    return result;
  }

  @override
  GlobId deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GlobIdBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'package':
          result.package =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )!
                  as String;
          break;
        case 'glob':
          result.glob =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )!
                  as String;
          break;
        case 'phaseNumber':
          result.phaseNumber =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(int),
                  )!
                  as int;
          break;
      }
    }

    return result.build();
  }
}

class _$GlobId extends GlobId {
  @override
  final String package;
  @override
  final String glob;
  @override
  final int phaseNumber;

  factory _$GlobId([void Function(GlobIdBuilder)? updates]) =>
      (GlobIdBuilder()..update(updates))._build();

  _$GlobId._({
    required this.package,
    required this.glob,
    required this.phaseNumber,
  }) : super._();
  @override
  GlobId rebuild(void Function(GlobIdBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GlobIdBuilder toBuilder() => GlobIdBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GlobId &&
        package == other.package &&
        glob == other.glob &&
        phaseNumber == other.phaseNumber;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, package.hashCode);
    _$hash = $jc(_$hash, glob.hashCode);
    _$hash = $jc(_$hash, phaseNumber.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GlobId')
          ..add('package', package)
          ..add('glob', glob)
          ..add('phaseNumber', phaseNumber))
        .toString();
  }
}

class GlobIdBuilder implements Builder<GlobId, GlobIdBuilder> {
  _$GlobId? _$v;

  String? _package;
  String? get package => _$this._package;
  set package(String? package) => _$this._package = package;

  String? _glob;
  String? get glob => _$this._glob;
  set glob(String? glob) => _$this._glob = glob;

  int? _phaseNumber;
  int? get phaseNumber => _$this._phaseNumber;
  set phaseNumber(int? phaseNumber) => _$this._phaseNumber = phaseNumber;

  GlobIdBuilder();

  GlobIdBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _package = $v.package;
      _glob = $v.glob;
      _phaseNumber = $v.phaseNumber;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GlobId other) {
    _$v = other as _$GlobId;
  }

  @override
  void update(void Function(GlobIdBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GlobId build() => _build();

  _$GlobId _build() {
    final _$result =
        _$v ??
        _$GlobId._(
          package: BuiltValueNullFieldError.checkNotNull(
            package,
            r'GlobId',
            'package',
          ),
          glob: BuiltValueNullFieldError.checkNotNull(glob, r'GlobId', 'glob'),
          phaseNumber: BuiltValueNullFieldError.checkNotNull(
            phaseNumber,
            r'GlobId',
            'phaseNumber',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
