// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_log_configuration.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BuildLogConfiguration extends BuildLogConfiguration {
  @override
  final bool verbose;
  @override
  final void Function(LogRecord)? onLog;

  factory _$BuildLogConfiguration([
    void Function(BuildLogConfigurationBuilder)? updates,
  ]) => (BuildLogConfigurationBuilder()..update(updates))._build();

  _$BuildLogConfiguration._({required this.verbose, this.onLog}) : super._();
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
        verbose == other.verbose &&
        onLog == _$dynamicOther.onLog;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, verbose.hashCode);
    _$hash = $jc(_$hash, onLog.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BuildLogConfiguration')
          ..add('verbose', verbose)
          ..add('onLog', onLog))
        .toString();
  }
}

class BuildLogConfigurationBuilder
    implements Builder<BuildLogConfiguration, BuildLogConfigurationBuilder> {
  _$BuildLogConfiguration? _$v;

  bool? _verbose;
  bool? get verbose => _$this._verbose;
  set verbose(bool? verbose) => _$this._verbose = verbose;

  void Function(LogRecord)? _onLog;
  void Function(LogRecord)? get onLog => _$this._onLog;
  set onLog(void Function(LogRecord)? onLog) => _$this._onLog = onLog;

  BuildLogConfigurationBuilder();

  BuildLogConfigurationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _verbose = $v.verbose;
      _onLog = $v.onLog;
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
          verbose: BuiltValueNullFieldError.checkNotNull(
            verbose,
            r'BuildLogConfiguration',
            'verbose',
          ),
          onLog: onLog,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
