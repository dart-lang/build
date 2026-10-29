// Copyright 2026 Dart Mockito authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart' as analyzer;
import 'package:analyzer/dart/element/type_system.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/type_algebra.dart' show Substitution;
import 'package:code_builder/code_builder.dart' hide refer;

/// Resolves an analyzer [analyzer.DartType] to a `code_builder` [Reference]
/// within the generated mock library's import and type-parameter scope.
typedef JsTypeReferenceResolver =
    Reference Function(
      analyzer.DartType type, {
      bool forceNullable,
      bool overrideVoid,
    });

Reference _referImported(String symbol, String? url) => Reference(symbol, url);

Reference _refer(String symbol) => Reference(symbol);

/// Returns the non-empty string value from the `dart:js_interop` `@JS()`
/// annotation on [element], if present.
String? jsInteropAnnotationName(Element element) {
  for (final annotation in element.baseElement.metadata.annotations) {
    final annotationElement = annotation.element;
    if (annotationElement is ConstructorElement &&
        annotationElement.enclosingElement.name == 'JS' &&
        annotationElement.library.uri.toString() == 'dart:js_interop') {
      final value =
          annotation.computeConstantValue()?.getField('name')?.toStringValue();
      if (value != null && value.isNotEmpty) return value;
    }
  }
  return null;
}

String _effectiveJsExportName(ExecutableElement member) =>
    jsInteropAnnotationName(member) ?? member.displayName;

String _memberUnsupportedKey(ExecutableElement member) =>
    member is SetterElement ? '${member.name}=' : member.name!;

String _memberSymbolLiteral(ExecutableElement member) =>
    member is SetterElement
        ? "Symbol('${member.displayName}=')"
        : '#${member.displayName}';

String _disambiguatedExportKey(ExecutableElement member) => switch (member) {
  GetterElement() => '\$mockito\$get\$${member.displayName}',
  SetterElement() => '\$mockito\$set\$${member.displayName}',
  _ => '\$mockito\$method\$${member.displayName}',
};

String _safeJsIdentifier(String name) => name.replaceAllMapped(
  RegExp(r'[^a-zA-Z0-9_]'),
  (m) => '\$u${m[0]!.codeUnitAt(0).toRadixString(16)}_',
);

/// Builds a `code_builder` string literal suitable for `@JSExport(...)`.
Expression jsExportLiteral(String value) =>
    value.contains("'")
        ? literalString(value.replaceAll(r'$', r'\$'))
        : literalString(value, raw: value.contains(r'$'));

/// Whether [member] is emitted onto `Mock*Target` as a concrete member that
/// `dart:js_interop` `@JSExport()` can export.
bool isExportableJsInteropMember(ExecutableElement member) {
  if (!member.isExternal || member.isPrivate || member.isStatic) return false;
  if (member is PropertyAccessorElement) {
    return member.name != 'hashCode' && member.name != 'runtimeType';
  }
  if (member is! MethodElement) return false;
  if (member.isOperator || member.typeParameters.isNotEmpty) return false;
  final name = member.name;
  return name != 'noSuchMethod' &&
      name != '==' &&
      !(name == 'toString' && member.formalParameters.isEmpty);
}

enum _JsCheckCategory {
  primitive,
  builtinObject,
  nominalObject,
  broadObject,
  top,
  nullOnly,
  cannotMultiplex,
}

final class _JsParamSpec {
  final analyzer.DartType originalType;
  final _JsCheckCategory category;
  final String tag;
  final String? sdkCheckSymbol;
  final bool isNullable;
  final bool canEmitIsA;

  const _JsParamSpec({
    required this.originalType,
    required this.category,
    required this.tag,
    required this.isNullable,
    required this.canEmitIsA,
    this.sdkCheckSymbol,
  });

  int get specificityRank => switch (category) {
    _JsCheckCategory.primitive => 1,
    _JsCheckCategory.builtinObject => 2,
    _JsCheckCategory.nominalObject => 3,
    _JsCheckCategory.broadObject => 4,
    _ => 5,
  };

  bool get _isObjectCategory =>
      category == _JsCheckCategory.builtinObject ||
      category == _JsCheckCategory.nominalObject ||
      category == _JsCheckCategory.broadObject;

  bool isDisjointFrom(_JsParamSpec other, TypeSystem typeSystem) {
    if (category == _JsCheckCategory.primitive) {
      if (other.category == _JsCheckCategory.primitive) {
        return tag != other.tag;
      }
      return other._isObjectCategory;
    }
    if (other.category == _JsCheckCategory.primitive) {
      return _isObjectCategory;
    }
    if (category == _JsCheckCategory.builtinObject &&
        other.category == _JsCheckCategory.builtinObject) {
      return tag != other.tag;
    }
    if (category == _JsCheckCategory.builtinObject &&
        other.category == _JsCheckCategory.nominalObject) {
      return _isBuiltinDisjointFromNominal(this, other, typeSystem);
    }
    if (category == _JsCheckCategory.nominalObject &&
        other.category == _JsCheckCategory.builtinObject) {
      return _isBuiltinDisjointFromNominal(other, this, typeSystem);
    }
    if (category == _JsCheckCategory.nominalObject &&
        other.category == _JsCheckCategory.nominalObject) {
      return _areNominalDisjoint(this, other, typeSystem);
    }
    return false;
  }
}

const _typedArrayInstanceOfTags = {
  'instanceof:Int8Array',
  'instanceof:Uint8Array',
  'instanceof:Uint8ClampedArray',
  'instanceof:Int16Array',
  'instanceof:Uint16Array',
  'instanceof:Int32Array',
  'instanceof:Uint32Array',
  'instanceof:BigInt64Array',
  'instanceof:BigUint64Array',
  'instanceof:Float16Array',
  'instanceof:Float32Array',
  'instanceof:Float64Array',
};

