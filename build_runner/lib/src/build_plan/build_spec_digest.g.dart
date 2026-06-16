// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_spec_digest.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<BuildSpecDigest> _$buildSpecDigestSerializer =
    _$BuildSpecDigestSerializer();

class _$BuildSpecDigestSerializer
    implements StructuredSerializer<BuildSpecDigest> {
  @override
  final Iterable<Type> types = const [BuildSpecDigest, _$BuildSpecDigest];
  @override
  final String wireName = 'BuildSpecDigest';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    BuildSpecDigest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'buildTriggersDigest',
      serializers.serialize(
        object.buildTriggersDigest,
        specifiedType: const FullType(String),
      ),
      'buildPhasesDigest',
      serializers.serialize(
        object.buildPhasesDigest,
        specifiedType: const FullType(String),
      ),
      'dartVersion',
      serializers.serialize(
        object.dartVersion,
        specifiedType: const FullType(String),
      ),
      'enabledExperiments',
      serializers.serialize(
        object.enabledExperiments,
        specifiedType: const FullType(BuiltList, const [
          const FullType(String),
        ]),
      ),
      'packageLanguageVersions',
      serializers.serialize(
        object.packageLanguageVersions,
        specifiedType: const FullType(BuiltMap, const [
          const FullType(String),
          const FullType.nullable(String),
        ]),
      ),
      'inBuildPhasesOptionsDigests',
      serializers.serialize(
        object.inBuildPhasesOptionsDigests,
        specifiedType: const FullType(BuiltList, const [
          const FullType(String),
        ]),
      ),
      'postBuildActionsOptionsDigests',
      serializers.serialize(
        object.postBuildActionsOptionsDigests,
        specifiedType: const FullType(BuiltList, const [
          const FullType(String),
        ]),
      ),
    ];
    Object? value;
    value = object.compileDigest;
    if (value != null) {
      result
        ..add('compileDigest')
        ..add(
          serializers.serialize(value, specifiedType: const FullType(String)),
        );
    }
    return result;
  }

  @override
  BuildSpecDigest deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BuildSpecDigestBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'compileDigest':
          result.compileDigest =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String?;
          break;
        case 'buildTriggersDigest':
          result.buildTriggersDigest =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )!
                  as String;
          break;
        case 'buildPhasesDigest':
          result.buildPhasesDigest =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )!
                  as String;
          break;
        case 'dartVersion':
          result.dartVersion =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )!
                  as String;
          break;
        case 'enabledExperiments':
          result.enabledExperiments.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltList, const [
                    const FullType(String),
                  ]),
                )!
                as BuiltList<Object?>,
          );
          break;
        case 'packageLanguageVersions':
          result.packageLanguageVersions.replace(
            serializers.deserialize(
              value,
              specifiedType: const FullType(BuiltMap, const [
                const FullType(String),
                const FullType.nullable(String),
              ]),
            )!,
          );
          break;
        case 'inBuildPhasesOptionsDigests':
          result.inBuildPhasesOptionsDigests.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltList, const [
                    const FullType(String),
                  ]),
                )!
                as BuiltList<Object?>,
          );
          break;
        case 'postBuildActionsOptionsDigests':
          result.postBuildActionsOptionsDigests.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltList, const [
                    const FullType(String),
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

class _$BuildSpecDigest extends BuildSpecDigest {
  @override
  final String? compileDigest;
  @override
  final String buildTriggersDigest;
  @override
  final String buildPhasesDigest;
  @override
  final String dartVersion;
  @override
  final BuiltList<String> enabledExperiments;
  @override
  final BuiltMap<String, String?> packageLanguageVersions;
  @override
  final BuiltList<String> inBuildPhasesOptionsDigests;
  @override
  final BuiltList<String> postBuildActionsOptionsDigests;

  factory _$BuildSpecDigest([void Function(BuildSpecDigestBuilder)? updates]) =>
      (BuildSpecDigestBuilder()..update(updates))._build();

  _$BuildSpecDigest._({
    this.compileDigest,
    required this.buildTriggersDigest,
    required this.buildPhasesDigest,
    required this.dartVersion,
    required this.enabledExperiments,
    required this.packageLanguageVersions,
    required this.inBuildPhasesOptionsDigests,
    required this.postBuildActionsOptionsDigests,
  }) : super._();
  @override
  BuildSpecDigest rebuild(void Function(BuildSpecDigestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BuildSpecDigestBuilder toBuilder() => BuildSpecDigestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BuildSpecDigest &&
        compileDigest == other.compileDigest &&
        buildTriggersDigest == other.buildTriggersDigest &&
        buildPhasesDigest == other.buildPhasesDigest &&
        dartVersion == other.dartVersion &&
        enabledExperiments == other.enabledExperiments &&
        packageLanguageVersions == other.packageLanguageVersions &&
        inBuildPhasesOptionsDigests == other.inBuildPhasesOptionsDigests &&
        postBuildActionsOptionsDigests == other.postBuildActionsOptionsDigests;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, compileDigest.hashCode);
    _$hash = $jc(_$hash, buildTriggersDigest.hashCode);
    _$hash = $jc(_$hash, buildPhasesDigest.hashCode);
    _$hash = $jc(_$hash, dartVersion.hashCode);
    _$hash = $jc(_$hash, enabledExperiments.hashCode);
    _$hash = $jc(_$hash, packageLanguageVersions.hashCode);
    _$hash = $jc(_$hash, inBuildPhasesOptionsDigests.hashCode);
    _$hash = $jc(_$hash, postBuildActionsOptionsDigests.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BuildSpecDigest')
          ..add('compileDigest', compileDigest)
          ..add('buildTriggersDigest', buildTriggersDigest)
          ..add('buildPhasesDigest', buildPhasesDigest)
          ..add('dartVersion', dartVersion)
          ..add('enabledExperiments', enabledExperiments)
          ..add('packageLanguageVersions', packageLanguageVersions)
          ..add('inBuildPhasesOptionsDigests', inBuildPhasesOptionsDigests)
          ..add(
            'postBuildActionsOptionsDigests',
            postBuildActionsOptionsDigests,
          ))
        .toString();
  }
}

class BuildSpecDigestBuilder
    implements Builder<BuildSpecDigest, BuildSpecDigestBuilder> {
  _$BuildSpecDigest? _$v;

  String? _compileDigest;
  String? get compileDigest => _$this._compileDigest;
  set compileDigest(String? compileDigest) =>
      _$this._compileDigest = compileDigest;

  String? _buildTriggersDigest;
  String? get buildTriggersDigest => _$this._buildTriggersDigest;
  set buildTriggersDigest(String? buildTriggersDigest) =>
      _$this._buildTriggersDigest = buildTriggersDigest;

  String? _buildPhasesDigest;
  String? get buildPhasesDigest => _$this._buildPhasesDigest;
  set buildPhasesDigest(String? buildPhasesDigest) =>
      _$this._buildPhasesDigest = buildPhasesDigest;

  String? _dartVersion;
  String? get dartVersion => _$this._dartVersion;
  set dartVersion(String? dartVersion) => _$this._dartVersion = dartVersion;

  ListBuilder<String>? _enabledExperiments;
  ListBuilder<String> get enabledExperiments =>
      _$this._enabledExperiments ??= ListBuilder<String>();
  set enabledExperiments(ListBuilder<String>? enabledExperiments) =>
      _$this._enabledExperiments = enabledExperiments;

  MapBuilder<String, String?>? _packageLanguageVersions;
  MapBuilder<String, String?> get packageLanguageVersions =>
      _$this._packageLanguageVersions ??= MapBuilder<String, String?>();
  set packageLanguageVersions(
    MapBuilder<String, String?>? packageLanguageVersions,
  ) => _$this._packageLanguageVersions = packageLanguageVersions;

  ListBuilder<String>? _inBuildPhasesOptionsDigests;
  ListBuilder<String> get inBuildPhasesOptionsDigests =>
      _$this._inBuildPhasesOptionsDigests ??= ListBuilder<String>();
  set inBuildPhasesOptionsDigests(
    ListBuilder<String>? inBuildPhasesOptionsDigests,
  ) => _$this._inBuildPhasesOptionsDigests = inBuildPhasesOptionsDigests;

  ListBuilder<String>? _postBuildActionsOptionsDigests;
  ListBuilder<String> get postBuildActionsOptionsDigests =>
      _$this._postBuildActionsOptionsDigests ??= ListBuilder<String>();
  set postBuildActionsOptionsDigests(
    ListBuilder<String>? postBuildActionsOptionsDigests,
  ) => _$this._postBuildActionsOptionsDigests = postBuildActionsOptionsDigests;

  BuildSpecDigestBuilder();

  BuildSpecDigestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _compileDigest = $v.compileDigest;
      _buildTriggersDigest = $v.buildTriggersDigest;
      _buildPhasesDigest = $v.buildPhasesDigest;
      _dartVersion = $v.dartVersion;
      _enabledExperiments = $v.enabledExperiments.toBuilder();
      _packageLanguageVersions = $v.packageLanguageVersions.toBuilder();
      _inBuildPhasesOptionsDigests = $v.inBuildPhasesOptionsDigests.toBuilder();
      _postBuildActionsOptionsDigests = $v.postBuildActionsOptionsDigests
          .toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BuildSpecDigest other) {
    _$v = other as _$BuildSpecDigest;
  }

  @override
  void update(void Function(BuildSpecDigestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BuildSpecDigest build() => _build();

  _$BuildSpecDigest _build() {
    _$BuildSpecDigest _$result;
    try {
      _$result =
          _$v ??
          _$BuildSpecDigest._(
            compileDigest: compileDigest,
            buildTriggersDigest: BuiltValueNullFieldError.checkNotNull(
              buildTriggersDigest,
              r'BuildSpecDigest',
              'buildTriggersDigest',
            ),
            buildPhasesDigest: BuiltValueNullFieldError.checkNotNull(
              buildPhasesDigest,
              r'BuildSpecDigest',
              'buildPhasesDigest',
            ),
            dartVersion: BuiltValueNullFieldError.checkNotNull(
              dartVersion,
              r'BuildSpecDigest',
              'dartVersion',
            ),
            enabledExperiments: enabledExperiments.build(),
            packageLanguageVersions: packageLanguageVersions.build(),
            inBuildPhasesOptionsDigests: inBuildPhasesOptionsDigests.build(),
            postBuildActionsOptionsDigests: postBuildActionsOptionsDigests
                .build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'enabledExperiments';
        enabledExperiments.build();
        _$failedField = 'packageLanguageVersions';
        packageLanguageVersions.build();
        _$failedField = 'inBuildPhasesOptionsDigests';
        inBuildPhasesOptionsDigests.build();
        _$failedField = 'postBuildActionsOptionsDigests';
        postBuildActionsOptionsDigests.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'BuildSpecDigest',
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
