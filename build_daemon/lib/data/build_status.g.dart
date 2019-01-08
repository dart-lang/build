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

final BuiltSet<BuildStatus> _$values =
    new BuiltSet<BuildStatus>(const <BuildStatus>[
  _$started,
  _$succeeded,
  _$failed,
]);

Serializer<BuildStatus> _$buildStatusSerializer = new _$BuildStatusSerializer();
Serializer<BuildResult> _$buildResultSerializer = new _$BuildResultSerializer();
Serializer<BuildResults> _$buildResultsSerializer =
    new _$BuildResultsSerializer();

class _$BuildStatusSerializer implements PrimitiveSerializer<BuildStatus> {
  @override
  final Iterable<Type> types = const <Type>[BuildStatus];
  @override
  final String wireName = 'BuildStatus';

  @override
  Object serialize(Serializers serializers, BuildStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      object.name;

  @override
  BuildStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      BuildStatus.valueOf(serialized as String);
}

class _$BuildResultSerializer implements StructuredSerializer<BuildResult> {
  @override
  final Iterable<Type> types = const [BuildResult, _$BuildResult];
  @override
  final String wireName = 'BuildResult';

  @override
  Iterable serialize(Serializers serializers, BuildResult object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'status',
      serializers.serialize(object.status,
          specifiedType: const FullType(BuildStatus)),
      'target',
      serializers.serialize(object.target,
          specifiedType: const FullType(String)),
    ];
    if (object.buildId != null) {
      result
        ..add('buildId')
        ..add(serializers.serialize(object.buildId,
            specifiedType: const FullType(String)));
    }
    if (object.error != null) {
      result
        ..add('error')
        ..add(serializers.serialize(object.error,
            specifiedType: const FullType(String)));
    }
    if (object.isCached != null) {
      result
        ..add('isCached')
        ..add(serializers.serialize(object.isCached,
            specifiedType: const FullType(bool)));
    }
    if (object.builderDetails != null) {
      result
        ..add('builderDetails')
        ..add(serializers.serialize(object.builderDetails,
            specifiedType: const FullType(Object)));
    }

    return result;
  }

  @override
  BuildResult deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new BuildResultBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'status':
          result.status = serializers.deserialize(value,
              specifiedType: const FullType(BuildStatus)) as BuildStatus;
          break;
        case 'target':
          result.target = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'buildId':
          result.buildId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'error':
          result.error = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'isCached':
          result.isCached = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'builderDetails':
          result.builderDetails = serializers.deserialize(value,
              specifiedType: const FullType(Object));
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
  Iterable serialize(Serializers serializers, BuildResults object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'results',
      serializers.serialize(object.results,
          specifiedType:
              const FullType(BuiltList, const [const FullType(BuildResult)])),
    ];

    return result;
  }

  @override
  BuildResults deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new BuildResultsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'results':
          result.results.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(BuildResult)]))
              as BuiltList);
          break;
      }
    }

    return result.build();
  }
}

class _$BuildResult extends BuildResult {
  @override
  final BuildStatus status;
  @override
  final String target;
  @override
  final String buildId;
  @override
  final String error;
  @override
  final bool isCached;
  @override
  final Object builderDetails;

  factory _$BuildResult([void updates(BuildResultBuilder b)]) =>
      (new BuildResultBuilder()..update(updates)).build();

  _$BuildResult._(
      {this.status,
      this.target,
      this.buildId,
      this.error,
      this.isCached,
      this.builderDetails})
      : super._() {
    if (status == null) {
      throw new BuiltValueNullFieldError('BuildResult', 'status');
    }
    if (target == null) {
      throw new BuiltValueNullFieldError('BuildResult', 'target');
    }
  }

  @override
  BuildResult rebuild(void updates(BuildResultBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  BuildResultBuilder toBuilder() => new BuildResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BuildResult &&
        status == other.status &&
        target == other.target &&
        buildId == other.buildId &&
        error == other.error &&
        isCached == other.isCached &&
        builderDetails == other.builderDetails;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc($jc($jc(0, status.hashCode), target.hashCode),
                    buildId.hashCode),
                error.hashCode),
            isCached.hashCode),
        builderDetails.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('BuildResult')
          ..add('status', status)
          ..add('target', target)
          ..add('buildId', buildId)
          ..add('error', error)
          ..add('isCached', isCached)
          ..add('builderDetails', builderDetails))
        .toString();
  }
}

class BuildResultBuilder implements Builder<BuildResult, BuildResultBuilder> {
  _$BuildResult _$v;

  BuildStatus _status;
  BuildStatus get status => _$this._status;
  set status(BuildStatus status) => _$this._status = status;

  String _target;
  String get target => _$this._target;
  set target(String target) => _$this._target = target;

  String _buildId;
  String get buildId => _$this._buildId;
  set buildId(String buildId) => _$this._buildId = buildId;

  String _error;
  String get error => _$this._error;
  set error(String error) => _$this._error = error;

  bool _isCached;
  bool get isCached => _$this._isCached;
  set isCached(bool isCached) => _$this._isCached = isCached;

  Object _builderDetails;
  Object get builderDetails => _$this._builderDetails;
  set builderDetails(Object builderDetails) =>
      _$this._builderDetails = builderDetails;

  BuildResultBuilder();

  BuildResultBuilder get _$this {
    if (_$v != null) {
      _status = _$v.status;
      _target = _$v.target;
      _buildId = _$v.buildId;
      _error = _$v.error;
      _isCached = _$v.isCached;
      _builderDetails = _$v.builderDetails;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BuildResult other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$BuildResult;
  }

  @override
  void update(void updates(BuildResultBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$BuildResult build() {
    final _$result = _$v ??
        new _$BuildResult._(
            status: status,
            target: target,
            buildId: buildId,
            error: error,
            isCached: isCached,
            builderDetails: builderDetails);
    replace(_$result);
    return _$result;
  }
}

class _$BuildResults extends BuildResults {
  @override
  final BuiltList<BuildResult> results;

  factory _$BuildResults([void updates(BuildResultsBuilder b)]) =>
      (new BuildResultsBuilder()..update(updates)).build();

  _$BuildResults._({this.results}) : super._() {
    if (results == null) {
      throw new BuiltValueNullFieldError('BuildResults', 'results');
    }
  }

  @override
  BuildResults rebuild(void updates(BuildResultsBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  BuildResultsBuilder toBuilder() => new BuildResultsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BuildResults && results == other.results;
  }

  @override
  int get hashCode {
    return $jf($jc(0, results.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('BuildResults')
          ..add('results', results))
        .toString();
  }
}

class BuildResultsBuilder
    implements Builder<BuildResults, BuildResultsBuilder> {
  _$BuildResults _$v;

  ListBuilder<BuildResult> _results;
  ListBuilder<BuildResult> get results =>
      _$this._results ??= new ListBuilder<BuildResult>();
  set results(ListBuilder<BuildResult> results) => _$this._results = results;

  BuildResultsBuilder();

  BuildResultsBuilder get _$this {
    if (_$v != null) {
      _results = _$v.results?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BuildResults other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$BuildResults;
  }

  @override
  void update(void updates(BuildResultsBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$BuildResults build() {
    _$BuildResults _$result;
    try {
      _$result = _$v ?? new _$BuildResults._(results: results.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'results';
        results.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'BuildResults', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