bool _isBuiltinDisjointFromNominal(
  _JsParamSpec builtin,
  _JsParamSpec nominal,
  TypeSystem typeSystem,
) {
  final nominalNonNull = typeSystem.promoteToNonNull(nominal.originalType);
  return switch (builtin.sdkCheckSymbol) {
    'JSArray' =>
      nominal.tag != 'instanceof:Array' &&
          !_wrapsOrImplementsSdkType(nominalNonNull, 'JSArray'),
    'JSTypedArray' =>
      !_typedArrayInstanceOfTags.contains(nominal.tag) &&
          !_wrapsOrImplementsSdkType(nominalNonNull, 'JSTypedArray'),
    'JSExportedDartFunction' =>
      nominal.tag != 'instanceof:Function' &&
          !_wrapsOrImplementsSdkType(nominalNonNull, 'JSFunction'),
    'JSBoxedDartObject' =>
      !_wrapsOrImplementsSdkType(nominalNonNull, 'JSBoxedDartObject'),
    _ => false,
  };
}

bool _areNominalDisjoint(
  _JsParamSpec a,
  _JsParamSpec b,
  TypeSystem typeSystem,
) {
  if (a.tag == b.tag) return false;
  final aNonNull = typeSystem.promoteToNonNull(a.originalType);
  final bNonNull = typeSystem.promoteToNonNull(b.originalType);
  if (typeSystem.isSubtypeOf(aNonNull, bNonNull) ||
      typeSystem.isSubtypeOf(bNonNull, aNonNull)) {
    return false;
  }
  return !_wrapsExtensionElement(aNonNull, bNonNull.element) &&
      !_wrapsExtensionElement(bNonNull, aNonNull.element);
}

bool _isSdkJsInteropType(Element? element, String name) =>
    element != null &&
    element.name == name &&
    element.library?.uri.toString() == 'dart:js_interop';

bool _wrapsExtensionElement(analyzer.DartType type, Element? target) {
  if (target == null) return false;
  var current = type.element?.baseElement;
  final targetBase = target.baseElement;
  while (current is ExtensionTypeElement) {
    if (current == targetBase) return true;
    current = current.representation.type.element?.baseElement;
  }
  return false;
}

bool _wrapsOrImplementsSdkType(analyzer.DartType type, String sdkName) {
  if (type is! analyzer.InterfaceType) return false;
  if (_isSdkJsInteropType(type.element, sdkName)) return true;
  if (type.allSupertypes.any((s) => _isSdkJsInteropType(s.element, sdkName))) {
    return true;
  }
  Element? current = type.element;
  while (current is ExtensionTypeElement) {
    if (_isSdkJsInteropType(current, sdkName)) return true;
    if (current.thisType.allSupertypes.any(
      (s) => _isSdkJsInteropType(s.element, sdkName),
    )) {
      return true;
    }
    current = current.representation.type.element;
  }
  return false;
}

bool _implementsJsAny(analyzer.DartType type) {
  if (type.isDartCoreNull) return true;
  if (type is analyzer.TypeParameterType) {
    return _implementsJsAny(type.bound);
  }
  return _wrapsDirectOrSuperSdkJsAny(type);
}

bool _wrapsDirectOrSuperSdkJsAny(analyzer.DartType type) {
  if (type is! analyzer.InterfaceType) return false;
  if (_isSdkJsInteropType(type.element, 'JSAny')) return true;
  return type.allSupertypes.any((s) => _isSdkJsInteropType(s.element, 'JSAny'));
}

bool _erasesToJsObject(analyzer.DartType? type) {
  if (type == null) return false;
  if (type is analyzer.TypeParameterType) {
    return _erasesToJsObject(type.bound);
  }
  return _wrapsOrImplementsSdkType(type, 'JSObject');
}

analyzer.DartType _unwrapNonJsExtensionType(analyzer.DartType type) {
  var current = type;
  while (current is analyzer.InterfaceType &&
      current.element is ExtensionTypeElement &&
      !(current.element as ExtensionTypeElement).isJSInteropType) {
    final ext = current.element as ExtensionTypeElement;
    current = Substitution.fromInterfaceType(
      current,
    ).substituteType(ext.representation.type);
  }
  return current;
}

_JsParamSpec _classifyJsParam(analyzer.DartType type, TypeSystem typeSystem) {
  final coreType = _unwrapNonJsExtensionType(type);
  final isNullable = typeSystem.isNullable(type);
  return _classifyCoreOrTypeParamJsType(
        coreType,
        type,
        isNullable: isNullable,
      ) ??
      _classifyInterfaceJsType(coreType, type, isNullable: isNullable);
}

_JsParamSpec? _classifyCoreOrTypeParamJsType(
  analyzer.DartType coreType,
  analyzer.DartType originalType, {
  required bool isNullable,
}) {
  if (coreType is analyzer.DynamicType || coreType is analyzer.InvalidType) {
    return _cannotMultiplexSpec(originalType, isNullable: isNullable);
  }
  if (coreType.isDartCoreNull) {
    return _JsParamSpec(
      originalType: originalType,
      category: _JsCheckCategory.nullOnly,
      tag: 'null',
      isNullable: true,
      canEmitIsA: false,
    );
  }
  if (coreType.isDartCoreString) {
    return _primitiveJsSpec(originalType, 'string', 'JSString', isNullable);
  }
  if (coreType.isDartCoreBool) {
    return _primitiveJsSpec(originalType, 'boolean', 'JSBoolean', isNullable);
  }
  if (coreType.isDartCoreInt ||
      coreType.isDartCoreDouble ||
      coreType.isDartCoreNum) {
    return _primitiveJsSpec(originalType, 'number', 'JSNumber', isNullable);
  }
  if (coreType is analyzer.TypeParameterType) {
    return _JsParamSpec(
      originalType: originalType,
      category:
          _erasesToJsObject(coreType.bound)
              ? _JsCheckCategory.broadObject
              : _JsCheckCategory.top,
      tag: 'typeparam:${coreType.element.name}',
      isNullable: isNullable,
      canEmitIsA: false,
    );
  }
  return null;
}

