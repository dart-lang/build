// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_target.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<DefaultBuildTarget> _$defaultBuildTargetSerializer =
    new _$DefaultBuildTargetSerializer();
Serializer<OutputLocation> _$outputLocationSerializer =
    new _$OutputLocationSerializer();

class _$DefaultBuildTargetSerializer
    implements StructuredSerializer<DefaultBuildTarget> {
  @override
  final Iterable<Type> types = const [DefaultBuildTarget, _$DefaultBuildTarget];
  @override
  final String wireName = 'DefaultBuildTarget';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    DefaultBuildTarget object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'blackListPatterns',
      serializers.serialize(
        object.blackListPatterns,
        specifiedType: const FullType(BuiltSet, const [const FullType(RegExp)]),
      ),
      'reportChangedAssets',
      serializers.serialize(
        object.reportChangedAssets,
        specifiedType: const FullType(bool),
      ),
      'target',
      serializers.serialize(
        object.target,
        specifiedType: const FullType(String),
      ),
    ];
    Object? value;
    value = object.outputLocation;
    if (value != null) {
      result
        ..add('outputLocation')
        ..add(
          serializers.serialize(
            value,
            specifiedType: const FullType(OutputLocation),
          ),
        );
    }
    value = object.buildFilters;
    if (value != null) {
      result
        ..add('buildFilters')
        ..add(
          serializers.serialize(
            value,
            specifiedType: const FullType(BuiltSet, const [
              const FullType(String),
            ]),
          ),
        );
    }
    return result;
  }

  @override
  DefaultBuildTarget deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new DefaultBuildTargetBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'blackListPatterns':
          result.blackListPatterns.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltSet, const [
                    const FullType(RegExp),
                  ]),
                )!
                as BuiltSet<Object?>,
          );
          break;
        case 'outputLocation':
          result.outputLocation.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(OutputLocation),
                )!
                as OutputLocation,
          );
          break;
        case 'buildFilters':
          result.buildFilters.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltSet, const [
                    const FullType(String),
                  ]),
                )!
                as BuiltSet<Object?>,
          );
          break;
        case 'reportChangedAssets':
          result.reportChangedAssets =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )!
                  as bool;
          break;
        case 'target':
          result.target =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )!
                  as String;
          break;
      }
    }

    return result.build();
  }
}

class _$OutputLocationSerializer
    implements StructuredSerializer<OutputLocation> {
  @override
  final Iterable<Type> types = const [OutputLocation, _$OutputLocation];
  @override
  final String wireName = 'OutputLocation';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    OutputLocation object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'output',
      serializers.serialize(
        object.output,
        specifiedType: const FullType(String),
      ),
      'useSymlinks',
      serializers.serialize(
        object.useSymlinks,
        specifiedType: const FullType(bool),
      ),
      'hoist',
      serializers.serialize(object.hoist, specifiedType: const FullType(bool)),
    ];

    return result;
  }

  @override
  OutputLocation deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new OutputLocationBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'output':
          result.output =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )!
                  as String;
          break;
        case 'useSymlinks':
          result.useSymlinks =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )!
                  as bool;
          break;
        case 'hoist':
          result.hoist =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )!
                  as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$DefaultBuildTarget extends DefaultBuildTarget {
  @override
  final BuiltSet<RegExp> blackListPatterns;
  @override
  final OutputLocation? outputLocation;
  @override
  final BuiltSet<String>? buildFilters;
  @override
  final bool reportChangedAssets;
  @override
  final String target;

  factory _$DefaultBuildTarget([
    void Function(DefaultBuildTargetBuilder)? updates,
  ]) => (new DefaultBuildTargetBuilder()..update(updates))._build();

  _$DefaultBuildTarget._({
    required this.blackListPatterns,
    this.outputLocation,
    this.buildFilters,
    required this.reportChangedAssets,
    required this.target,
  }) : super._() {
    BuiltValueNullFieldError.checkNotNull(
      blackListPatterns,
      r'DefaultBuildTarget',
      'blackListPatterns',
    );
    BuiltValueNullFieldError.checkNotNull(
      reportChangedAssets,
      r'DefaultBuildTarget',
      'reportChangedAssets',
    );
    BuiltValueNullFieldError.checkNotNull(
      target,
      r'DefaultBuildTarget',
      'target',
    );
  }

  @override
  DefaultBuildTarget rebuild(
    void Function(DefaultBuildTargetBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DefaultBuildTargetBuilder toBuilder() =>
      new DefaultBuildTargetBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DefaultBuildTarget &&
        blackListPatterns == other.blackListPatterns &&
        outputLocation == other.outputLocation &&
        buildFilters == other.buildFilters &&
        reportChangedAssets == other.reportChangedAssets &&
        target == other.target;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, blackListPatterns.hashCode);
    _$hash = $jc(_$hash, outputLocation.hashCode);
    _$hash = $jc(_$hash, buildFilters.hashCode);
    _$hash = $jc(_$hash, reportChangedAssets.hashCode);
    _$hash = $jc(_$hash, target.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DefaultBuildTarget')
          ..add('blackListPatterns', blackListPatterns)
          ..add('outputLocation', outputLocation)
          ..add('buildFilters', buildFilters)
          ..add('reportChangedAssets', reportChangedAssets)
          ..add('target', target))
        .toString();
  }
}

