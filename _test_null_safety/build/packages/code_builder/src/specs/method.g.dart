// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'method.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Method extends Method {
  @override
  final BuiltList<Expression> annotations;
  @override
  final BuiltList<String> docs;
  @override
  final BuiltList<Reference> types;
  @override
  final BuiltList<Parameter> optionalParameters;
  @override
  final BuiltList<Parameter> requiredParameters;
  @override
  final Code? body;
  @override
  final bool external;
  @override
  final bool? lambda;
  @override
  final bool static;
  @override
  final String? name;
  @override
  final MethodType? type;
  @override
  final MethodModifier? modifier;
  @override
  final Reference? returns;

  factory _$Method([void Function(MethodBuilder)? updates]) =>
      (new MethodBuilder()..update(updates)).build() as _$Method;

  _$Method._(
      {required this.annotations,
      required this.docs,
      required this.types,
      required this.optionalParameters,
      required this.requiredParameters,
      this.body,
      required this.external,
      this.lambda,
      required this.static,
      this.name,
      this.type,
      this.modifier,
      this.returns})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(annotations, 'Method', 'annotations');
    BuiltValueNullFieldError.checkNotNull(docs, 'Method', 'docs');
    BuiltValueNullFieldError.checkNotNull(types, 'Method', 'types');
    BuiltValueNullFieldError.checkNotNull(
        optionalParameters, 'Method', 'optionalParameters');
    BuiltValueNullFieldError.checkNotNull(
        requiredParameters, 'Method', 'requiredParameters');
    BuiltValueNullFieldError.checkNotNull(external, 'Method', 'external');
    BuiltValueNullFieldError.checkNotNull(static, 'Method', 'static');
  }

  @override
  Method rebuild(void Function(MethodBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  _$MethodBuilder toBuilder() => new _$MethodBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Method &&
        annotations == other.annotations &&
        docs == other.docs &&
        types == other.types &&
        optionalParameters == other.optionalParameters &&
        requiredParameters == other.requiredParameters &&
        body == other.body &&
        external == other.external &&
        lambda == other.lambda &&
        static == other.static &&
        name == other.name &&
        type == other.type &&
        modifier == other.modifier &&
        returns == other.returns;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc(
                            $jc(
                                $jc(
                                    $jc(
                                        $jc(
                                            $jc(
                                                $jc(
                                                    $jc(0,
                                                        annotations.hashCode),
                                                    docs.hashCode),
                                                types.hashCode),
                                            optionalParameters.hashCode),
                                        requiredParameters.hashCode),
                                    body.hashCode),
                                external.hashCode),
                            lambda.hashCode),
                        static.hashCode),
                    name.hashCode),
                type.hashCode),
            modifier.hashCode),
        returns.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Method')
          ..add('annotations', annotations)
          ..add('docs', docs)
          ..add('types', types)
          ..add('optionalParameters', optionalParameters)
          ..add('requiredParameters', requiredParameters)
          ..add('body', body)
          ..add('external', external)
          ..add('lambda', lambda)
          ..add('static', static)
          ..add('name', name)
          ..add('type', type)
          ..add('modifier', modifier)
          ..add('returns', returns))
        .toString();
  }
}

class _$MethodBuilder extends MethodBuilder {
  _$Method? _$v;

  @override
  ListBuilder<Expression> get annotations {
    _$this;
    return super.annotations;
  }

  @override
  set annotations(ListBuilder<Expression> annotations) {
    _$this;
    super.annotations = annotations;
  }

  @override
  ListBuilder<String> get docs {
    _$this;
    return super.docs;
  }

  @override
  set docs(ListBuilder<String> docs) {
    _$this;
    super.docs = docs;
  }

  @override
  ListBuilder<Reference> get types {
    _$this;
    return super.types;
  }

  @override
  set types(ListBuilder<Reference> types) {
    _$this;
    super.types = types;
  }

  @override
  ListBuilder<Parameter> get optionalParameters {
    _$this;
    return super.optionalParameters;
  }

  @override
  set optionalParameters(ListBuilder<Parameter> optionalParameters) {
    _$this;
    super.optionalParameters = optionalParameters;
  }

  @override
  ListBuilder<Parameter> get requiredParameters {
    _$this;
    return super.requiredParameters;
  }

  @override
  set requiredParameters(ListBuilder<Parameter> requiredParameters) {
    _$this;
    super.requiredParameters = requiredParameters;
  }