_JsParamSpec _primitiveJsSpec(
  analyzer.DartType originalType,
  String typeofTag,
  String sdkSymbol,
  bool isNullable,
) => _JsParamSpec(
  originalType: originalType,
  category: _JsCheckCategory.primitive,
  tag: 'typeof:$typeofTag',
  sdkCheckSymbol: sdkSymbol,
  isNullable: isNullable,
  canEmitIsA: true,
);

_JsParamSpec _cannotMultiplexSpec(
  analyzer.DartType originalType, {
  required bool isNullable,
}) => _JsParamSpec(
  originalType: originalType,
  category: _JsCheckCategory.cannotMultiplex,
  tag: 'invalid',
  isNullable: isNullable,
  canEmitIsA: false,
);

_JsParamSpec _classifyInterfaceJsType(
  analyzer.DartType coreType,
  analyzer.DartType originalType, {
  required bool isNullable,
}) {
  if (coreType is! analyzer.InterfaceType) {
    return _cannotMultiplexSpec(originalType, isNullable: isNullable);
  }
  final element = coreType.element;
  if (_isSdkJsInteropType(element, 'ExternalDartReference') ||
      element is! ExtensionTypeElement ||
      !element.isJSInteropType) {
    return _cannotMultiplexSpec(originalType, isNullable: isNullable);
  }
  final primitive = _classifySdkPrimitiveWrapper(
    element,
    originalType,
    isNullable: isNullable,
  );
  if (primitive != null) return primitive;
  final directSdk = _classifyDirectSdkExtension(
    element,
    originalType,
    isNullable: isNullable,
  );
  if (directSdk != null) return directSdk;
  if (!_erasesToJsObject(coreType)) {
    return _JsParamSpec(
      originalType: originalType,
      category: _JsCheckCategory.top,
      tag: 'top:${element.name}',
      isNullable: isNullable,
      canEmitIsA: false,
    );
  }
  return _classifyNominalOrObjectLiteral(
    element,
    originalType,
    isNullable: isNullable,
  );
}

_JsParamSpec? _classifySdkPrimitiveWrapper(
  ExtensionTypeElement element,
  analyzer.DartType originalType, {
  required bool isNullable,
}) {
  Element? current = element;
  while (current is ExtensionTypeElement) {
    if (current.library.uri.toString() == 'dart:js_interop') {
      return switch (current.name) {
        'JSString' => _primitiveJsSpec(
          originalType,
          'string',
          'JSString',
          isNullable,
        ),
        'JSBoolean' => _primitiveJsSpec(
          originalType,
          'boolean',
          'JSBoolean',
          isNullable,
        ),
        'JSNumber' => _primitiveJsSpec(
          originalType,
          'number',
          'JSNumber',
          isNullable,
        ),
        'JSBigInt' => _primitiveJsSpec(
          originalType,
          'bigint',
          'JSBigInt',
          isNullable,
        ),
        'JSSymbol' => _primitiveJsSpec(
          originalType,
          'symbol',
          'JSSymbol',
          isNullable,
        ),
        _ => null,
      };
    }
    current = current.representation.type.element;
  }
  return null;
}

_JsParamSpec? _classifyDirectSdkExtension(
  ExtensionTypeElement element,
  analyzer.DartType originalType, {
  required bool isNullable,
}) {
  if (element.library.uri.toString() != 'dart:js_interop') return null;
  final name = element.name;
  return switch (name) {
    'JSAny' => _JsParamSpec(
      originalType: originalType,
      category: _JsCheckCategory.top,
      tag: 'top:JSAny',
      isNullable: isNullable,
      canEmitIsA: false,
    ),
    'JSObject' => _JsParamSpec(
      originalType: originalType,
      category: _JsCheckCategory.broadObject,
      tag: 'broad:JSObject',
      sdkCheckSymbol: 'JSObject',
      isNullable: isNullable,
      canEmitIsA: true,
    ),
    'JSArray' ||
    'JSTypedArray' ||
    'JSExportedDartFunction' ||
    'JSBoxedDartObject' => _JsParamSpec(
      originalType: originalType,
      category: _JsCheckCategory.builtinObject,
      tag: 'builtin:$name',
      sdkCheckSymbol: name,
      isNullable: isNullable,
      canEmitIsA: true,
    ),
    _ => null,
  };
}

_JsParamSpec _classifyNominalOrObjectLiteral(
  ExtensionTypeElement element,
  analyzer.DartType originalType, {
  required bool isNullable,
}) {
  final hasObjectLiteralConstructor = element.constructors.any(
    (c) => c.isExternal && c.formalParameters.any((p) => p.isNamed),
  );
  if (hasObjectLiteralConstructor) {
    return _JsParamSpec(
      originalType: originalType,
      category: _JsCheckCategory.broadObject,
      tag: 'literal:${element.name}',
      isNullable: isNullable,
      canEmitIsA: false,
    );
  }
  final typeJsName = jsInteropAnnotationName(element) ?? element.name!;
  final libJsName = jsInteropAnnotationName(element.library);
  final instanceOfName =
      libJsName == null ? typeJsName : '$libJsName.$typeJsName';
  if (instanceOfName == 'Object') {
    return _JsParamSpec(
      originalType: originalType,
      category: _JsCheckCategory.broadObject,
      tag: 'broad:Object',
      isNullable: isNullable,
      canEmitIsA: true,
    );
  }
  return _JsParamSpec(
    originalType: originalType,
    category: _JsCheckCategory.nominalObject,
    tag: 'instanceof:$instanceOfName',
    isNullable: isNullable,
    canEmitIsA: true,
  );
}

sealed class _JsDispatchClause {
  final int paramIndex;
  String get dedupeKey;

  const _JsDispatchClause(this.paramIndex);
}

final class _JsParamNullClause extends _JsDispatchClause {
  final bool expectNull;

  const _JsParamNullClause(super.paramIndex, {required this.expectNull});

  @override
  String get dedupeKey => 'null:$paramIndex:$expectNull';
}

final class _JsParamTypeClause extends _JsDispatchClause {
  final _JsParamSpec spec;
  final bool allowNull;

