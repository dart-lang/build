// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incremental_build_state.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<IncrementalBuildState> _$incrementalBuildStateSerializer =
    _$IncrementalBuildStateSerializer();

class _$IncrementalBuildStateSerializer
    implements StructuredSerializer<IncrementalBuildState> {
  @override
  final Iterable<Type> types = const [
    IncrementalBuildState,
    _$IncrementalBuildState,
  ];
  @override
  final String wireName = 'IncrementalBuildState';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    IncrementalBuildState object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'sources',
      serializers.serialize(
        object.sources,
        specifiedType: const FullType(BuiltSet, const [
          const FullType(AssetId),
        ]),
      ),
      'digests',
      serializers.serialize(
        object.digests,
        specifiedType: const FullType(BuiltMap, const [
          const FullType(AssetId),
          const FullType(Digest),
        ]),
      ),
      'missingSources',
      serializers.serialize(
        object.missingSources,
        specifiedType: const FullType(BuiltSet, const [
          const FullType(AssetId),
        ]),
      ),
      'buildStepResults',
      serializers.serialize(
        object.buildStepResults,
        specifiedType: const FullType(BuiltMap, const [
          const FullType(BuildStepId),
          const FullType(BuildStepResult),
        ]),
      ),
      'postProcessResults',
      serializers.serialize(
        object.postProcessResults,
        specifiedType: const FullType(BuiltMap, const [
          const FullType(PostProcessBuildStepId),
          const FullType(PostProcessBuildStepResult),
        ]),
      ),
      'globResults',
      serializers.serialize(
        object.globResults,
        specifiedType: const FullType(BuiltMap, const [
          const FullType(GlobId),
          const FullType(GlobResult),
        ]),
      ),
    ];

    return result;
  }

  @override
  IncrementalBuildState deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = IncrementalBuildStateBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'sources':
          result.sources.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltSet, const [
                    const FullType(AssetId),
                  ]),
                )!
                as BuiltSet<Object?>,
          );
          break;
        case 'digests':
          result.digests.replace(
            serializers.deserialize(
              value,
              specifiedType: const FullType(BuiltMap, const [
                const FullType(AssetId),
                const FullType(Digest),
              ]),
            )!,
          );
          break;
        case 'missingSources':
          result.missingSources.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltSet, const [
                    const FullType(AssetId),
                  ]),
                )!
                as BuiltSet<Object?>,
          );
          break;
        case 'buildStepResults':
          result.buildStepResults.replace(
            serializers.deserialize(
              value,
              specifiedType: const FullType(BuiltMap, const [
                const FullType(BuildStepId),
                const FullType(BuildStepResult),
              ]),
            )!,
          );
          break;
        case 'postProcessResults':
          result.postProcessResults.replace(
            serializers.deserialize(
              value,
              specifiedType: const FullType(BuiltMap, const [
                const FullType(PostProcessBuildStepId),
                const FullType(PostProcessBuildStepResult),
              ]),
            )!,
          );
          break;
        case 'globResults':
          result.globResults.replace(
            serializers.deserialize(
              value,
              specifiedType: const FullType(BuiltMap, const [
                const FullType(GlobId),
                const FullType(GlobResult),
              ]),
            )!,
          );
          break;
      }
    }

    return result.build();
  }
}

class _$IncrementalBuildState extends IncrementalBuildState {
  @override
  final BuiltSet<AssetId> sources;
  @override
  final BuiltMap<AssetId, Digest> digests;
  @override
  final BuiltSet<AssetId> missingSources;
  @override
  final BuiltMap<BuildStepId, BuildStepResult> buildStepResults;
  @override
  final BuiltMap<PostProcessBuildStepId, PostProcessBuildStepResult>
  postProcessResults;
  @override
  final BuiltMap<GlobId, GlobResult> globResults;

  factory _$IncrementalBuildState([
    void Function(IncrementalBuildStateBuilder)? updates,
  ]) => (IncrementalBuildStateBuilder()..update(updates))._build();

