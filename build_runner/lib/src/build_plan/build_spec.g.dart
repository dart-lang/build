// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_spec.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BuildSpec extends BuildSpec {
  @override
  final BuildSpecDigest buildPlanDigest;
  @override
  final BuilderFactories builderFactories;
  @override
  final BuildOptions buildOptions;
  @override
  final TestingOverrides testingOverrides;
  @override
  final Bootstrapper bootstrapper;
  @override
  final BuildPackages buildPackages;
  @override
  final BuildConfigs buildConfigs;
  @override
  final BuildPhases buildPhases;
  @override
  final ReaderWriter readerWriter;
  @override
  final bool restartIsNeeded;

  factory _$BuildSpec([void Function(BuildSpecBuilder)? updates]) =>
      (BuildSpecBuilder()..update(updates))._build();

  _$BuildSpec._({
    required this.buildPlanDigest,
    required this.builderFactories,
    required this.buildOptions,
    required this.testingOverrides,
    required this.bootstrapper,
    required this.buildPackages,
    required this.buildConfigs,
    required this.buildPhases,
    required this.readerWriter,
    required this.restartIsNeeded,
  }) : super._();
  @override
  BuildSpec rebuild(void Function(BuildSpecBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BuildSpecBuilder toBuilder() => BuildSpecBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BuildSpec &&
        buildPlanDigest == other.buildPlanDigest &&
        builderFactories == other.builderFactories &&
        buildOptions == other.buildOptions &&
        testingOverrides == other.testingOverrides &&
        bootstrapper == other.bootstrapper &&
        buildPackages == other.buildPackages &&
        buildConfigs == other.buildConfigs &&
        buildPhases == other.buildPhases &&
        readerWriter == other.readerWriter &&
        restartIsNeeded == other.restartIsNeeded;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, buildPlanDigest.hashCode);
    _$hash = $jc(_$hash, builderFactories.hashCode);
    _$hash = $jc(_$hash, buildOptions.hashCode);
    _$hash = $jc(_$hash, testingOverrides.hashCode);
    _$hash = $jc(_$hash, bootstrapper.hashCode);
    _$hash = $jc(_$hash, buildPackages.hashCode);
    _$hash = $jc(_$hash, buildConfigs.hashCode);
    _$hash = $jc(_$hash, buildPhases.hashCode);
    _$hash = $jc(_$hash, readerWriter.hashCode);
    _$hash = $jc(_$hash, restartIsNeeded.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BuildSpec')
          ..add('buildPlanDigest', buildPlanDigest)
          ..add('builderFactories', builderFactories)
          ..add('buildOptions', buildOptions)
          ..add('testingOverrides', testingOverrides)
          ..add('bootstrapper', bootstrapper)
          ..add('buildPackages', buildPackages)
          ..add('buildConfigs', buildConfigs)
          ..add('buildPhases', buildPhases)
          ..add('readerWriter', readerWriter)
          ..add('restartIsNeeded', restartIsNeeded))
        .toString();
  }
}

class BuildSpecBuilder implements Builder<BuildSpec, BuildSpecBuilder> {
  _$BuildSpec? _$v;

  BuildSpecDigestBuilder? _buildPlanDigest;
  BuildSpecDigestBuilder get buildPlanDigest =>
      _$this._buildPlanDigest ??= BuildSpecDigestBuilder();
  set buildPlanDigest(BuildSpecDigestBuilder? buildPlanDigest) =>
      _$this._buildPlanDigest = buildPlanDigest;

  BuilderFactories? _builderFactories;
  BuilderFactories? get builderFactories => _$this._builderFactories;
  set builderFactories(BuilderFactories? builderFactories) =>
      _$this._builderFactories = builderFactories;

  BuildOptions? _buildOptions;
  BuildOptions? get buildOptions => _$this._buildOptions;
  set buildOptions(BuildOptions? buildOptions) =>
      _$this._buildOptions = buildOptions;