  const _JsParamTypeClause(
    super.paramIndex,
    this.spec, {
    required this.allowNull,
  });

  @override
  String get dedupeKey => 'type:$paramIndex:$allowNull:${spec.tag}';
}

final class _JsOverloadCandidate<E extends ExecutableElement> {
  final E element;
  final List<_JsParamSpec> params;
  final int minRequired;
  final bool isPrimary;

  const _JsOverloadCandidate({
    required this.element,
    required this.params,
    required this.minRequired,
    required this.isPrimary,
  });

  int get maxArgs => params.length;

  bool acceptsNullAt(int index) =>
      index >= minRequired || params[index].isNullable;
}

final class _JsOrderedBranch<E extends ExecutableElement> {
  final _JsOverloadCandidate<E> candidate;
  final List<_JsDispatchClause> clauses;

  const _JsOrderedBranch(this.candidate, this.clauses);
}

List<_JsOrderedBranch<E>>? _orderOverloadBranches<E extends ExecutableElement>(
  List<_JsOverloadCandidate<E>> candidates,
  TypeSystem typeSystem,
) {
  for (final candidate in candidates) {
    if (candidate.params.any(
      (p) => p.category == _JsCheckCategory.cannotMultiplex,
    )) {
      return null;
    }
  }
  if (!_areAllPairsDistinguishable(candidates, typeSystem)) return null;

  final remaining = candidates.toList();
  final ordered = <_JsOrderedBranch<E>>[];
  while (remaining.length > 1) {
    final next = _selectNextBranch(remaining, typeSystem);
    if (next == null) return null;
    ordered.add(next);
    remaining.remove(next.candidate);
  }
  ordered.add(_JsOrderedBranch(remaining.single, const []));
  return ordered;
}

bool _areAllPairsDistinguishable<E extends ExecutableElement>(
  List<_JsOverloadCandidate<E>> candidates,
  TypeSystem typeSystem,
) {
  for (var i = 0; i < candidates.length; i++) {
    for (var j = i + 1; j < candidates.length; j++) {
      if (!_pairIsDistinguishable(candidates[i], candidates[j], typeSystem)) {
        return false;
      }
    }
  }
  return true;
}

bool _pairIsDistinguishable<E extends ExecutableElement>(
  _JsOverloadCandidate<E> a,
  _JsOverloadCandidate<E> b,
  TypeSystem typeSystem,
) {
  if (_nonNullRequiredIndexBetween(b.maxArgs, a.minRequired, a) != null ||
      _nonNullRequiredIndexBetween(a.maxArgs, b.minRequired, b) != null) {
    return true;
  }
  final maxShared = a.maxArgs < b.maxArgs ? a.maxArgs : b.maxArgs;
  final firstOptional =
      a.minRequired < b.minRequired ? a.minRequired : b.minRequired;
  for (var i = 0; i <= firstOptional && i < maxShared; i++) {
    if (a.params[i].isDisjointFrom(b.params[i], typeSystem)) return true;
  }
  return false;
}

int? _nonNullRequiredIndexBetween<E extends ExecutableElement>(
  int start,
  int end,
  _JsOverloadCandidate<E> candidate,
) {
  for (var i = start; i < end; i++) {
    if (!candidate.params[i].isNullable) return i;
  }
  return null;
}

_JsOrderedBranch<E>? _selectNextBranch<E extends ExecutableElement>(
  List<_JsOverloadCandidate<E>> remaining,
  TypeSystem typeSystem,
) {
  _JsOverloadCandidate<E>? bestCandidate;
  List<_JsDispatchClause>? bestClauses;
  var bestWorstRank = 999;

  for (final candidate in remaining) {
    final evaluated = _evaluateCandidateAgainstRest(
      candidate,
      remaining,
      typeSystem,
    );
    if (evaluated == null) continue;
    final (worstRank, clauses) = evaluated;
    final isBetter =
        bestCandidate == null ||
        worstRank < bestWorstRank ||
        (worstRank == bestWorstRank &&
            candidate.isPrimary &&
            !bestCandidate.isPrimary);
    if (isBetter) {
      bestCandidate = candidate;
      bestClauses = clauses;
      bestWorstRank = worstRank;
    }
  }
  if (bestCandidate == null || bestClauses == null) return null;
  return _JsOrderedBranch(bestCandidate, bestClauses);
}

(int, List<_JsDispatchClause>)?
_evaluateCandidateAgainstRest<E extends ExecutableElement>(
  _JsOverloadCandidate<E> candidate,
  List<_JsOverloadCandidate<E>> remaining,
  TypeSystem typeSystem,
) {
  var worstRank = 0;
  final clausesByKey = <String, _JsDispatchClause>{};
  for (final other in remaining) {
    if (identical(candidate, other)) continue;
    final pairResult = _clausesForPair(candidate, other, typeSystem);
    if (pairResult == null) return null;
    final (rank, clauses) = pairResult;
    if (rank > worstRank) worstRank = rank;
    for (final clause in clauses) {
      clausesByKey.putIfAbsent(clause.dedupeKey, () => clause);
    }
  }
  return (worstRank, clausesByKey.values.toList());
}

(int, List<_JsDispatchClause>)? _clausesForPair<E extends ExecutableElement>(
  _JsOverloadCandidate<E> candidate,
  _JsOverloadCandidate<E> other,
  TypeSystem typeSystem,
) {
  final extraNonNull = _nonNullRequiredIndexBetween(
    other.maxArgs,
    candidate.minRequired,
    candidate,
  );
  if (extraNonNull != null) {
    return (0, [_JsParamNullClause(extraNonNull, expectNull: false)]);
  }
  final missingNonNull = _nonNullRequiredIndexBetween(
    candidate.maxArgs,
    other.minRequired,
    other,
  );
  if (missingNonNull != null) {
    return (0, [_JsParamNullClause(missingNonNull, expectNull: true)]);
  }
  return _typeClausesForPair(candidate, other, typeSystem);
}

