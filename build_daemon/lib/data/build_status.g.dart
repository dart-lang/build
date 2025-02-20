// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const BuildStatus _$started = const BuildStatus._('started');
const BuildStatus _$succeeded = const BuildStatus._('succeeded');
const BuildStatus _$failed = const BuildStatus._('failed');

BuildStatus _$valueOf(String name) {
  switch (name) {
    case 'started':
      return _$started;
    case 'succeeded':
      return _$succeeded;
    case 'failed':
      return _$failed;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<BuildStatus> _$values = new BuiltSet<BuildStatus>(
  const <BuildStatus>[_$started, _$succeeded, _$failed],
);

Serializer<BuildStatus> _$buildStatusSerializer = new _$BuildStatusSerializer();
Serializer<DefaultBuildResult> _$defaultBuildResultSerializer =
    new _$DefaultBuildResultSerializer();
Serializer<BuildResults> _$buildResultsSerializer =
    new _$BuildResultsSerializer();

class _$BuildStatusSerializer implements PrimitiveSerializer<BuildStatus> {
  @override
  final Iterable<Type> types = const <Type>[BuildStatus];
  @override
  final String wireName = 'BuildStatus';

  @override
  Object serialize(
    Serializers serializers,
    BuildStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) => object.name;

  @override
  BuildStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => BuildStatus.valueOf(serialized as String);
}

class _$DefaultBuildResultSerializer
    implements StructuredSerializer<DefaultBuildResult> {
  @override
  final Iterable<Type> types = const [DefaultBuildResult, _$DefaultBuildResult];
  @override
  final String wireName = 'DefaultBuildResult';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    DefaultBuildResult object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'status',
      serializers.serialize(
        object.status,
        specifiedType: const FullType(BuildStatus),
      ),
      'target',
      serializers.serialize(
        object.target,
        specifiedType: const FullType(String),
      ),
    ];
    Object? value;
    value = object.buildId;
    if (value != null) {
      result
        ..add('buildId')
        ..add(
          serializers.serialize(value, specifiedType: const FullType(String)),
        );
    }
    value = object.error;
    if (value != null) {
      result
        ..add('error')
        ..add(
          serializers.serialize(value, specifiedType: const FullType(String)),
        );
    }
    value = object.isCached;
    if (value != null) {
      result
        ..add('isCached')
        ..add(
          serializers.serialize(value, specifiedType: const FullType(bool)),
        );
    }
    return result;
  }

  @override
  DefaultBuildResult deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new DefaultBuildResultBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'status':
          result.status =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuildStatus),
                  )!
                  as BuildStatus;
          break;
        case 'target':
          result.target =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )!
                  as String;
          break;
        case 'buildId':
          result.buildId =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String?;
          break;
        case 'error':
          result.error =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String?;
          break;
        case 'isCached':
          result.isCached =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )
                  as bool?;
          break;
      }
    }

    return result.build();
  }
}