class DefaultBuildTargetBuilder
    implements Builder<DefaultBuildTarget, DefaultBuildTargetBuilder> {
  _$DefaultBuildTarget? _$v;

  SetBuilder<RegExp>? _blackListPatterns;
  SetBuilder<RegExp> get blackListPatterns =>
      _$this._blackListPatterns ??= new SetBuilder<RegExp>();
  set blackListPatterns(SetBuilder<RegExp>? blackListPatterns) =>
      _$this._blackListPatterns = blackListPatterns;

  OutputLocationBuilder? _outputLocation;
  OutputLocationBuilder get outputLocation =>
      _$this._outputLocation ??= new OutputLocationBuilder();
  set outputLocation(OutputLocationBuilder? outputLocation) =>
      _$this._outputLocation = outputLocation;

  SetBuilder<String>? _buildFilters;
  SetBuilder<String> get buildFilters =>
      _$this._buildFilters ??= new SetBuilder<String>();
  set buildFilters(SetBuilder<String>? buildFilters) =>
      _$this._buildFilters = buildFilters;

  bool? _reportChangedAssets;
  bool? get reportChangedAssets => _$this._reportChangedAssets;
  set reportChangedAssets(bool? reportChangedAssets) =>
      _$this._reportChangedAssets = reportChangedAssets;

  String? _target;
  String? get target => _$this._target;
  set target(String? target) => _$this._target = target;

  DefaultBuildTargetBuilder() {
    DefaultBuildTarget._setDefaults(this);
  }

  DefaultBuildTargetBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _blackListPatterns = $v.blackListPatterns.toBuilder();
      _outputLocation = $v.outputLocation?.toBuilder();
      _buildFilters = $v.buildFilters?.toBuilder();
      _reportChangedAssets = $v.reportChangedAssets;
      _target = $v.target;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DefaultBuildTarget other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$DefaultBuildTarget;
  }

  @override
  void update(void Function(DefaultBuildTargetBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DefaultBuildTarget build() => _build();

  _$DefaultBuildTarget _build() {
    _$DefaultBuildTarget _$result;
    try {
      _$result =
          _$v ??
          new _$DefaultBuildTarget._(
            blackListPatterns: blackListPatterns.build(),
            outputLocation: _outputLocation?.build(),
            buildFilters: _buildFilters?.build(),
            reportChangedAssets: BuiltValueNullFieldError.checkNotNull(
              reportChangedAssets,
              r'DefaultBuildTarget',
              'reportChangedAssets',
            ),
            target: BuiltValueNullFieldError.checkNotNull(
              target,
              r'DefaultBuildTarget',
              'target',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'blackListPatterns';
        blackListPatterns.build();
        _$failedField = 'outputLocation';
        _outputLocation?.build();
        _$failedField = 'buildFilters';
        _buildFilters?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'DefaultBuildTarget',
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

class _$OutputLocation extends OutputLocation {
  @override
  final String output;
  @override
  final bool useSymlinks;
  @override
  final bool hoist;

  factory _$OutputLocation([void Function(OutputLocationBuilder)? updates]) =>
      (new OutputLocationBuilder()..update(updates))._build();

  _$OutputLocation._({
    required this.output,
    required this.useSymlinks,
    required this.hoist,
  }) : super._() {
    BuiltValueNullFieldError.checkNotNull(output, r'OutputLocation', 'output');
    BuiltValueNullFieldError.checkNotNull(
      useSymlinks,
      r'OutputLocation',
      'useSymlinks',
    );
    BuiltValueNullFieldError.checkNotNull(hoist, r'OutputLocation', 'hoist');
  }

  @override
  OutputLocation rebuild(void Function(OutputLocationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OutputLocationBuilder toBuilder() =>
      new OutputLocationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OutputLocation &&
        output == other.output &&
        useSymlinks == other.useSymlinks &&
        hoist == other.hoist;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, output.hashCode);
    _$hash = $jc(_$hash, useSymlinks.hashCode);
    _$hash = $jc(_$hash, hoist.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OutputLocation')
          ..add('output', output)
          ..add('useSymlinks', useSymlinks)
          ..add('hoist', hoist))
        .toString();
  }
}

class OutputLocationBuilder
    implements Builder<OutputLocation, OutputLocationBuilder> {
  _$OutputLocation? _$v;

  String? _output;
  String? get output => _$this._output;
  set output(String? output) => _$this._output = output;

  bool? _useSymlinks;
  bool? get useSymlinks => _$this._useSymlinks;
  set useSymlinks(bool? useSymlinks) => _$this._useSymlinks = useSymlinks;

  bool? _hoist;
  bool? get hoist => _$this._hoist;
  set hoist(bool? hoist) => _$this._hoist = hoist;

  OutputLocationBuilder();

  OutputLocationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _output = $v.output;
      _useSymlinks = $v.useSymlinks;
      _hoist = $v.hoist;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OutputLocation other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$OutputLocation;
  }

  @override
  void update(void Function(OutputLocationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OutputLocation build() => _build();

  _$OutputLocation _build() {
    final _$result =
        _$v ??
        new _$OutputLocation._(
          output: BuiltValueNullFieldError.checkNotNull(
            output,
            r'OutputLocation',
            'output',
          ),
          useSymlinks: BuiltValueNullFieldError.checkNotNull(
            useSymlinks,
            r'OutputLocation',
            'useSymlinks',
          ),
          hoist: BuiltValueNullFieldError.checkNotNull(
            hoist,
            r'OutputLocation',
            'hoist',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