(int, List<_JsDispatchClause>)?
_typeClausesForPair<E extends ExecutableElement>(
  _JsOverloadCandidate<E> candidate,
  _JsOverloadCandidate<E> other,
  TypeSystem typeSystem,
) {
  final firstOptional =
      candidate.minRequired < other.minRequired
          ? candidate.minRequired
          : other.minRequired;
  final maxShared =
      candidate.maxArgs < other.maxArgs ? candidate.maxArgs : other.maxArgs;

  final requiredClause = _bestRequiredTypeClause(
    candidate,
    other,
    firstOptional,
    typeSystem,
  );
  if (requiredClause != null) return requiredClause;

  if (firstOptional >= maxShared) return null;
  final firstParam = candidate.params[firstOptional];
  if (!firstParam.canEmitIsA ||
      !firstParam.isDisjointFrom(other.params[firstOptional], typeSystem)) {
    return null;
  }
  return _optionalTypeClauses(
    candidate,
    other,
    firstOptional,
    maxShared,
    typeSystem,
  );
}

(int, List<_JsDispatchClause>)?
_bestRequiredTypeClause<E extends ExecutableElement>(
  _JsOverloadCandidate<E> candidate,
  _JsOverloadCandidate<E> other,
  int firstOptional,
  TypeSystem typeSystem,
) {
  int? bestIndex;
  var bestRank = 999;
  for (var i = 0; i < firstOptional; i++) {
    final spec = candidate.params[i];
    if (!spec.canEmitIsA || !spec.isDisjointFrom(other.params[i], typeSystem)) {
      continue;
    }
    if (spec.specificityRank < bestRank) {
      bestRank = spec.specificityRank;
      bestIndex = i;
    }
  }
  if (bestIndex == null) return null;
  final allowNull = _shouldAllowNullAt(candidate, other, bestIndex);
  return (
    bestRank,
    [
      _JsParamTypeClause(
        bestIndex,
        candidate.params[bestIndex],
        allowNull: allowNull,
      ),
    ],
  );
}

(int, List<_JsDispatchClause>)
_optionalTypeClauses<E extends ExecutableElement>(
  _JsOverloadCandidate<E> candidate,
  _JsOverloadCandidate<E> other,
  int firstOptional,
  int maxShared,
  TypeSystem typeSystem,
) {
  var worstRank = 0;
  final clauses = <_JsDispatchClause>[];
  for (var i = firstOptional; i < maxShared; i++) {
    final spec = candidate.params[i];
    if (!spec.canEmitIsA || !spec.isDisjointFrom(other.params[i], typeSystem)) {
      continue;
    }
    if (spec.specificityRank > worstRank) worstRank = spec.specificityRank;
    final allowNull =
        i > firstOptional || _shouldAllowNullAt(candidate, other, i);
    clauses.add(_JsParamTypeClause(i, spec, allowNull: allowNull));
  }
  return (worstRank, clauses);
}

bool _shouldAllowNullAt<E extends ExecutableElement>(
  _JsOverloadCandidate<E> candidate,
  _JsOverloadCandidate<E> other,
  int index,
) {
  final cNull = candidate.acceptsNullAt(index);
  final oNull = other.acceptsNullAt(index);
  if (cNull && !oNull) return true;
  if (!cNull && oNull) return false;
  return candidate.isPrimary;
}

final class _JsSetterMultiplexer {
  final String jsName;
  final List<_JsOrderedBranch<SetterElement>> branches;

  const _JsSetterMultiplexer({required this.jsName, required this.branches});
}

final class _JsMethodMultiplexer {
  final String jsName;
  final List<_JsOrderedBranch<MethodElement>> branches;
  final int minRequired;
  final int maxArgs;
  final bool allSameReturn;

  const _JsMethodMultiplexer({
    required this.jsName,
    required this.branches,
    required this.minRequired,
    required this.maxArgs,
    required this.allSameReturn,
  });
}

final class _JsExportBucket {
  final String jsName;
  final getters = <GetterElement>[];
  final setters = <SetterElement>[];
  final methods = <MethodElement>[];

  _JsExportBucket(this.jsName);
}

final class _JsBucketPlan {
  final Map<ExecutableElement, String> disambiguatedExports;
  final _JsSetterMultiplexer? setterMultiplexer;
  final _JsMethodMultiplexer? methodMultiplexer;
  final List<String> errors;

  const _JsBucketPlan({
    this.disambiguatedExports = const {},
    this.setterMultiplexer,
    this.methodMultiplexer,
    this.errors = const [],
  });
}

/// Planned `@JSExport` key disambiguations, multiplexer members, and collision
/// diagnostics for a mocked JS interop extension type.
final class JsExportPlan {
  final Map<ExecutableElement, String> disambiguatedExports;
  final List<String> errorMessages;
  final List<_JsSetterMultiplexer> _setterMultiplexers;
  final List<_JsMethodMultiplexer> _methodMultiplexers;
  final TypeSystem _typeSystem;

  const JsExportPlan._({
    required this.disambiguatedExports,
    required this.errorMessages,
    required List<_JsSetterMultiplexer> setterMultiplexers,
    required List<_JsMethodMultiplexer> methodMultiplexers,
    required TypeSystem typeSystem,
  }) : _setterMultiplexers = setterMultiplexers,
       _methodMultiplexers = methodMultiplexers,
       _typeSystem = typeSystem;