class _$BuildResultsSerializer implements StructuredSerializer<BuildResults> {
  @override
  final Iterable<Type> types = const [BuildResults, _$BuildResults];
  @override
  final String wireName = 'BuildResults';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    BuildResults object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'results',
      serializers.serialize(
        object.results,
        specifiedType: const FullType(BuiltList, const [
          const FullType(BuildResult),
        ]),
      ),
    ];
    Object? value;
    value = object.changedAssets;
    if (value != null) {
      result
        ..add('changedAssets')
        ..add(
          serializers.serialize(
            value,
            specifiedType: const FullType(BuiltList, const [
              const FullType(Uri),
            ]),
          ),
        );
    }
    return result;
  }

  @override
  BuildResults deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new BuildResultsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'results':
          result.results.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltList, const [
                    const FullType(BuildResult),
                  ]),
                )!
                as BuiltList<Object?>,
          );
          break;
        case 'changedAssets':
          result.changedAssets.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltList, const [
                    const FullType(Uri),
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

class _$DefaultBuildResult extends DefaultBuildResult {
  @override
  final BuildStatus status;
  @override
  final String target;
  @override
  final String? buildId;
  @override
  final String? error;
  @override
  final bool? isCached;

  factory _$DefaultBuildResult([
    void Function(DefaultBuildResultBuilder)? updates,
  ]) => (new DefaultBuildResultBuilder()..update(updates))._build();

  _$DefaultBuildResult._({
    required this.status,
    required this.target,
    this.buildId,
    this.error,
    this.isCached,
  }) : super._() {
    BuiltValueNullFieldError.checkNotNull(
      status,
      r'DefaultBuildResult',
      'status',
    );
    BuiltValueNullFieldError.checkNotNull(
      target,
      r'DefaultBuildResult',
      'target',
    );
  }

  @override
  DefaultBuildResult rebuild(
    void Function(DefaultBuildResultBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DefaultBuildResultBuilder toBuilder() =>
      new DefaultBuildResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DefaultBuildResult &&
        status == other.status &&
        target == other.target &&
        buildId == other.buildId &&
        error == other.error &&
        isCached == other.isCached;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, target.hashCode);
    _$hash = $jc(_$hash, buildId.hashCode);
    _$hash = $jc(_$hash, error.hashCode);
    _$hash = $jc(_$hash, isCached.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DefaultBuildResult')
          ..add('status', status)
          ..add('target', target)
          ..add('buildId', buildId)
          ..add('error', error)
          ..add('isCached', isCached))
        .toString();
  }
}

class DefaultBuildResultBuilder
    implements Builder<DefaultBuildResult, DefaultBuildResultBuilder> {
  _$DefaultBuildResult? _$v;

  BuildStatus? _status;
  BuildStatus? get status => _$this._status;
  set status(BuildStatus? status) => _$this._status = status;

  String? _target;
  String? get target => _$this._target;
  set target(String? target) => _$this._target = target;

  String? _buildId;
  String? get buildId => _$this._buildId;
  set buildId(String? buildId) => _$this._buildId = buildId;

  String? _error;
  String? get error => _$this._error;
  set error(String? error) => _$this._error = error;

  bool? _isCached;
  bool? get isCached => _$this._isCached;
  set isCached(bool? isCached) => _$this._isCached = isCached;

  DefaultBuildResultBuilder();

  DefaultBuildResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _target = $v.target;
      _buildId = $v.buildId;
      _error = $v.error;
      _isCached = $v.isCached;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DefaultBuildResult other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$DefaultBuildResult;
  }

  @override
  void update(void Function(DefaultBuildResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DefaultBuildResult build() => _build();

  _$DefaultBuildResult _build() {
    final _$result =
        _$v ??
        new _$DefaultBuildResult._(
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'DefaultBuildResult',
            'status',
          ),
          target: BuiltValueNullFieldError.checkNotNull(
            target,
            r'DefaultBuildResult',
            'target',
          ),
          buildId: buildId,
          error: error,
          isCached: isCached,
        );
    replace(_$result);
    return _$result;
  }
}

class _$BuildResults extends BuildResults {
  @override
  final BuiltList<BuildResult> results;
  @override
  final BuiltList<Uri>? changedAssets;

  factory _$BuildResults([void Function(BuildResultsBuilder)? updates]) =>
      (new BuildResultsBuilder()..update(updates))._build();

  _$BuildResults._({required this.results, this.changedAssets}) : super._() {
    BuiltValueNullFieldError.checkNotNull(results, r'BuildResults', 'results');
  }

  @override
  BuildResults rebuild(void Function(BuildResultsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BuildResultsBuilder toBuilder() => new BuildResultsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BuildResults &&
        results == other.results &&
        changedAssets == other.changedAssets;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, results.hashCode);
    _$hash = $jc(_$hash, changedAssets.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BuildResults')
          ..add('results', results)
          ..add('changedAssets', changedAssets))
        .toString();
  }
}

class BuildResultsBuilder
    implements Builder<BuildResults, BuildResultsBuilder> {
  _$BuildResults? _$v;

  ListBuilder<BuildResult>? _results;
  ListBuilder<BuildResult> get results =>
      _$this._results ??= new ListBuilder<BuildResult>();
  set results(ListBuilder<BuildResult>? results) => _$this._results = results;

  ListBuilder<Uri>? _changedAssets;
  ListBuilder<Uri> get changedAssets =>
      _$this._changedAssets ??= new ListBuilder<Uri>();
  set changedAssets(ListBuilder<Uri>? changedAssets) =>
      _$this._changedAssets = changedAssets;

  BuildResultsBuilder();

  BuildResultsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _results = $v.results.toBuilder();
      _changedAssets = $v.changedAssets?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BuildResults other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$BuildResults;
  }

  @override
  void update(void Function(BuildResultsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BuildResults build() => _build();

  _$BuildResults _build() {
    _$BuildResults _$result;
    try {
      _$result =
          _$v ??
          new _$BuildResults._(
            results: results.build(),
            changedAssets: _changedAssets?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'results';
        results.build();
        _$failedField = 'changedAssets';
        _changedAssets?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'BuildResults',
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
