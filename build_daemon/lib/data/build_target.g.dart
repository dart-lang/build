// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_target.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<DefaultBuildTarget> _$defaultBuildTargetSerializer =
    new _$DefaultBuildTargetSerializer();

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
    if (object.output != null) {
      result
        ..add('output')
        ..add(serializers.serialize(object.output,
            specifiedType: const FullType(String)));
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
        case 'output':
          result.output = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
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

class _$DefaultBuildTarget extends DefaultBuildTarget {
  @override
  final BuiltSet<RegExp> blackListPatterns;
  @override
  final String output;
  @override
  final String target;

  factory _$DefaultBuildTarget([void updates(DefaultBuildTargetBuilder b)]) =>
      (new DefaultBuildTargetBuilder()..update(updates)).build();

  _$DefaultBuildTarget._({this.blackListPatterns, this.output, this.target})
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
        output == other.output &&
        target == other.target;
  }

  @override
  int get hashCode {
    return $jf($jc($jc($jc(0, blackListPatterns.hashCode), output.hashCode),
        target.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('DefaultBuildTarget')
          ..add('blackListPatterns', blackListPatterns)
          ..add('output', output)
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

  String _output;
  String get output => _$this._output;
  set output(String output) => _$this._output = output;

  String _target;
  String get target => _$this._target;
  set target(String target) => _$this._target = target;

  DefaultBuildTargetBuilder();

  DefaultBuildTargetBuilder get _$this {
    if (_$v != null) {
      _blackListPatterns = _$v.blackListPatterns?.toBuilder();
      _output = _$v.output;
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
              output: output,
              target: target);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'blackListPatterns';
        blackListPatterns.build();
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

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
