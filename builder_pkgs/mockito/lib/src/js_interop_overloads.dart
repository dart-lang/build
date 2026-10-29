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

import 'dart:math' as math;

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

typedef _JsOrderedBranch<E extends ExecutableElement> =
    ({_JsOverloadCandidate<E> candidate, List<_JsDispatchClause> clauses});

typedef _JsSetterMultiplexer =
    ({String jsName, List<_JsOrderedBranch<SetterElement>> branches});

typedef _JsMethodMultiplexer =
    ({
      String jsName,
      List<_JsOrderedBranch<MethodElement>> branches,
      int minRequired,
      int maxArgs,
      bool allSameReturn,
    });

final _nonIdentifierRegExp = RegExp(r'[^a-zA-Z0-9_]');

const _sdkPrimitiveSymbols = {
  'JSString',
  'JSBoolean',
  'JSNumber',
  'JSBigInt',
  'JSSymbol',
};

const _typedArrayJsNames = {
  'Int8Array',
  'Uint8Array',
  'Uint8ClampedArray',
  'Int16Array',
  'Uint16Array',
  'Int32Array',
  'Uint32Array',
  'BigInt64Array',
  'BigUint64Array',
  'Float16Array',
  'Float32Array',
  'Float64Array',
};

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
  _nonIdentifierRegExp,
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
  cannotMultiplex,
}

final class _JsParamSpec {
  final analyzer.DartType originalType;
  final _JsCheckCategory category;
  final String jsName;
  final String? sdkCheckSymbol;
  final bool isNullable;
  final bool canEmitIsA;

  const _JsParamSpec.uncheckable(
    this.originalType,
    this.category, {
    required this.isNullable,
  }) : jsName = '',
       sdkCheckSymbol = null,
       canEmitIsA = false;

  const _JsParamSpec.sdk(
    this.originalType,
    this.category,
    String symbol, {
    required this.isNullable,
  }) : jsName = symbol,
       sdkCheckSymbol = symbol,
       canEmitIsA = true;

  const _JsParamSpec.nominal(
    this.originalType,
    this.category,
    this.jsName, {
    required this.isNullable,
  }) : sdkCheckSymbol = null,
       canEmitIsA = true;

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

  bool isDisjointFrom(_JsParamSpec other, TypeSystem typeSystem) => switch ((
    category,
    other.category,
  )) {
    (_JsCheckCategory.primitive, _JsCheckCategory.primitive) ||
    (
      _JsCheckCategory.builtinObject,
      _JsCheckCategory.builtinObject,
    ) => jsName != other.jsName,
    (_JsCheckCategory.primitive, _) => other._isObjectCategory,
    (_, _JsCheckCategory.primitive) => _isObjectCategory,
    (_JsCheckCategory.builtinObject, _JsCheckCategory.nominalObject) =>
      _isBuiltinDisjointFromNominal(this, other, typeSystem),
    (_JsCheckCategory.nominalObject, _JsCheckCategory.builtinObject) =>
      _isBuiltinDisjointFromNominal(other, this, typeSystem),
    (_JsCheckCategory.nominalObject, _JsCheckCategory.nominalObject) =>
      _areNominalDisjoint(this, other, typeSystem),
    _ => false,
  };
}

