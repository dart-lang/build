// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mixin.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Mixin extends Mixin {
  @override
  final BuiltList<Expression> annotations;
  @override
  final BuiltList<String> docs;
  @override
  final Reference? on;
  @override
  final BuiltList<Reference> implements;
  @override
  final BuiltList<Reference> types;
  @override
  final BuiltList<Method> methods;
  @override
  final BuiltList<Field> fields;
  @override
  final String name;

  factory _$Mixin([void Function(MixinBuilder)? updates]) =>
      (new MixinBuilder()..update(updates)).build() as _$Mixin;

  _$Mixin._(
      {required this.annotations,
      required this.docs,
      this.on,
      required this.implements,
      required this.types,
      required this.methods,
      required this.fields,
      required this.name})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(annotations, r'Mixin', 'annotations');
    BuiltValueNullFieldError.checkNotNull(docs, r'Mixin', 'docs');
    BuiltValueNullFieldError.checkNotNull(implements, r'Mixin', 'implements');
    BuiltValueNullFieldError.checkNotNull(types, r'Mixin', 'types');
    BuiltValueNullFieldError.checkNotNull(methods, r'Mixin', 'methods');
    BuiltValueNullFieldError.checkNotNull(fields, r'Mixin', 'fields');
    BuiltValueNullFieldError.checkNotNull(name, r'Mixin', 'name');
  }

  @override
  Mixin rebuild(void Function(MixinBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  _$MixinBuilder toBuilder() => new _$MixinBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Mixin &&
        annotations == other.annotations &&
        docs == other.docs &&
        on == other.on &&
        implements == other.implements &&
        types == other.types &&
        methods == other.methods &&
        fields == other.fields &&
        name == other.name;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc($jc($jc(0, annotations.hashCode), docs.hashCode),
                            on.hashCode),
                        implements.hashCode),
                    types.hashCode),
                methods.hashCode),
            fields.hashCode),
        name.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Mixin')
          ..add('annotations', annotations)
          ..add('docs', docs)
          ..add('on', on)
          ..add('implements', implements)
          ..add('types', types)
          ..add('methods', methods)
          ..add('fields', fields)
          ..add('name', name))
        .toString();
  }
}

class _$MixinBuilder extends MixinBuilder {
  _$Mixin? _$v;

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
  Reference? get on {
    _$this;
    return super.on;
  }

  @override
  set on(Reference? on) {
    _$this;
    super.on = on;
  }

  @override
  ListBuilder<Reference> get implements {
    _$this;
    return super.implements;
  }

  @override
  set implements(ListBuilder<Reference> implements) {
    _$this;
    super.implements = implements;
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
  ListBuilder<Method> get methods {
    _$this;
    return super.methods;
  }

  @override
  set methods(ListBuilder<Method> methods) {
    _$this;
    super.methods = methods;
  }

  @override
  ListBuilder<Field> get fields {
    _$this;
    return super.fields;
  }

  @override
  set fields(ListBuilder<Field> fields) {
    _$this;
    super.fields = fields;
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

  _$MixinBuilder() : super._();

  MixinBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      super.annotations = $v.annotations.toBuilder();
      super.docs = $v.docs.toBuilder();
      super.on = $v.on;
      super.implements = $v.implements.toBuilder();
      super.types = $v.types.toBuilder();
      super.methods = $v.methods.toBuilder();
      super.fields = $v.fields.toBuilder();
      super.name = $v.name;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Mixin other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Mixin;
  }

  @override
  void update(void Function(MixinBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Mixin build() => _build();

  _$Mixin _build() {
    _$Mixin _$result;
    try {
      _$result = _$v ??
          new _$Mixin._(
              annotations: annotations.build(),
              docs: docs.build(),
              on: on,
              implements: implements.build(),
              types: types.build(),
              methods: methods.build(),
              fields: fields.build(),
              name: BuiltValueNullFieldError.checkNotNull(
                  name, r'Mixin', 'name'));
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'annotations';
        annotations.build();
        _$failedField = 'docs';
        docs.build();

        _$failedField = 'implements';
        implements.build();
        _$failedField = 'types';
        types.build();
        _$failedField = 'methods';
        methods.build();
        _$failedField = 'fields';
        fields.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'Mixin', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,no_leading_underscores_for_local_identifiers,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new,unnecessary_lambdas
