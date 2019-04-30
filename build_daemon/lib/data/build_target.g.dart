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
  Iterable serialize(Serializers serializers, DefaultBuildTarget object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'blackListPatterns',
      serializers.serialize(object.blackListPatterns,
          specifiedType:
              const FullType(BuiltSet, const [const FullType(RegExp)])),
      'target',
      serializers.serialize(object.target,
          specifiedType: const FullType(String)),
    ];
    if (object.outputLocation != null) {
      result
        ..add('outputLocation')
        ..add(serializers.serialize(object.outputLocation,
            specifiedType: const FullType(OutputLocation)));
    }

    return result;
  }

  @override
  DefaultBuildTarget deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new DefaultBuildTargetBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'blackListPatterns':
          result.blackListPatterns.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltSet, const [const FullType(RegExp)]))
              as BuiltSet);
          break;
        case 'outputLocation':
          result.outputLocation.replace(serializers.deserialize(value,
              specifiedType: const FullType(OutputLocation)) as OutputLocation);
          break;
        case 'target':
          result.target = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
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
  Iterable serialize(Serializers serializers, OutputLocation object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'output',
      serializers.serialize(object.output,
          specifiedType: const FullType(String)),
      'useSymlinks',
      serializers.serialize(object.useSymlinks,
          specifiedType: const FullType(bool)),
      'hoist',
      serializers.serialize(object.hoist, specifiedType: const FullType(bool)),
    ];

    return result;
  }

  @override
  OutputLocation deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new OutputLocationBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'output':
          result.output = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'useSymlinks':
          result.useSymlinks = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'hoist':
          result.hoist = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
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
  final OutputLocation outputLocation;
  @override
  final String target;

  factory _$DefaultBuildTarget([void updates(DefaultBuildTargetBuilder b)]) =>
      (new DefaultBuildTargetBuilder()..update(updates)).build();

  _$DefaultBuildTarget._(
      {this.blackListPatterns, this.outputLocation, this.target})
      : super._() {
    if (blackListPatterns == null) {
      throw new BuiltValueNullFieldError(
          'DefaultBuildTarget', 'blackListPatterns');
    }
    if (target == null) {
      throw new BuiltValueNullFieldError('DefaultBuildTarget', 'target');
    }
  }

  @override
  DefaultBuildTarget rebuild(void updates(DefaultBuildTargetBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  DefaultBuildTargetBuilder toBuilder() =>
      new DefaultBuildTargetBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DefaultBuildTarget &&
        blackListPatterns == other.blackListPatterns &&
        outputLocation == other.outputLocation &&
        target == other.target;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc(0, blackListPatterns.hashCode), outputLocation.hashCode),
        target.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('DefaultBuildTarget')
          ..add('blackListPatterns', blackListPatterns)
          ..add('outputLocation', outputLocation)
          ..add('target', target))
        .toString();
  }
}

class DefaultBuildTargetBuilder
    implements Builder<DefaultBuildTarget, DefaultBuildTargetBuilder> {
  _$DefaultBuildTarget _$v;

  SetBuilder<RegExp> _blackListPatterns;
  SetBuilder<RegExp> get blackListPatterns =>
      _$this._blackListPatterns ??= new SetBuilder<RegExp>();
  set blackListPatterns(SetBuilder<RegExp> blackListPatterns) =>
      _$this._blackListPatterns = blackListPatterns;

  OutputLocationBuilder _outputLocation;
  OutputLocationBuilder get outputLocation =>
      _$this._outputLocation ??= new OutputLocationBuilder();
  set outputLocation(OutputLocationBuilder outputLocation) =>
      _$this._outputLocation = outputLocation;

  String _target;
  String get target => _$this._target;
  set target(String target) => _$this._target = target;

  DefaultBuildTargetBuilder();

  DefaultBuildTargetBuilder get _$this {
    if (_$v != null) {
      _blackListPatterns = _$v.blackListPatterns?.toBuilder();
      _outputLocation = _$v.outputLocation?.toBuilder();
      _target = _$v.target;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DefaultBuildTarget other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$DefaultBuildTarget;
  }

  @override
  void update(void updates(DefaultBuildTargetBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$DefaultBuildTarget build() {
    _$DefaultBuildTarget _$result;
    try {
      _$result = _$v ??
          new _$DefaultBuildTarget._(
              blackListPatterns: blackListPatterns.build(),
              outputLocation: _outputLocation?.build(),
              target: target);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'blackListPatterns';
        blackListPatterns.build();
        _$failedField = 'outputLocation';
        _outputLocation?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'DefaultBuildTarget', _$failedField, e.toString());
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

  factory _$OutputLocation([void updates(OutputLocationBuilder b)]) =>
      (new OutputLocationBuilder()..update(updates)).build();

  _$OutputLocation._({this.output, this.useSymlinks, this.hoist}) : super._() {
    if (output == null) {
      throw new BuiltValueNullFieldError('OutputLocation', 'output');
    }
    if (useSymlinks == null) {
      throw new BuiltValueNullFieldError('OutputLocation', 'useSymlinks');
    }
    if (hoist == null) {
      throw new BuiltValueNullFieldError('OutputLocation', 'hoist');
    }
  }

  @override
  OutputLocation rebuild(void updates(OutputLocationBuilder b)) =>
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
    return $jf($jc(
        $jc($jc(0, output.hashCode), useSymlinks.hashCode), hoist.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('OutputLocation')
          ..add('output', output)
          ..add('useSymlinks', useSymlinks)
          ..add('hoist', hoist))
        .toString();
  }
}

class OutputLocationBuilder
    implements Builder<OutputLocation, OutputLocationBuilder> {
  _$OutputLocation _$v;

  String _output;
  String get output => _$this._output;
  set output(String output) => _$this._output = output;

  bool _useSymlinks;
  bool get useSymlinks => _$this._useSymlinks;
  set useSymlinks(bool useSymlinks) => _$this._useSymlinks = useSymlinks;

  bool _hoist;
  bool get hoist => _$this._hoist;
  set hoist(bool hoist) => _$this._hoist = hoist;

  OutputLocationBuilder();

  OutputLocationBuilder get _$this {
    if (_$v != null) {
      _output = _$v.output;
      _useSymlinks = _$v.useSymlinks;
      _hoist = _$v.hoist;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OutputLocation other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$OutputLocation;
  }

  @override
  void update(void updates(OutputLocationBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$OutputLocation build() {
    final _$result = _$v ??
        new _$OutputLocation._(
            output: output, useSymlinks: useSymlinks, hoist: hoist);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
