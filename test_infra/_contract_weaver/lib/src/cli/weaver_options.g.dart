// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weaver_options.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$WeaverOptions extends WeaverOptions {
  @override
  final bool help;
  @override
  final bool clean;
  @override
  final bool analyzeOnly;
  @override
  final String? stageDir;
  @override
  final String? package;
  @override
  final BuiltList<ContractImportRule> importRules;
  @override
  final BuiltList<String> testArgs;

  factory _$WeaverOptions([void Function(WeaverOptionsBuilder)? updates]) =>
      (WeaverOptionsBuilder()..update(updates))._build();

  _$WeaverOptions._({
    required this.help,
    required this.clean,
    required this.analyzeOnly,
    this.stageDir,
    this.package,
    required this.importRules,
    required this.testArgs,
  }) : super._();
  @override
  WeaverOptions rebuild(void Function(WeaverOptionsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WeaverOptionsBuilder toBuilder() => WeaverOptionsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WeaverOptions &&
        help == other.help &&
        clean == other.clean &&
        analyzeOnly == other.analyzeOnly &&
        stageDir == other.stageDir &&
        package == other.package &&
        importRules == other.importRules &&
        testArgs == other.testArgs;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, help.hashCode);
    _$hash = $jc(_$hash, clean.hashCode);
    _$hash = $jc(_$hash, analyzeOnly.hashCode);
    _$hash = $jc(_$hash, stageDir.hashCode);
    _$hash = $jc(_$hash, package.hashCode);
    _$hash = $jc(_$hash, importRules.hashCode);
    _$hash = $jc(_$hash, testArgs.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'WeaverOptions')
          ..add('help', help)
          ..add('clean', clean)
          ..add('analyzeOnly', analyzeOnly)
          ..add('stageDir', stageDir)
          ..add('package', package)
          ..add('importRules', importRules)
          ..add('testArgs', testArgs))
        .toString();
  }
}

class WeaverOptionsBuilder
    implements Builder<WeaverOptions, WeaverOptionsBuilder> {
  _$WeaverOptions? _$v;

  bool? _help;
  bool? get help => _$this._help;
  set help(bool? help) => _$this._help = help;

  bool? _clean;
  bool? get clean => _$this._clean;
  set clean(bool? clean) => _$this._clean = clean;

  bool? _analyzeOnly;
  bool? get analyzeOnly => _$this._analyzeOnly;
  set analyzeOnly(bool? analyzeOnly) => _$this._analyzeOnly = analyzeOnly;

  String? _stageDir;
  String? get stageDir => _$this._stageDir;
  set stageDir(String? stageDir) => _$this._stageDir = stageDir;

  String? _package;
  String? get package => _$this._package;
  set package(String? package) => _$this._package = package;

  ListBuilder<ContractImportRule>? _importRules;
  ListBuilder<ContractImportRule> get importRules =>
      _$this._importRules ??= ListBuilder<ContractImportRule>();
  set importRules(ListBuilder<ContractImportRule>? importRules) =>
      _$this._importRules = importRules;

  ListBuilder<String>? _testArgs;
  ListBuilder<String> get testArgs =>
      _$this._testArgs ??= ListBuilder<String>();
  set testArgs(ListBuilder<String>? testArgs) => _$this._testArgs = testArgs;

  WeaverOptionsBuilder();

  WeaverOptionsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _help = $v.help;
      _clean = $v.clean;
      _analyzeOnly = $v.analyzeOnly;
      _stageDir = $v.stageDir;
      _package = $v.package;
      _importRules = $v.importRules.toBuilder();
      _testArgs = $v.testArgs.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WeaverOptions other) {
    _$v = other as _$WeaverOptions;
  }

  @override
  void update(void Function(WeaverOptionsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WeaverOptions build() => _build();

  _$WeaverOptions _build() {
    _$WeaverOptions _$result;
    try {
      _$result =
          _$v ??
          _$WeaverOptions._(
            help: BuiltValueNullFieldError.checkNotNull(
              help,
              r'WeaverOptions',
              'help',
            ),
            clean: BuiltValueNullFieldError.checkNotNull(
              clean,
              r'WeaverOptions',
              'clean',
            ),
            analyzeOnly: BuiltValueNullFieldError.checkNotNull(
              analyzeOnly,
              r'WeaverOptions',
              'analyzeOnly',
            ),
            stageDir: stageDir,
            package: package,
            importRules: importRules.build(),
            testArgs: testArgs.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'importRules';
        importRules.build();
        _$failedField = 'testArgs';
        testArgs.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'WeaverOptions',
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
