// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Library extends Library {
  @override
  final BuiltList<Expression> annotations;
  @override
  final BuiltList<Directive> directives;
  @override
  final BuiltList<Spec> body;
  @override
  final String? name;

  factory _$Library([void Function(LibraryBuilder)? updates]) =>
      (new LibraryBuilder()..update(updates)).build() as _$Library;

  _$Library._(
      {required this.annotations,
      required this.directives,
      required this.body,
      this.name})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        annotations, 'Library', 'annotations');
    BuiltValueNullFieldError.checkNotNull(directives, 'Library', 'directives');
    BuiltValueNullFieldError.checkNotNull(body, 'Library', 'body');
  }

  @override
  Library rebuild(void Function(LibraryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  _$LibraryBuilder toBuilder() => new _$LibraryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Library &&
        annotations == other.annotations &&
        directives == other.directives &&
        body == other.body &&
        name == other.name;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, annotations.hashCode), directives.hashCode),
            body.hashCode),
        name.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Library')
          ..add('annotations', annotations)
          ..add('directives', directives)
          ..add('body', body)
          ..add('name', name))
        .toString();
  }
}

class _$LibraryBuilder extends LibraryBuilder {
  _$Library? _$v;

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
  ListBuilder<Directive> get directives {
    _$this;
    return super.directives;
  }

  @override
  set directives(ListBuilder<Directive> directives) {
    _$this;
    super.directives = directives;
  }

  @override
  ListBuilder<Spec> get body {
    _$this;
    return super.body;
  }

  @override
  set body(ListBuilder<Spec> body) {
    _$this;
    super.body = body;
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

  _$LibraryBuilder() : super._();

  LibraryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      super.annotations = $v.annotations.toBuilder();
      super.directives = $v.directives.toBuilder();
      super.body = $v.body.toBuilder();
      super.name = $v.name;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Library other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Library;
  }

  @override
  void update(void Function(LibraryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Library build() {
    _$Library _$result;
    try {
      _$result = _$v ??
          new _$Library._(
              annotations: annotations.build(),
              directives: directives.build(),
              body: body.build(),
              name: name);
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'annotations';
        annotations.build();
        _$failedField = 'directives';
        directives.build();
        _$failedField = 'body';
        body.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Library', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