  factory JsExportPlan.analyze({
    required String interfaceName,
    required Iterable<ExecutableElement> members,
    required Set<String> unsupportedMembers,
    required Map<String, ExecutableElement> fallbackGenerators,
    required TypeSystem typeSystem,
  }) {
    final disambiguated = <ExecutableElement, String>{};
    final buckets = <String, _JsExportBucket>{};

    for (final member in members) {
      if (!isExportableJsInteropMember(member)) continue;
      final unsupportedKey = _memberUnsupportedKey(member);
      if (unsupportedMembers.contains(unsupportedKey) &&
          !fallbackGenerators.containsKey(unsupportedKey)) {
        disambiguated[member] = _disambiguatedExportKey(member);
        continue;
      }
      final jsName = _effectiveJsExportName(member);
      final bucket = buckets.putIfAbsent(jsName, () => _JsExportBucket(jsName));
      switch (member) {
        case GetterElement():
          bucket.getters.add(member);
        case SetterElement():
          bucket.setters.add(member);
        case MethodElement():
          bucket.methods.add(member);
      }
    }

    final setterMuxes = <_JsSetterMultiplexer>[];
    final methodMuxes = <_JsMethodMultiplexer>[];
    final errors = <String>[];

    for (final bucket in buckets.values) {
      final bucketPlan = _analyzeBucket(bucket, typeSystem, interfaceName);
      disambiguated.addAll(bucketPlan.disambiguatedExports);
      if (bucketPlan.setterMultiplexer case final setterMux?) {
        setterMuxes.add(setterMux);
      }
      if (bucketPlan.methodMultiplexer case final methodMux?) {
        methodMuxes.add(methodMux);
      }
      errors.addAll(bucketPlan.errors);
    }

    return JsExportPlan._(
      disambiguatedExports: disambiguated,
      errorMessages: errors,
      setterMultiplexers: setterMuxes,
      methodMultiplexers: methodMuxes,
      typeSystem: typeSystem,
    );
  }

  /// Generates `@JSExport` setter and method multiplexers for colliding
  /// overloads using [typeReference] to resolve types in the target library.
  Iterable<Method> buildMultiplexers(JsTypeReferenceResolver typeReference) =>
      _JsMultiplexerBuilder(_typeSystem, typeReference).buildAll(
        setterMultiplexers: _setterMultiplexers,
        methodMultiplexers: _methodMultiplexers,
      );
}

_JsBucketPlan _analyzeBucket(
  _JsExportBucket bucket,
  TypeSystem typeSystem,
  String interfaceName,
) {
  final mixedError = _checkMethodAccessorConflict(bucket, interfaceName);
  if (mixedError != null) {
    return _JsBucketPlan(errors: [mixedError]);
  }

  final errors = <String>[
    if (_checkGetterConflict(bucket, interfaceName) case final getterError?)
      getterError,
  ];
  final disambiguated = <ExecutableElement, String>{};

  final (setterMux, setterError) = _planBucketSetters(
    bucket,
    typeSystem,
    interfaceName,
  );
  if (setterError != null) {
    errors.add(setterError);
  } else if (setterMux != null) {
    for (final setter in bucket.setters) {
      disambiguated[setter] = _disambiguatedExportKey(setter);
    }
  }

  final (methodMux, methodError) = _planBucketMethods(
    bucket,
    typeSystem,
    interfaceName,
  );
  if (methodError != null) {
    errors.add(methodError);
  } else if (methodMux != null) {
    for (final method in bucket.methods) {
      disambiguated[method] = _disambiguatedExportKey(method);
    }
  }

  return _JsBucketPlan(
    disambiguatedExports: disambiguated,
    setterMultiplexer: setterMux,
    methodMultiplexer: methodMux,
    errors: errors,
  );
}

String? _checkMethodAccessorConflict(
  _JsExportBucket bucket,
  String interfaceName,
) {
  if (bucket.methods.isEmpty ||
      (bucket.getters.isEmpty && bucket.setters.isEmpty)) {
    return null;
  }
  final all = <ExecutableElement>[
    ...bucket.getters,
    ...bucket.setters,
    ...bucket.methods,
  ];
  final names = all.map((m) => "'${m.displayName}'").join(', ');
  final symbols = all.skip(1).map(_memberSymbolLiteral).join(', ');
  return "The external members $names on '$interfaceName' export the same JS "
      "property '${bucket.jsName}' as both a method and a property accessor. "
      'Exclude conflicting members using '
      'MockSpec(unsupportedMembers: {$symbols}).';
}

String? _checkGetterConflict(_JsExportBucket bucket, String interfaceName) {
  if (bucket.getters.length <= 1) return null;
  final names = bucket.getters.map((g) => "'${g.displayName}'").join(', ');
  final symbols = bucket.getters.skip(1).map(_memberSymbolLiteral).join(', ');
  return "The external getters $names on '$interfaceName' export the same JS "
      "property '${bucket.jsName}' and cannot both be mocked. "
      'Exclude all but one using MockSpec(unsupportedMembers: {$symbols}).';
}

(_JsSetterMultiplexer?, String?) _planBucketSetters(
  _JsExportBucket bucket,
  TypeSystem typeSystem,
  String interfaceName,
) {
  if (bucket.setters.length <= 1) return (null, null);
  final mux = _analyzeSetterOverloads(bucket, typeSystem);
  if (mux != null) return (mux, null);
  final names = bucket.setters.map((s) => "'${s.displayName}'").join(', ');
  final symbols = bucket.setters.skip(1).map(_memberSymbolLiteral).join(', ');
  return (
    null,
    "The external setters $names on '$interfaceName' export the same JS "
        "property '${bucket.jsName}' with parameter types that cannot be "
        'distinguished at runtime. Exclude all but one using '
        'MockSpec(unsupportedMembers: {$symbols}).',
  );
}

(_JsMethodMultiplexer?, String?) _planBucketMethods(
  _JsExportBucket bucket,
  TypeSystem typeSystem,
  String interfaceName,
) {
  if (bucket.methods.length <= 1) return (null, null);
  final mux = _analyzeMethodOverloads(bucket, typeSystem);
  if (mux != null) return (mux, null);
  final names = bucket.methods.map((m) => "'${m.displayName}'").join(', ');
  final symbols = bucket.methods.skip(1).map(_memberSymbolLiteral).join(', ');
  return (
    null,
    "The external methods $names on '$interfaceName' export the same JS "
        "property '${bucket.jsName}' with signatures that cannot be "
        'distinguished at runtime. Exclude conflicting overloads using '
        'MockSpec(unsupportedMembers: {$symbols}).',
  );
}