  TestingOverrides? _testingOverrides;
  TestingOverrides? get testingOverrides => _$this._testingOverrides;
  set testingOverrides(TestingOverrides? testingOverrides) =>
      _$this._testingOverrides = testingOverrides;

  Bootstrapper? _bootstrapper;
  Bootstrapper? get bootstrapper => _$this._bootstrapper;
  set bootstrapper(Bootstrapper? bootstrapper) =>
      _$this._bootstrapper = bootstrapper;

  BuildPackages? _buildPackages;
  BuildPackages? get buildPackages => _$this._buildPackages;
  set buildPackages(BuildPackages? buildPackages) =>
      _$this._buildPackages = buildPackages;

  BuildConfigs? _buildConfigs;
  BuildConfigs? get buildConfigs => _$this._buildConfigs;
  set buildConfigs(BuildConfigs? buildConfigs) =>
      _$this._buildConfigs = buildConfigs;

  BuildPhases? _buildPhases;
  BuildPhases? get buildPhases => _$this._buildPhases;
  set buildPhases(BuildPhases? buildPhases) =>
      _$this._buildPhases = buildPhases;

  ReaderWriter? _readerWriter;
  ReaderWriter? get readerWriter => _$this._readerWriter;
  set readerWriter(ReaderWriter? readerWriter) =>
      _$this._readerWriter = readerWriter;

  bool? _restartIsNeeded;
  bool? get restartIsNeeded => _$this._restartIsNeeded;
  set restartIsNeeded(bool? restartIsNeeded) =>
      _$this._restartIsNeeded = restartIsNeeded;

  BuildSpecBuilder();

  BuildSpecBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _buildPlanDigest = $v.buildPlanDigest.toBuilder();
      _builderFactories = $v.builderFactories;
      _buildOptions = $v.buildOptions;
      _testingOverrides = $v.testingOverrides;
      _bootstrapper = $v.bootstrapper;
      _buildPackages = $v.buildPackages;
      _buildConfigs = $v.buildConfigs;
      _buildPhases = $v.buildPhases;
      _readerWriter = $v.readerWriter;
      _restartIsNeeded = $v.restartIsNeeded;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BuildSpec other) {
    _$v = other as _$BuildSpec;
  }

  @override
  void update(void Function(BuildSpecBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BuildSpec build() => _build();

  _$BuildSpec _build() {
    _$BuildSpec _$result;
    try {
      _$result =
          _$v ??
          _$BuildSpec._(
            buildPlanDigest: buildPlanDigest.build(),
            builderFactories: BuiltValueNullFieldError.checkNotNull(
              builderFactories,
              r'BuildSpec',
              'builderFactories',
            ),
            buildOptions: BuiltValueNullFieldError.checkNotNull(
              buildOptions,
              r'BuildSpec',
              'buildOptions',
            ),
            testingOverrides: BuiltValueNullFieldError.checkNotNull(
              testingOverrides,
              r'BuildSpec',
              'testingOverrides',
            ),
            bootstrapper: BuiltValueNullFieldError.checkNotNull(
              bootstrapper,
              r'BuildSpec',
              'bootstrapper',
            ),
            buildPackages: BuiltValueNullFieldError.checkNotNull(
              buildPackages,
              r'BuildSpec',
              'buildPackages',
            ),
            buildConfigs: BuiltValueNullFieldError.checkNotNull(
              buildConfigs,
              r'BuildSpec',
              'buildConfigs',
            ),
            buildPhases: BuiltValueNullFieldError.checkNotNull(
              buildPhases,
              r'BuildSpec',
              'buildPhases',
            ),
            readerWriter: BuiltValueNullFieldError.checkNotNull(
              readerWriter,
              r'BuildSpec',
              'readerWriter',
            ),
            restartIsNeeded: BuiltValueNullFieldError.checkNotNull(
              restartIsNeeded,
              r'BuildSpec',
              'restartIsNeeded',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'buildPlanDigest';
        buildPlanDigest.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'BuildSpec',
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