  @override
  Code? get body {
    _$this;
    return super.body;
  }

  @override
  set body(Code? body) {
    _$this;
    super.body = body;
  }

  @override
  bool get external {
    _$this;
    return super.external;
  }

  @override
  set external(bool external) {
    _$this;
    super.external = external;
  }

  @override
  bool? get lambda {
    _$this;
    return super.lambda;
  }

  @override
  set lambda(bool? lambda) {
    _$this;
    super.lambda = lambda;
  }

  @override
  bool get static {
    _$this;
    return super.static;
  }

  @override
  set static(bool static) {
    _$this;
    super.static = static;
  }

  @override
  String? get name {
    _$this;
    return super.name;
  }

  @override
  set name(String? name) {
    _$this;
    super.name = name;
  }

  @override
  MethodType? get type {
    _$this;
    return super.type;
  }

  @override
  set type(MethodType? type) {
    _$this;
    super.type = type;
  }

  @override
  MethodModifier? get modifier {
    _$this;
    return super.modifier;
  }

  @override
  set modifier(MethodModifier? modifier) {
    _$this;
    super.modifier = modifier;
  }

  @override
  Reference? get returns {
    _$this;
    return super.returns;
  }

  @override
  set returns(Reference? returns) {
    _$this;
    super.returns = returns;
  }

  _$MethodBuilder() : super._();

  MethodBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      super.annotations = $v.annotations.toBuilder();
      super.docs = $v.docs.toBuilder();
      super.types = $v.types.toBuilder();
      super.optionalParameters = $v.optionalParameters.toBuilder();
      super.requiredParameters = $v.requiredParameters.toBuilder();
      super.body = $v.body;
      super.external = $v.external;
      super.lambda = $v.lambda;
      super.static = $v.static;
      super.name = $v.name;
      super.type = $v.type;
      super.modifier = $v.modifier;
      super.returns = $v.returns;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Method other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Method;
  }

  @override
  void update(void Function(MethodBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Method build() {
    _$Method _$result;
    try {
      _$result = _$v ??
          new _$Method._(
              annotations: annotations.build(),
              docs: docs.build(),
              types: types.build(),
              optionalParameters: optionalParameters.build(),
              requiredParameters: requiredParameters.build(),
              body: body,
              external: BuiltValueNullFieldError.checkNotNull(
                  external, 'Method', 'external'),
              lambda: lambda,
              static: BuiltValueNullFieldError.checkNotNull(
                  static, 'Method', 'static'),
              name: name,
              type: type,
              modifier: modifier,
              returns: returns);
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'annotations';
        annotations.build();
        _$failedField = 'docs';
        docs.build();
        _$failedField = 'types';
        types.build();
        _$failedField = 'optionalParameters';
        optionalParameters.build();
        _$failedField = 'requiredParameters';
        requiredParameters.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Method', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$Parameter extends Parameter {
  @override
  final Code? defaultTo;
  @override
  final String name;
  @override
  final bool named;
  @override
  final bool toThis;
  @override
  final BuiltList<Expression> annotations;
  @override
  final BuiltList<String> docs;
  @override
  final BuiltList<Reference> types;
  @override
  final Reference? type;
  @override
  final bool required;
  @override
  final bool covariant;

  factory _$Parameter([void Function(ParameterBuilder)? updates]) =>
      (new ParameterBuilder()..update(updates)).build() as _$Parameter;

  _$Parameter._(
      {this.defaultTo,
      required this.name,
      required this.named,
      required this.toThis,
      required this.annotations,
      required this.docs,
      required this.types,
      this.type,
      required this.required,
      required this.covariant})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(name, 'Parameter', 'name');
    BuiltValueNullFieldError.checkNotNull(named, 'Parameter', 'named');
    BuiltValueNullFieldError.checkNotNull(toThis, 'Parameter', 'toThis');
    BuiltValueNullFieldError.checkNotNull(
        annotations, 'Parameter', 'annotations');
    BuiltValueNullFieldError.checkNotNull(docs, 'Parameter', 'docs');
    BuiltValueNullFieldError.checkNotNull(types, 'Parameter', 'types');
    BuiltValueNullFieldError.checkNotNull(required, 'Parameter', 'required');
    BuiltValueNullFieldError.checkNotNull(covariant, 'Parameter', 'covariant');
  }

  @override
  Parameter rebuild(void Function(ParameterBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  _$ParameterBuilder toBuilder() => new _$ParameterBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Parameter &&
        defaultTo == other.defaultTo &&
        name == other.name &&
        named == other.named &&
        toThis == other.toThis &&
        annotations == other.annotations &&
        docs == other.docs &&
        types == other.types &&
        type == other.type &&
        required == other.required &&
        covariant == other.covariant;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc(
                            $jc(
                                $jc(
                                    $jc($jc(0, defaultTo.hashCode),
                                        name.hashCode),
                                    named.hashCode),
                                toThis.hashCode),
                            annotations.hashCode),
                        docs.hashCode),
                    types.hashCode),
                type.hashCode),
            required.hashCode),
        covariant.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Parameter')
          ..add('defaultTo', defaultTo)
          ..add('name', name)
          ..add('named', named)
          ..add('toThis', toThis)
          ..add('annotations', annotations)
          ..add('docs', docs)
          ..add('types', types)
          ..add('type', type)
          ..add('required', required)
          ..add('covariant', covariant))
        .toString();
  }
}

