// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_log_configuration.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BuildLogConfiguration extends BuildLogConfiguration {
  @override
  final BuildLogMode mode;
  @override
  final bool verbose;
  @override
  final void Function(LogRecord)? onLog;
  @override
  final String? singleOutputPackage;
  @override
  final bool throttleProgressUpdates;
  @override
  final void Function(String)? printOnFailure;
  @override
  final bool? forceAnsiConsoleForTesting;
  @override
  final int? forceConsoleWidthForTesting;

  factory _$BuildLogConfiguration([
    void Function(BuildLogConfigurationBuilder)? updates,
  ]) => (BuildLogConfigurationBuilder()..update(updates))._build();

  _$BuildLogConfiguration._({
    required this.mode,
    required this.verbose,
    this.onLog,
    this.singleOutputPackage,
    required this.throttleProgressUpdates,
    this.printOnFailure,
    this.forceAnsiConsoleForTesting,
    this.forceConsoleWidthForTesting,
  }) : super._();
  @override
  BuildLogConfiguration rebuild(
    void Function(BuildLogConfigurationBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  BuildLogConfigurationBuilder toBuilder() =>
      BuildLogConfigurationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    final dynamic _$dynamicOther = other;
    return other is BuildLogConfiguration &&
        mode == other.mode &&
        verbose == other.verbose &&
        onLog == _$dynamicOther.onLog &&
        singleOutputPackage == other.singleOutputPackage &&
        throttleProgressUpdates == other.throttleProgressUpdates &&
        printOnFailure == _$dynamicOther.printOnFailure &&
        forceAnsiConsoleForTesting == other.forceAnsiConsoleForTesting &&
        forceConsoleWidthForTesting == other.forceConsoleWidthForTesting;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, mode.hashCode);
    _$hash = $jc(_$hash, verbose.hashCode);
    _$hash = $jc(_$hash, onLog.hashCode);
    _$hash = $jc(_$hash, singleOutputPackage.hashCode);
    _$hash = $jc(_$hash, throttleProgressUpdates.hashCode);
    _$hash = $jc(_$hash, printOnFailure.hashCode);
    _$hash = $jc(_$hash, forceAnsiConsoleForTesting.hashCode);
    _$hash = $jc(_$hash, forceConsoleWidthForTesting.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BuildLogConfiguration')
          ..add('mode', mode)
          ..add('verbose', verbose)
          ..add('onLog', onLog)
          ..add('singleOutputPackage', singleOutputPackage)
          ..add('throttleProgressUpdates', throttleProgressUpdates)
          ..add('printOnFailure', printOnFailure)
          ..add('forceAnsiConsoleForTesting', forceAnsiConsoleForTesting)
          ..add('forceConsoleWidthForTesting', forceConsoleWidthForTesting))
        .toString();
  }
}

class BuildLogConfigurationBuilder
    implements Builder<BuildLogConfiguration, BuildLogConfigurationBuilder> {
  _$BuildLogConfiguration? _$v;

  BuildLogMode? _mode;
  BuildLogMode? get mode => _$this._mode;
  set mode(BuildLogMode? mode) => _$this._mode = mode;

  bool? _verbose;
  bool? get verbose => _$this._verbose;
  set verbose(bool? verbose) => _$this._verbose = verbose;

  void Function(LogRecord)? _onLog;
  void Function(LogRecord)? get onLog => _$this._onLog;
  set onLog(void Function(LogRecord)? onLog) => _$this._onLog = onLog;

  String? _singleOutputPackage;
  String? get singleOutputPackage => _$this._singleOutputPackage;
  set singleOutputPackage(String? singleOutputPackage) =>
      _$this._singleOutputPackage = singleOutputPackage;

  bool? _throttleProgressUpdates;
  bool? get throttleProgressUpdates => _$this._throttleProgressUpdates;
  set throttleProgressUpdates(bool? throttleProgressUpdates) =>
      _$this._throttleProgressUpdates = throttleProgressUpdates;

  void Function(String)? _printOnFailure;
  void Function(String)? get printOnFailure => _$this._printOnFailure;
  set printOnFailure(void Function(String)? printOnFailure) =>
      _$this._printOnFailure = printOnFailure;

  bool? _forceAnsiConsoleForTesting;
  bool? get forceAnsiConsoleForTesting => _$this._forceAnsiConsoleForTesting;
  set forceAnsiConsoleForTesting(bool? forceAnsiConsoleForTesting) =>
      _$this._forceAnsiConsoleForTesting = forceAnsiConsoleForTesting;

  int? _forceConsoleWidthForTesting;
  int? get forceConsoleWidthForTesting => _$this._forceConsoleWidthForTesting;
  set forceConsoleWidthForTesting(int? forceConsoleWidthForTesting) =>
      _$this._forceConsoleWidthForTesting = forceConsoleWidthForTesting;

  BuildLogConfigurationBuilder();

  BuildLogConfigurationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _mode = $v.mode;
      _verbose = $v.verbose;
      _onLog = $v.onLog;
      _singleOutputPackage = $v.singleOutputPackage;
      _throttleProgressUpdates = $v.throttleProgressUpdates;
      _printOnFailure = $v.printOnFailure;
      _forceAnsiConsoleForTesting = $v.forceAnsiConsoleForTesting;
      _forceConsoleWidthForTesting = $v.forceConsoleWidthForTesting;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BuildLogConfiguration other) {
    _$v = other as _$BuildLogConfiguration;
  }

  @override
  void update(void Function(BuildLogConfigurationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BuildLogConfiguration build() => _build();

  _$BuildLogConfiguration _build() {
    final _$result =
        _$v ??
        _$BuildLogConfiguration._(
          mode: BuiltValueNullFieldError.checkNotNull(
            mode,
            r'BuildLogConfiguration',
            'mode',
          ),
          verbose: BuiltValueNullFieldError.checkNotNull(
            verbose,
            r'BuildLogConfiguration',
            'verbose',
          ),
          onLog: onLog,
          singleOutputPackage: singleOutputPackage,
          throttleProgressUpdates: BuiltValueNullFieldError.checkNotNull(
            throttleProgressUpdates,
            r'BuildLogConfiguration',
            'throttleProgressUpdates',
          ),
          printOnFailure: printOnFailure,
          forceAnsiConsoleForTesting: forceAnsiConsoleForTesting,
          forceConsoleWidthForTesting: forceConsoleWidthForTesting,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