  _$IncrementalBuildState._({
    required this.sources,
    required this.digests,
    required this.missingSources,
    required this.buildStepResults,
    required this.postProcessResults,
    required this.globResults,
  }) : super._();
  @override
  IncrementalBuildState rebuild(
    void Function(IncrementalBuildStateBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  IncrementalBuildStateBuilder toBuilder() =>
      IncrementalBuildStateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is IncrementalBuildState &&
        sources == other.sources &&
        digests == other.digests &&
        missingSources == other.missingSources &&
        buildStepResults == other.buildStepResults &&
        postProcessResults == other.postProcessResults &&
        globResults == other.globResults;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, sources.hashCode);
    _$hash = $jc(_$hash, digests.hashCode);
    _$hash = $jc(_$hash, missingSources.hashCode);
    _$hash = $jc(_$hash, buildStepResults.hashCode);
    _$hash = $jc(_$hash, postProcessResults.hashCode);
    _$hash = $jc(_$hash, globResults.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'IncrementalBuildState')
          ..add('sources', sources)
          ..add('digests', digests)
          ..add('missingSources', missingSources)
          ..add('buildStepResults', buildStepResults)
          ..add('postProcessResults', postProcessResults)
          ..add('globResults', globResults))
        .toString();
  }
}

class IncrementalBuildStateBuilder
    implements Builder<IncrementalBuildState, IncrementalBuildStateBuilder> {
  _$IncrementalBuildState? _$v;

  SetBuilder<AssetId>? _sources;
  SetBuilder<AssetId> get sources => _$this._sources ??= SetBuilder<AssetId>();
  set sources(SetBuilder<AssetId>? sources) => _$this._sources = sources;

  MapBuilder<AssetId, Digest>? _digests;
  MapBuilder<AssetId, Digest> get digests =>
      _$this._digests ??= MapBuilder<AssetId, Digest>();
  set digests(MapBuilder<AssetId, Digest>? digests) =>
      _$this._digests = digests;

  SetBuilder<AssetId>? _missingSources;
  SetBuilder<AssetId> get missingSources =>
      _$this._missingSources ??= SetBuilder<AssetId>();
  set missingSources(SetBuilder<AssetId>? missingSources) =>
      _$this._missingSources = missingSources;

  MapBuilder<BuildStepId, BuildStepResult>? _buildStepResults;
  MapBuilder<BuildStepId, BuildStepResult> get buildStepResults =>
      _$this._buildStepResults ??= MapBuilder<BuildStepId, BuildStepResult>();
  set buildStepResults(
    MapBuilder<BuildStepId, BuildStepResult>? buildStepResults,
  ) => _$this._buildStepResults = buildStepResults;

  MapBuilder<PostProcessBuildStepId, PostProcessBuildStepResult>?
  _postProcessResults;
  MapBuilder<PostProcessBuildStepId, PostProcessBuildStepResult>
  get postProcessResults => _$this._postProcessResults ??=
      MapBuilder<PostProcessBuildStepId, PostProcessBuildStepResult>();
  set postProcessResults(
    MapBuilder<PostProcessBuildStepId, PostProcessBuildStepResult>?
    postProcessResults,
  ) => _$this._postProcessResults = postProcessResults;

  MapBuilder<GlobId, GlobResult>? _globResults;
  MapBuilder<GlobId, GlobResult> get globResults =>
      _$this._globResults ??= MapBuilder<GlobId, GlobResult>();
  set globResults(MapBuilder<GlobId, GlobResult>? globResults) =>
      _$this._globResults = globResults;

  IncrementalBuildStateBuilder();

  IncrementalBuildStateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _sources = $v.sources.toBuilder();
      _digests = $v.digests.toBuilder();
      _missingSources = $v.missingSources.toBuilder();
      _buildStepResults = $v.buildStepResults.toBuilder();
      _postProcessResults = $v.postProcessResults.toBuilder();
      _globResults = $v.globResults.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(IncrementalBuildState other) {
    _$v = other as _$IncrementalBuildState;
  }

  @override
  void update(void Function(IncrementalBuildStateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  IncrementalBuildState build() => _build();

  _$IncrementalBuildState _build() {
    _$IncrementalBuildState _$result;
    try {
      _$result =
          _$v ??
          _$IncrementalBuildState._(
            sources: sources.build(),
            digests: digests.build(),
            missingSources: missingSources.build(),
            buildStepResults: buildStepResults.build(),
            postProcessResults: postProcessResults.build(),
            globResults: globResults.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'sources';
        sources.build();
        _$failedField = 'digests';
        digests.build();
        _$failedField = 'missingSources';
        missingSources.build();
        _$failedField = 'buildStepResults';
        buildStepResults.build();
        _$failedField = 'postProcessResults';
        postProcessResults.build();
        _$failedField = 'globResults';
        globResults.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'IncrementalBuildState',
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
