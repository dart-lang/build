// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_triggers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ImportBuildTrigger extends ImportBuildTrigger {
  @override
  final String import;

  factory _$ImportBuildTrigger([
    void Function(ImportBuildTriggerBuilder)? updates,
  ]) => (ImportBuildTriggerBuilder()..update(updates))._build();

  _$ImportBuildTrigger._({required this.import}) : super._();
  @override
  ImportBuildTrigger rebuild(
    void Function(ImportBuildTriggerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ImportBuildTriggerBuilder toBuilder() =>
      ImportBuildTriggerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ImportBuildTrigger && import == other.import;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, import.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ImportBuildTrigger')
      ..add('import', import)).toString();
  }
}

class ImportBuildTriggerBuilder
    implements Builder<ImportBuildTrigger, ImportBuildTriggerBuilder> {
  _$ImportBuildTrigger? _$v;

  String? _import;
  String? get import => _$this._import;
  set import(String? import) => _$this._import = import;

  ImportBuildTriggerBuilder();

  ImportBuildTriggerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _import = $v.import;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ImportBuildTrigger other) {
    _$v = other as _$ImportBuildTrigger;
  }

  @override
  void update(void Function(ImportBuildTriggerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ImportBuildTrigger build() => _build();

  _$ImportBuildTrigger _build() {
    final _$result =
        _$v ??
        _$ImportBuildTrigger._(
          import: BuiltValueNullFieldError.checkNotNull(
            import,
            r'ImportBuildTrigger',
            'import',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

class _$AnnotationBuildTrigger extends AnnotationBuildTrigger {
  @override
  final String annotation;

  factory _$AnnotationBuildTrigger([
    void Function(AnnotationBuildTriggerBuilder)? updates,
  ]) => (AnnotationBuildTriggerBuilder()..update(updates))._build();

  _$AnnotationBuildTrigger._({required this.annotation}) : super._();
  @override
  AnnotationBuildTrigger rebuild(
    void Function(AnnotationBuildTriggerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AnnotationBuildTriggerBuilder toBuilder() =>
      AnnotationBuildTriggerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AnnotationBuildTrigger && annotation == other.annotation;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, annotation.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }
}

class AnnotationBuildTriggerBuilder
    implements Builder<AnnotationBuildTrigger, AnnotationBuildTriggerBuilder> {
  _$AnnotationBuildTrigger? _$v;

  String? _annotation;
  String? get annotation => _$this._annotation;
  set annotation(String? annotation) => _$this._annotation = annotation;

  AnnotationBuildTriggerBuilder();

  AnnotationBuildTriggerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _annotation = $v.annotation;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AnnotationBuildTrigger other) {
    _$v = other as _$AnnotationBuildTrigger;
  }

  @override
  void update(void Function(AnnotationBuildTriggerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AnnotationBuildTrigger build() => _build();

  _$AnnotationBuildTrigger _build() {
    final _$result =
        _$v ??
        _$AnnotationBuildTrigger._(
          annotation: BuiltValueNullFieldError.checkNotNull(
            annotation,
            r'AnnotationBuildTrigger',
            'annotation',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