_JsSetterMultiplexer? _analyzeSetterOverloads(
  _JsExportBucket bucket,
  TypeSystem typeSystem,
) {
  final candidates = [
    for (final setter in bucket.setters)
      _JsOverloadCandidate<SetterElement>(
        element: setter,
        params: [
          _classifyJsParam(setter.formalParameters.single.type, typeSystem),
        ],
        minRequired: 1,
        isPrimary: setter.displayName == bucket.jsName,
      ),
  ];
  final branches = _orderOverloadBranches(candidates, typeSystem);
  if (branches == null) return null;
  return _JsSetterMultiplexer(jsName: bucket.jsName, branches: branches);
}

_JsMethodMultiplexer? _analyzeMethodOverloads(
  _JsExportBucket bucket,
  TypeSystem typeSystem,
) {
  if (bucket.methods.any((m) => m.formalParameters.any((p) => p.isNamed))) {
    return null;
  }
  final allSameReturn = _haveIdenticalReturnType(bucket.methods, typeSystem);
  if (!allSameReturn &&
      bucket.methods.any((m) => !_canBoxJsReturn(m.returnType))) {
    return null;
  }
  final candidates = [
    for (final method in bucket.methods)
      _JsOverloadCandidate<MethodElement>(
        element: method,
        params: [
          for (final param in method.formalParameters)
            _classifyJsParam(param.type, typeSystem),
        ],
        minRequired:
            method.formalParameters.where((p) => p.isRequiredPositional).length,
        isPrimary: method.displayName == bucket.jsName,
      ),
  ];
  final branches = _orderOverloadBranches(candidates, typeSystem);
  if (branches == null) return null;

  var minReq = candidates.first.minRequired;
  var maxPos = candidates.first.maxArgs;
  for (final c in candidates.skip(1)) {
    if (c.minRequired < minReq) minReq = c.minRequired;
    if (c.maxArgs > maxPos) maxPos = c.maxArgs;
  }
  return _JsMethodMultiplexer(
    jsName: bucket.jsName,
    branches: branches,
    minRequired: minReq,
    maxArgs: maxPos,
    allSameReturn: allSameReturn,
  );
}

bool _haveIdenticalReturnType(
  List<MethodElement> methods,
  TypeSystem typeSystem,
) {
  final first = methods.first.returnType;
  final firstIsVoid = first is analyzer.VoidType;
  for (final m in methods.skip(1)) {
    final current = m.returnType;
    final currentIsVoid = current is analyzer.VoidType;
    if (firstIsVoid != currentIsVoid) return false;
    if (firstIsVoid) continue;
    if (!typeSystem.isSubtypeOf(first, current) ||
        !typeSystem.isSubtypeOf(current, first)) {
      return false;
    }
  }
  return true;
}

bool _canBoxJsReturn(analyzer.DartType type) {
  if (type is analyzer.VoidType || type.isDartCoreNull) return true;
  if (type.isDartCoreString ||
      type.isDartCoreBool ||
      type.isDartCoreInt ||
      type.isDartCoreDouble ||
      type.isDartCoreNum) {
    return true;
  }
  if (type is analyzer.TypeParameterType) {
    final bound = type.bound;
    return _implementsJsAny(bound) || _erasesToJsObject(bound);
  }
  if (type is analyzer.InterfaceType) {
    if (_isSdkJsInteropType(type.element, 'ExternalDartReference')) {
      return false;
    }
    final element = type.element;
    return element is ExtensionTypeElement && element.isJSInteropType;
  }
  return false;
}

final class _JsMultiplexerBuilder {
  final TypeSystem typeSystem;
  final JsTypeReferenceResolver _typeReference;

  const _JsMultiplexerBuilder(this.typeSystem, this._typeReference);

  Iterable<Method> buildAll({
    required List<_JsSetterMultiplexer> setterMultiplexers,
    required List<_JsMethodMultiplexer> methodMultiplexers,
  }) sync* {
    for (final mux in setterMultiplexers) {
      yield _buildSetterMultiplexer(mux);
    }
    for (final mux in methodMultiplexers) {
      yield _buildMethodMultiplexer(mux);
    }
  }

  TypeReference _nullableJsAnyRef() => TypeReference(
    (b) =>
        b
          ..symbol = 'JSAny'
          ..url = 'dart:js_interop'
          ..isNullable = true,
  );

  Method _buildSetterMultiplexer(_JsSetterMultiplexer mux) {
    final safeName = _safeJsIdentifier(mux.jsName);
    const paramName = '_value';
    return Method((mBuilder) {
      mBuilder
        ..name = '\$jsExport\$set\$$safeName'
        ..type = MethodType.setter
        ..annotations.add(
          _referImported(
            'JSExport',
            'dart:js_interop',
          ).call([jsExportLiteral(mux.jsName)]),
        )
        ..requiredParameters.add(
          Parameter(
            (p) =>
                p
                  ..name = paramName
                  ..type = _nullableJsAnyRef(),
          ),
        )
        ..body = _buildBranchChain(
          mux.branches,
          const [paramName],
          (candidate) =>
              _refer(candidate.element.displayName)
                  .assign(
                    _convertArgExpression(paramName, candidate.params.single),
                  )
                  .statement,
        );
    });
  }

  Method _buildMethodMultiplexer(_JsMethodMultiplexer mux) {
    final safeName = _safeJsIdentifier(mux.jsName);
    final paramNames = [for (var i = 0; i < mux.maxArgs; i++) '_p$i'];
    final firstReturn = mux.branches.first.candidate.element.returnType;
    return Method((mBuilder) {
      mBuilder
        ..name = '\$jsExport\$method\$$safeName'
        ..annotations.add(
          _referImported(
            'JSExport',
            'dart:js_interop',
          ).call([jsExportLiteral(mux.jsName)]),
        )
        ..returns =
            mux.allSameReturn
                ? _typeReference(firstReturn)
                : _nullableJsAnyRef();
      for (var i = 0; i < mux.maxArgs; i++) {
        final param = Parameter(
          (p) =>
              p
                ..name = paramNames[i]
                ..type = _nullableJsAnyRef(),
        );
        if (i < mux.minRequired) {
          mBuilder.requiredParameters.add(param);
        } else {
          mBuilder.optionalParameters.add(param);
        }
      }
      mBuilder.body = _buildBranchChain(
        mux.branches,
        paramNames,
        (candidate) => _emitMethodBranchBody(
          candidate,
          paramNames,
          allSameReturn: mux.allSameReturn,
        ),
      );
    });
  }