class _$ParameterBuilder extends ParameterBuilder {
  _$Parameter? _$v;

  @override
  Code? get defaultTo {
    _$this;
    return super.defaultTo;
  }

  @override
  set defaultTo(Code? defaultTo) {
    _$this;
    super.defaultTo = defaultTo;
  }

  @override
  String get name {
    _$this;
    return super.name;
  }

  @override
  set name(String name) {
    _$this;
    super.name = name;
  }

  @override
  bool get named {
    _$this;
    return super.named;
  }

  @override
  set named(bool named) {
    _$this;
    super.named = named;
  }

  @override
  bool get toThis {
    _$this;
    return super.toThis;
  }

  @override
  set toThis(bool toThis) {
    _$this;
    super.toThis = toThis;
  }

  @override
  ListBuilder<Expression> get annotations {
    _$this;
    return super.annotations;
  }

  @override
  set annotations(ListBuilder<Expression> annotations) {
    _$this;
    super.annotations = annotations;
  }

  @override
  ListBuilder<String> get docs {
    _$this;
    return super.docs;
  }

  @override
  set docs(ListBuilder<String> docs) {
    _$this;
    super.docs = docs;
  }

  @override
  ListBuilder<Reference> get types {
    _$this;
    return super.types;
  }

  @override
  set types(ListBuilder<Reference> types) {
    _$this;
    super.types = types;
  }

  @override
  Reference? get type {
    _$this;
    return super.type;
  }

  @override
  set type(Reference? type) {
    _$this;
    super.type = type;
  }

  @override
  bool get required {
    _$this;
    return super.required;
  }

  @override
  set required(bool required) {
    _$this;
    super.required = required;
  }

  @override
  bool get covariant {
    _$this;
    return super.covariant;
  }

  @override
  set covariant(bool covariant) {
    _$this;
    super.covariant = covariant;
  }

  _$ParameterBuilder() : super._();

  ParameterBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      super.defaultTo = $v.defaultTo;
      super.name = $v.name;
      super.named = $v.named;
      super.toThis = $v.toThis;
      super.annotations = $v.annotations.toBuilder();
      super.docs = $v.docs.toBuilder();
      super.types = $v.types.toBuilder();
      super.type = $v.type;
      super.required = $v.required;
      super.covariant = $v.covariant;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Parameter other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Parameter;
  }

  @override
  void update(void Function(ParameterBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Parameter build() {
    _$Parameter _$result;
    try {
      _$result = _$v ??
          new _$Parameter._(
              defaultTo: defaultTo,
              name: BuiltValueNullFieldError.checkNotNull(
                  name, 'Parameter', 'name'),
              named: BuiltValueNullFieldError.checkNotNull(
                  named, 'Parameter', 'named'),
              toThis: BuiltValueNullFieldError.checkNotNull(
                  toThis, 'Parameter', 'toThis'),
              annotations: annotations.build(),
              docs: docs.build(),
              types: types.build(),
              type: type,
              required: BuiltValueNullFieldError.checkNotNull(
                  required, 'Parameter', 'required'),
              covariant: BuiltValueNullFieldError.checkNotNull(
                  covariant, 'Parameter', 'covariant'));
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'annotations';
        annotations.build();
        _$failedField = 'docs';
        docs.build();
        _$failedField = 'types';
        types.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Parameter', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