bool _isBuiltinDisjointFromNominal(
  _JsParamSpec builtin,
  _JsParamSpec nominal,
  TypeSystem typeSystem,
) {
  final nominalNonNull = typeSystem.promoteToNonNull(nominal.originalType);
  final jsName = nominal.jsName;
  return switch (builtin.sdkCheckSymbol) {
    'JSArray' =>
      jsName != 'Array' &&
          !_wrapsOrImplementsSdkType(nominalNonNull, 'JSArray'),
    'JSTypedArray' =>
      !_typedArrayJsNames.contains(jsName) &&
          !_wrapsOrImplementsSdkType(nominalNonNull, 'JSTypedArray'),
    'JSExportedDartFunction' =>
      jsName != 'Function' &&
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
  if (a.jsName == b.jsName) return false;
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

bool _implementsSdkType(analyzer.InterfaceType type, String sdkName) =>
    _isSdkJsInteropType(type.element, sdkName) ||
    type.allSupertypes.any((s) => _isSdkJsInteropType(s.element, sdkName));

bool _wrapsExtensionElement(analyzer.DartType type, Element? target) {
  final element = type.element;
  if (target == null || element is! ExtensionTypeElement) return false;
  final targetBase = target.baseElement;
  return element._representationChain.any((e) => e.baseElement == targetBase);
}

bool _wrapsOrImplementsSdkType(analyzer.DartType type, String sdkName) {
  if (type is! analyzer.InterfaceType) return false;
  if (_implementsSdkType(type, sdkName)) return true;
  final element = type.element;
  return element is ExtensionTypeElement &&
      element._representationChain.any(
        (e) => _implementsSdkType(e.thisType, sdkName),
      );
}

bool _implementsJsAny(analyzer.DartType type) => switch (type) {
  _ when type.isDartCoreNull => true,
  analyzer.TypeParameterType(:final bound) => _implementsJsAny(bound),
  final analyzer.InterfaceType iface => _implementsSdkType(iface, 'JSAny'),
  _ => false,
};

bool _erasesToJsObject(analyzer.DartType? type) => switch (type) {
  null => false,
  analyzer.TypeParameterType(:final bound) => _erasesToJsObject(bound),
  _ => _wrapsOrImplementsSdkType(type, 'JSObject'),
};

String? _corePrimitiveSymbol(analyzer.DartType type) => switch (type) {
  _ when type.isDartCoreString => 'String',
  _ when type.isDartCoreBool => 'bool',
  _ when type.isDartCoreInt => 'int',
  _ when type.isDartCoreDouble => 'double',
  _ when type.isDartCoreNum => 'num',
  _ => null,
};

(analyzer.DartType, {bool isNullable}) _unwrapNonJsExtensionType(
  analyzer.DartType type,
  TypeSystem typeSystem,
) {
  var current = type;
  var isNullable = typeSystem.isNullable(current);
  while (current is analyzer.InterfaceType &&
      current.element is ExtensionTypeElement &&
      !(current.element as ExtensionTypeElement).isJSInteropType) {
    final ext = current.element as ExtensionTypeElement;
    current = Substitution.fromInterfaceType(
      current,
    ).substituteType(ext.representation.type);
    if (typeSystem.isNullable(current)) isNullable = true;
  }
  return (current, isNullable: isNullable);
}

_JsParamSpec _classifyJsParam(analyzer.DartType type, TypeSystem typeSystem) {
  final (coreType, :isNullable) = _unwrapNonJsExtensionType(type, typeSystem);
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
  if (coreType.isDartCoreNull) {
    return _JsParamSpec.uncheckable(
      originalType,
      _JsCheckCategory.top,
      isNullable: true,
    );
  }
  final sdkPrimitive = switch (_corePrimitiveSymbol(coreType)) {
    'String' => 'JSString',
    'bool' => 'JSBoolean',
    'int' || 'double' || 'num' => 'JSNumber',
    _ => null,
  };
  if (sdkPrimitive != null) {
    return _JsParamSpec.sdk(
      originalType,
      _JsCheckCategory.primitive,
      sdkPrimitive,
      isNullable: isNullable,
    );
  }
  if (coreType is analyzer.TypeParameterType) {
    final category =
        _erasesToJsObject(coreType.bound)
            ? _JsCheckCategory.broadObject
            : _JsCheckCategory.top;
    return _JsParamSpec.uncheckable(
      originalType,
      category,
      isNullable: isNullable,
    );
  }
  return null;
}

_JsParamSpec _classifyInterfaceJsType(
  analyzer.DartType coreType,
  analyzer.DartType originalType, {
  required bool isNullable,
}) {
  if (coreType is! analyzer.InterfaceType ||
      _wrapsOrImplementsSdkType(coreType, 'ExternalDartReference') ||
      coreType.element is! ExtensionTypeElement ||
      !(coreType.element as ExtensionTypeElement).isJSInteropType) {
    return _JsParamSpec.uncheckable(
      originalType,
      _JsCheckCategory.cannotMultiplex,
      isNullable: isNullable,
    );
  }
  final element = coreType.element as ExtensionTypeElement;
  if (_classifySdkPrimitiveOrBuiltin(
        element,
        originalType,
        isNullable: isNullable,
      )
      case final sdkSpec?) {
    return sdkSpec;
  }
  if (!_erasesToJsObject(coreType)) {
    return _JsParamSpec.uncheckable(
      originalType,
      _JsCheckCategory.top,
      isNullable: isNullable,
    );
  }
  return _classifyNominalOrObjectLiteral(
    element,
    originalType,
    isNullable: isNullable,
  );
}

_JsParamSpec? _classifySdkPrimitiveOrBuiltin(
  ExtensionTypeElement element,
  analyzer.DartType originalType, {
  required bool isNullable,
}) {
  for (final ext in element._representationChain) {
    if (ext.library.uri.toString() == 'dart:js_interop' &&
        _sdkPrimitiveSymbols.contains(ext.name)) {
      return _JsParamSpec.sdk(
        originalType,
        _JsCheckCategory.primitive,
        ext.name!,
        isNullable: isNullable,
      );
    }
  }
  if (element.library.uri.toString() != 'dart:js_interop') return null;
  final name = element.name;
  return switch (name) {
    'JSAny' => _JsParamSpec.uncheckable(
      originalType,
      _JsCheckCategory.top,
      isNullable: isNullable,
    ),
    'JSObject' => _JsParamSpec.sdk(
      originalType,
      _JsCheckCategory.broadObject,
      'JSObject',
      isNullable: isNullable,
    ),
    'JSArray' ||
    'JSTypedArray' ||
    'JSExportedDartFunction' ||
    'JSBoxedDartObject' => _JsParamSpec.sdk(
      originalType,
      _JsCheckCategory.builtinObject,
      name!,
      isNullable: isNullable,
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
    return _JsParamSpec.uncheckable(
      originalType,
      _JsCheckCategory.broadObject,
      isNullable: isNullable,
    );
  }
  final typeJsName = jsInteropAnnotationName(element) ?? element.name!;
  final libJsName = jsInteropAnnotationName(element.library);
  final jsName = libJsName == null ? typeJsName : '$libJsName.$typeJsName';
  final category =
      jsName == 'Object'
          ? _JsCheckCategory.broadObject
          : _JsCheckCategory.nominalObject;
  return _JsParamSpec.nominal(
    originalType,
    category,
    jsName,
    isNullable: isNullable,
  );
}

final class _JsDispatchClause {
  final int paramIndex;
  final _JsParamSpec? spec;
  final bool flag;

  const _JsDispatchClause.nullCheck(this.paramIndex, {required bool expectNull})
    : spec = null,
      flag = expectNull;

  const _JsDispatchClause.typeCheck(
    this.paramIndex,
    _JsParamSpec this.spec, {
    required bool allowNull,
  }) : flag = allowNull;

  String get dedupeKey {
    final s = spec;
    if (s == null) return 'null:$paramIndex:$flag';
    final kind =
        s.sdkCheckSymbol != null
            ? 'sdk:${s.sdkCheckSymbol}'
            : 'nom:${s.jsName}';
    return 'type:$paramIndex:$flag:$kind';
  }
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

List<_JsOrderedBranch<E>>? _orderOverloadBranches<E extends ExecutableElement>(
  List<_JsOverloadCandidate<E>> candidates,
  TypeSystem typeSystem,
) {
  if (candidates.any(
    (c) => c.params.any((p) => p.category == _JsCheckCategory.cannotMultiplex),
  )) {
    return null;
  }
  final remaining = [
    ...candidates.where((c) => c.isPrimary),
    ...candidates.where((c) => !c.isPrimary),
  ];
  final ordered = <_JsOrderedBranch<E>>[];
  while (remaining.length > 1) {
    final next = _selectNextBranch(remaining, typeSystem);
    if (next == null) return null;
    ordered.add(next);
    remaining.remove(next.candidate);
  }
  ordered.add((candidate: remaining.single, clauses: const []));
  return ordered;
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
    if (bestCandidate == null || worstRank < bestWorstRank) {
      bestCandidate = candidate;
      bestClauses = clauses;
      bestWorstRank = worstRank;
    }
  }
  if (bestCandidate == null || bestClauses == null) return null;
  return (candidate: bestCandidate, clauses: bestClauses);
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
  if (_nonNullRequiredIndexBetween(
        other.maxArgs,
        candidate.minRequired,
        candidate,
      )
      case final extraNonNull?) {
    return (0, [_JsDispatchClause.nullCheck(extraNonNull, expectNull: false)]);
  }
  if (_nonNullRequiredIndexBetween(candidate.maxArgs, other.minRequired, other)
      case final missingNonNull?) {
    return (0, [_JsDispatchClause.nullCheck(missingNonNull, expectNull: true)]);
  }
  return _requiredTypeClause(candidate, other, typeSystem) ??
      _optionalTypeClauses(candidate, other, typeSystem);
}

(int, List<_JsDispatchClause>)?
_requiredTypeClause<E extends ExecutableElement>(
  _JsOverloadCandidate<E> candidate,
  _JsOverloadCandidate<E> other,
  TypeSystem typeSystem,
) {
  final firstOptional = math.min(candidate.minRequired, other.minRequired);
  int? bestIndex;
  var bestRank = 999;
  for (var i = 0; i < firstOptional; i++) {
    final spec = candidate.params[i];
    if (spec.canEmitIsA &&
        spec.isDisjointFrom(other.params[i], typeSystem) &&
        spec.specificityRank < bestRank) {
      bestRank = spec.specificityRank;
      bestIndex = i;
    }
  }
  if (bestIndex == null) return null;
  return (
    bestRank,
    [
      _JsDispatchClause.typeCheck(
        bestIndex,
        candidate.params[bestIndex],
        allowNull: _shouldAllowNullAt(candidate, other, bestIndex),
      ),
    ],
  );
}

(int, List<_JsDispatchClause>)?
_optionalTypeClauses<E extends ExecutableElement>(
  _JsOverloadCandidate<E> candidate,
  _JsOverloadCandidate<E> other,
  TypeSystem typeSystem,
) {
  final firstOptional = math.min(candidate.minRequired, other.minRequired);
  final maxShared = math.min(candidate.maxArgs, other.maxArgs);
  if (firstOptional >= maxShared) return null;
  final firstSpec = candidate.params[firstOptional];
  if (!firstSpec.canEmitIsA ||
      !firstSpec.isDisjointFrom(other.params[firstOptional], typeSystem)) {
    return null;
  }
  var worstRank = 0;
  final clauses = <_JsDispatchClause>[];
  for (var i = firstOptional; i < maxShared; i++) {
    final spec = candidate.params[i];
    if (!spec.canEmitIsA || !spec.isDisjointFrom(other.params[i], typeSystem)) {
      continue;
    }
    if (spec.specificityRank > worstRank) worstRank = spec.specificityRank;
    final allowNull =
        i == firstOptional
            ? _shouldAllowNullAt(candidate, other, i)
            : candidate.acceptsNullAt(i);
    clauses.add(_JsDispatchClause.typeCheck(i, spec, allowNull: allowNull));
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
  return cNull != oNull ? cNull : candidate.isPrimary;
}

final class _JsExportBucket {
  final String jsName;
  final getters = <GetterElement>[];
  final setters = <SetterElement>[];
  final methods = <MethodElement>[];
  final unsupported = <ExecutableElement>[];

  _JsExportBucket(this.jsName);
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
    final buckets = <String, _JsExportBucket>{};
    for (final member in members) {
      if (!isExportableJsInteropMember(member)) continue;
      final jsName = _effectiveJsExportName(member);
      final bucket = buckets.putIfAbsent(jsName, () => _JsExportBucket(jsName));
      final unsupportedKey = _memberUnsupportedKey(member);
      if (unsupportedMembers.contains(unsupportedKey) &&
          !fallbackGenerators.containsKey(unsupportedKey)) {
        bucket.unsupported.add(member);
      } else {
        switch (member) {
          case GetterElement():
            bucket.getters.add(member);
          case SetterElement():
            bucket.setters.add(member);
          case MethodElement():
            bucket.methods.add(member);
        }
      }
    }

    final disambiguated = <ExecutableElement, String>{};
    final setterMuxes = <_JsSetterMultiplexer>[];
    final methodMuxes = <_JsMethodMultiplexer>[];
    final errors = <String>[];

    for (final bucket in buckets.values) {
      _analyzeBucket(
        bucket,
        typeSystem: typeSystem,
        interfaceName: interfaceName,
        disambiguated: disambiguated,
        setterMuxes: setterMuxes,
        methodMuxes: methodMuxes,
        errors: errors,
      );
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

void _analyzeBucket(
  _JsExportBucket bucket, {
  required TypeSystem typeSystem,
  required String interfaceName,
  required Map<ExecutableElement, String> disambiguated,
  required List<_JsSetterMultiplexer> setterMuxes,
  required List<_JsMethodMultiplexer> methodMuxes,
  required List<String> errors,
}) {
  if (_checkMethodAccessorConflict(bucket, interfaceName)
      case final mixedError?) {
    errors.add(mixedError);
    return;
  }
  if (_checkGetterConflict(bucket, interfaceName) case final getterError?) {
    errors.add(getterError);
  }

  final (setterMux, setterError) = _planBucketSetters(
    bucket,
    typeSystem,
    interfaceName,
  );
  if (setterError != null) {
    errors.add(setterError);
  } else if (setterMux != null) {
    setterMuxes.add(setterMux);
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
    methodMuxes.add(methodMux);
    for (final method in bucket.methods) {
      disambiguated[method] = _disambiguatedExportKey(method);
    }
  }

  _disambiguateUnsupportedInBucket(bucket, disambiguated);
}

void _disambiguateUnsupportedInBucket(
  _JsExportBucket bucket,
  Map<ExecutableElement, String> disambiguated,
) {
  if (bucket.unsupported.isEmpty) return;
  var hasGetter = bucket.getters.isNotEmpty;
  var hasSetter = bucket.setters.isNotEmpty;
  var hasMethod = bucket.methods.isNotEmpty;
  final ordered = [
    ...bucket.unsupported.where((m) => m.displayName == bucket.jsName),
    ...bucket.unsupported.where((m) => m.displayName != bucket.jsName),
  ];
  for (final member in ordered) {
    final canKeepJsName = switch (member) {
      GetterElement() => !hasGetter && !hasMethod,
      SetterElement() => !hasSetter && !hasMethod,
      _ => !hasMethod && !hasGetter && !hasSetter,
    };
    if (!canKeepJsName) {
      disambiguated[member] = _disambiguatedExportKey(member);
      continue;
    }
    switch (member) {
      case GetterElement():
        hasGetter = true;
      case SetterElement():
        hasSetter = true;
      default:
        hasMethod = true;
    }
  }
}

String _formatBucketConflict(
  List<ExecutableElement> members,
  String Function(String names) describeConflict, {
  String action = 'Exclude all but one',
}) {
  final names = members.map((m) => "'${m.displayName}'").join(', ');
  final symbols = members.skip(1).map(_memberSymbolLiteral).join(', ');
  return '${describeConflict(names)} '
      '$action using MockSpec(unsupportedMembers: {$symbols}).';
}

String? _checkMethodAccessorConflict(
  _JsExportBucket bucket,
  String interfaceName,
) {
  if (bucket.methods.isEmpty ||
      (bucket.getters.isEmpty && bucket.setters.isEmpty)) {
    return null;
  }
  return _formatBucketConflict(
    [...bucket.getters, ...bucket.setters, ...bucket.methods],
    (names) =>
        "The external members $names on '$interfaceName' export the same JS "
        "property '${bucket.jsName}' as both a method and a property accessor.",
    action: 'Exclude conflicting members',
  );
}

String? _checkGetterConflict(_JsExportBucket bucket, String interfaceName) {
  if (bucket.getters.length <= 1) return null;
  return _formatBucketConflict(
    bucket.getters,
    (names) =>
        "The external getters $names on '$interfaceName' export the same JS "
        "property '${bucket.jsName}' and cannot both be mocked.",
  );
}

(_JsSetterMultiplexer?, String?) _planBucketSetters(
  _JsExportBucket bucket,
  TypeSystem typeSystem,
  String interfaceName,
) {
  if (bucket.setters.length <= 1) return (null, null);
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
  if (branches != null) {
    return ((jsName: bucket.jsName, branches: branches), null);
  }
  return (
    null,
    _formatBucketConflict(
      bucket.setters,
      (names) =>
          "The external setters $names on '$interfaceName' export the same JS "
          "property '${bucket.jsName}' with parameter types that cannot be "
          'distinguished at runtime.',
    ),
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
  return (
    null,
    _formatBucketConflict(
      bucket.methods,
      (names) =>
          "The external methods $names on '$interfaceName' export the same JS "
          "property '${bucket.jsName}' with signatures that cannot be "
          'distinguished at runtime.',
      action: 'Exclude conflicting overloads',
    ),
  );
}

_JsMethodMultiplexer? _analyzeMethodOverloads(
  _JsExportBucket bucket,
  TypeSystem typeSystem,
) {
  if (bucket.methods.any((m) => m.formalParameters.any((p) => p.isNamed))) {
    return null;
  }
  final firstReturn = bucket.methods.first.returnType;
  final allSameReturn = bucket.methods.every(
    (m) => m.returnType == firstReturn,
  );
  if (!allSameReturn &&
      bucket.methods.any((m) => !_canBoxJsReturn(m.returnType, typeSystem))) {
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
    minReq = math.min(minReq, c.minRequired);
    maxPos = math.max(maxPos, c.maxArgs);
  }
  return (
    jsName: bucket.jsName,
    branches: branches,
    minRequired: minReq,
    maxArgs: maxPos,
    allSameReturn: allSameReturn,
  );
}

bool _canBoxJsReturn(analyzer.DartType type, TypeSystem typeSystem) {
  var (coreType, isNullable: _) = _unwrapNonJsExtensionType(type, typeSystem);
  while (coreType is analyzer.TypeParameterType) {
    coreType = coreType.bound;
  }
  if (coreType is analyzer.VoidType ||
      coreType.isDartCoreNull ||
      _corePrimitiveSymbol(coreType) != null) {
    return true;
  }
  return coreType is analyzer.InterfaceType &&
      !_wrapsOrImplementsSdkType(coreType, 'ExternalDartReference') &&
      coreType.element is ExtensionTypeElement &&
      (coreType.element as ExtensionTypeElement).isJSInteropType;
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

  TypeReference _sdkInteropTypeRef(String symbol, {required bool isNullable}) =>
      TypeReference(
        (b) =>
            b
              ..symbol = symbol
              ..url = 'dart:js_interop'
              ..isNullable = isNullable,
      );

  TypeReference _nullableJsAnyRef() =>
      _sdkInteropTypeRef('JSAny', isNullable: true);

  Expression _jsExportAnnotation(String jsName) =>
      Reference('JSExport', 'dart:js_interop').call([jsExportLiteral(jsName)]);

  Method _buildSetterMultiplexer(_JsSetterMultiplexer mux) {
    const paramName = '_value';
    return Method((mBuilder) {
      mBuilder
        ..name = '\$jsExport\$set\$${_safeJsIdentifier(mux.jsName)}'
        ..type = MethodType.setter
        ..annotations.add(_jsExportAnnotation(mux.jsName))
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
    final paramNames = [for (var i = 0; i < mux.maxArgs; i++) '_p$i'];
    final firstReturn = mux.branches.first.candidate.element.returnType;
    return Method((mBuilder) {
      mBuilder
        ..name = '\$jsExport\$method\$${_safeJsIdentifier(mux.jsName)}'
        ..annotations.add(_jsExportAnnotation(mux.jsName))
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
    final callExpr = _refer(method.displayName).call([
      for (var i = 0; i < candidate.params.length; i++)
        _convertArgExpression(paramNames[i], candidate.params[i]),
    ]);
    final returnType = method.returnType;
    if (allSameReturn) {
      return returnType is analyzer.VoidType
          ? callExpr.statement
          : callExpr.returned.statement;
    }
    final (coreReturn, :isNullable) = _unwrapNonJsExtensionType(
      returnType,
      typeSystem,
    );
    if (coreReturn is analyzer.VoidType || coreReturn.isDartCoreNull) {
      return Block.of([callExpr.statement, literalNull.returned.statement]);
    }
    if (_corePrimitiveSymbol(coreReturn) case final coreSymbol?) {
      final primitiveExpr =
          identical(coreReturn, returnType)
              ? callExpr
              : callExpr.asA(
                TypeReference(
                  (b) =>
                      b
                        ..symbol = coreSymbol
                        ..url = 'dart:core'
                        ..isNullable = isNullable,
                ),
              );
      final boxed =
          isNullable
              ? primitiveExpr.nullSafeProperty('toJS')
              : primitiveExpr.property('toJS');
      return boxed.returned.statement;
    }
    if (identical(coreReturn, returnType) && _implementsJsAny(returnType)) {
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
      if (i < branches.length - 1) {
        parts
          ..add(Code(i == 0 ? 'if (' : ' else if ('))
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
    final spec = clause.spec;
    if (spec == null) {
      return clause.flag
          ? paramRef.equalTo(literalNull)
          : paramRef.notEqualTo(literalNull);
    }
    final checkTypeRef =
        spec.sdkCheckSymbol != null
            ? _sdkInteropTypeRef(spec.sdkCheckSymbol!, isNullable: clause.flag)
            : _typeReference(
              typeSystem.promoteToNonNull(spec.originalType),
              forceNullable: clause.flag,
            );
    return paramRef.property('isA').call([], const {}, [checkTypeRef]);
  }

  Expression _convertArgExpression(String paramName, _JsParamSpec spec) {
    final paramRef = _refer(paramName);
    final targetType = spec.originalType;
    final (coreType, isNullable: _) = _unwrapNonJsExtensionType(
      targetType,
      typeSystem,
    );
    if (_unboxCorePrimitive(paramRef, coreType) case final unboxed?) {
      return identical(coreType, targetType)
          ? unboxed
          : unboxed.asA(
            _typeReference(targetType, forceNullable: true, overrideVoid: true),
          );
    }
    if (_isSdkJsInteropType(targetType.element, 'JSAny')) return paramRef;
    return paramRef.asA(
      _typeReference(targetType, forceNullable: true, overrideVoid: true),
    );
  }

  Expression? _unboxCorePrimitive(Expression paramRef, analyzer.DartType type) {
    final (sdkSymbol, getter) = switch (type) {
      _ when type.isDartCoreString => ('JSString', 'toDart'),
      _ when type.isDartCoreBool => ('JSBoolean', 'toDart'),
      _ when type.isDartCoreInt => ('JSNumber', 'toDartInt'),
      _ when type.isDartCoreDouble || type.isDartCoreNum => (
        'JSNumber',
        'toDartDouble',
      ),
      _ => (null, null),
    };
    if (sdkSymbol == null || getter == null) return null;
    return paramRef
        .asA(_sdkInteropTypeRef(sdkSymbol, isNullable: true))
        .nullSafeProperty(getter);
  }
}

/// JS interop classification helpers for analyzer [ExtensionTypeElement]s.
extension JsInteropExtensionTypeElement on ExtensionTypeElement {
  bool get isSdkJSInteropType {
    final uri = library.uri.toString();
    return uri == 'dart:js_interop' || uri == 'dart:js_interop_unsafe';
  }

  bool get isJSInteropType =>
      _representationChain.any((e) => e.isSdkJSInteropType);

  Iterable<ExtensionTypeElement> get _representationChain sync* {
    Element? current = this;
    while (current is ExtensionTypeElement) {
      yield current;
      current = current.representation.type.element;
    }
  }
}
