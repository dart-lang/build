// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'directive.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Directive extends Directive {
  @override
  final String? as;
  @override
  final String url;
  @override
  final DirectiveType type;
  @override
  final List<String> show;
  @override
  final List<String> hide;
  @override
  final bool deferred;

  factory _$Directive([void Function(DirectiveBuilder)? updates]) =>
      (new DirectiveBuilder()..update(updates)).build() as _$Directive;

  _$Directive._(
      {this.as,
      required this.url,
      required this.type,
      required this.show,
      required this.hide,
      required this.deferred})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(url, r'Directive', 'url');
    BuiltValueNullFieldError.checkNotNull(type, r'Directive', 'type');
    BuiltValueNullFieldError.checkNotNull(show, r'Directive', 'show');
    BuiltValueNullFieldError.checkNotNull(hide, r'Directive', 'hide');
    BuiltValueNullFieldError.checkNotNull(deferred, r'Directive', 'deferred');
  }

  @override
  Directive rebuild(void Function(DirectiveBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  _$DirectiveBuilder toBuilder() => new _$DirectiveBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Directive &&
        as == other.as &&
        url == other.url &&
        type == other.type &&
        show == other.show &&
        hide == other.hide &&
        deferred == other.deferred;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc($jc($jc($jc(0, as.hashCode), url.hashCode), type.hashCode),
                show.hashCode),
            hide.hashCode),
        deferred.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Directive')
          ..add('as', as)
          ..add('url', url)
          ..add('type', type)
          ..add('show', show)
          ..add('hide', hide)
          ..add('deferred', deferred))
        .toString();
  }
}

class _$DirectiveBuilder extends DirectiveBuilder {
  _$Directive? _$v;

  @override
  String? get as {
    _$this;
    return super.as;
  }

  @override
  set as(String? as) {
    _$this;
    super.as = as;
  }

  @override
  String? get url {
    _$this;
    return super.url;
  }

  @override
  set url(String? url) {
    _$this;
    super.url = url;
  }

  @override
  DirectiveType? get type {
    _$this;
    return super.type;
  }

  @override
  set type(DirectiveType? type) {
    _$this;
    super.type = type;
  }

  @override
  List<String> get show {
    _$this;
    return super.show;
  }

  @override
  set show(List<String> show) {
    _$this;
    super.show = show;
  }

  @override
  List<String> get hide {
    _$this;
    return super.hide;
  }

  @override
  set hide(List<String> hide) {
    _$this;
    super.hide = hide;
  }

  @override
  bool get deferred {
    _$this;
    return super.deferred;
  }

  @override
  set deferred(bool deferred) {
    _$this;
    super.deferred = deferred;
  }

  _$DirectiveBuilder() : super._();

  DirectiveBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      super.as = $v.as;
      super.url = $v.url;
      super.type = $v.type;
      super.show = $v.show;
      super.hide = $v.hide;
      super.deferred = $v.deferred;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Directive other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Directive;
  }

  @override
  void update(void Function(DirectiveBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Directive build() => _build();

  _$Directive _build() {
    final _$result = _$v ??
        new _$Directive._(
            as: as,
            url:
                BuiltValueNullFieldError.checkNotNull(url, r'Directive', 'url'),
            type: BuiltValueNullFieldError.checkNotNull(
                type, r'Directive', 'type'),
            show: BuiltValueNullFieldError.checkNotNull(
                show, r'Directive', 'show'),
            hide: BuiltValueNullFieldError.checkNotNull(
                hide, r'Directive', 'hide'),
            deferred: BuiltValueNullFieldError.checkNotNull(
                deferred, r'Directive', 'deferred'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,no_leading_underscores_for_local_identifiers,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new,unnecessary_lambdas