  Code _emitMethodBranchBody(
    _JsOverloadCandidate<MethodElement> candidate,
    List<String> paramNames, {
    required bool allSameReturn,
  }) {
    final method = candidate.element;
    final args = [
      for (var i = 0; i < candidate.params.length; i++)
        _convertArgExpression(paramNames[i], candidate.params[i]),
    ];
    final callExpr = _refer(method.displayName).call(args);
    final returnType = method.returnType;
    if (allSameReturn) {
      return returnType is analyzer.VoidType
          ? callExpr.statement
          : callExpr.returned.statement;
    }
    if (returnType is analyzer.VoidType) {
      return Block.of([callExpr.statement, literalNull.returned.statement]);
    }
    if (returnType.isDartCoreString ||
        returnType.isDartCoreBool ||
        returnType.isDartCoreInt ||
        returnType.isDartCoreDouble ||
        returnType.isDartCoreNum) {
      final boxed =
          typeSystem.isNullable(returnType)
              ? callExpr.nullSafeProperty('toJS')
              : callExpr.property('toJS');
      return boxed.returned.statement;
    }
    if (_implementsJsAny(returnType)) {
      return callExpr.returned.statement;
    }
    return callExpr.asA(_nullableJsAnyRef()).returned.statement;
  }

  Code _buildBranchChain<E extends ExecutableElement>(
    List<_JsOrderedBranch<E>> branches,
    List<String> paramNames,
    Code Function(_JsOverloadCandidate<E>) buildLeaf,
  ) {
    final parts = <Code>[];
    for (var i = 0; i < branches.length; i++) {
      final branch = branches[i];
      if (i == 0) {
        parts
          ..add(const Code('if ('))
          ..add(_emitCondition(branch.clauses, paramNames).code)
          ..add(const Code(') {\n'))
          ..add(buildLeaf(branch.candidate))
          ..add(const Code('\n}'));
      } else if (i < branches.length - 1) {
        parts
          ..add(const Code(' else if ('))
          ..add(_emitCondition(branch.clauses, paramNames).code)
          ..add(const Code(') {\n'))
          ..add(buildLeaf(branch.candidate))
          ..add(const Code('\n}'));
      } else {
        parts
          ..add(const Code(' else {\n'))
          ..add(buildLeaf(branch.candidate))
          ..add(const Code('\n}'));
      }
    }
    return Block.of(parts);
  }

  Expression _emitCondition(
    List<_JsDispatchClause> clauses,
    List<String> paramNames,
  ) {
    var combined = _emitSingleClause(clauses.first, paramNames);
    for (final clause in clauses.skip(1)) {
      combined = combined.and(_emitSingleClause(clause, paramNames));
    }
    return combined;
  }

  Expression _emitSingleClause(
    _JsDispatchClause clause,
    List<String> paramNames,
  ) {
    final paramRef = _refer(paramNames[clause.paramIndex]);
    switch (clause) {
      case _JsParamNullClause(:final expectNull):
        return expectNull
            ? paramRef.equalTo(literalNull)
            : paramRef.notEqualTo(literalNull);
      case _JsParamTypeClause(:final spec, :final allowNull):
        final checkTypeRef =
            spec.sdkCheckSymbol != null
                ? TypeReference(
                  (b) =>
                      b
                        ..symbol = spec.sdkCheckSymbol!
                        ..url = 'dart:js_interop'
                        ..isNullable = allowNull,
                )
                : _typeReference(
                  typeSystem.promoteToNonNull(spec.originalType),
                  forceNullable: allowNull,
                );
        return paramRef.property('isA').call([], const {}, [checkTypeRef]);
    }
  }

  Expression _convertArgExpression(String paramName, _JsParamSpec spec) {
    final paramRef = _refer(paramName);
    final targetType = spec.originalType;
    final coreType = _unwrapNonJsExtensionType(targetType);
    if (coreType.isDartCoreString) {
      return _unboxSdkPrimitive(paramRef, 'JSString', 'toDart');
    }
    if (coreType.isDartCoreBool) {
      return _unboxSdkPrimitive(paramRef, 'JSBoolean', 'toDart');
    }
    if (coreType.isDartCoreInt) {
      return _unboxSdkPrimitive(paramRef, 'JSNumber', 'toDartInt');
    }
    if (coreType.isDartCoreDouble || coreType.isDartCoreNum) {
      return _unboxSdkPrimitive(paramRef, 'JSNumber', 'toDartDouble');
    }
    if (_isSdkJsInteropType(targetType.element, 'JSAny')) {
      return paramRef;
    }
    return paramRef.asA(
      _typeReference(targetType, forceNullable: true, overrideVoid: true),
    );
  }

  Expression _unboxSdkPrimitive(
    Expression paramRef,
    String sdkSymbol,
    String getterName,
  ) => paramRef
      .asA(
        TypeReference(
          (b) =>
              b
                ..symbol = sdkSymbol
                ..url = 'dart:js_interop'
                ..isNullable = true,
        ),
      )
      .nullSafeProperty(getterName);
}

/// JS interop classification helpers for analyzer [ExtensionTypeElement]s.
extension JsInteropExtensionTypeElement on ExtensionTypeElement {
  bool get isSdkJSInteropType {
    final uri = library.uri.toString();
    return uri == 'dart:js_interop' || uri == 'dart:js_interop_unsafe';
  }

  bool get isJSInteropType {
    Element? element = this;
    while (element is ExtensionTypeElement) {
      if (element.isSdkJSInteropType) return true;
      element = element.representation.type.element;
    }
    return false;
  }
}
