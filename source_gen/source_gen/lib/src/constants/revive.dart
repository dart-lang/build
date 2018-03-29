// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/constant/value.dart';

import '../utils.dart';

/// Attempts to extract what source code could be used to represent [object].
///
/// Returns `null` if it wasn't possible to parse [object], or [object] is a
/// primitive value (such as a number, string, boolean) that does not need to be
/// revived in order to represent it.
///
/// **NOTE**: Some returned [Revivable] instances are not representable as valid
/// Dart source code (such as referencing private constructors). It is up to the
/// build tool(s) using this library to surface error messages to the user.
Revivable reviveInstance(DartObject object, [LibraryElement origin]) {
  origin ??= object.type.element.library;
  final element = object.type.element;
  var url = Uri.parse(urlOfElement(element));
  if (element is FunctionElement) {
    return new Revivable._(
      source: url.removeFragment(),
      accessor: element.name,
    );
  }
  if (element is MethodElement && element.isStatic) {
    return new Revivable._(
      source: url.removeFragment(),
      accessor: '${element.enclosingElement.name}.${element.name}',
    );
  }
  final clazz = element as ClassElement;
  // Enums are not included in .definingCompilationUnit.types.
  if (clazz.isEnum) {
    for (final e in clazz.fields.where(
        (f) => f.isPublic && f.isConst && f.computeConstantValue() == object)) {
      return new Revivable._(
        source: url.removeFragment(),
        accessor: '${clazz.name}.${e.name}',
      );
    }
  }
  for (final e in origin.definingCompilationUnit.types
      .expand((t) => t.fields)
      .where((f) =>
          f.isPublic && f.isConst && f.computeConstantValue() == object)) {
    return new Revivable._(
      source: url.removeFragment(),
      accessor: '${clazz.name}.${e.name}',
    );
  }
  final i = (object as DartObjectImpl).getInvocation();
  if (i != null &&
      i.constructor.isPublic &&
      i.constructor.enclosingElement.isPublic) {
    url = Uri.parse(urlOfElement(i.constructor.enclosingElement));
    return new Revivable._(
      source: url,
      accessor: i.constructor.name,
      namedArguments: i.namedArguments,
      positionalArguments: i.positionalArguments,
    );
  }
  if (origin == null) {
    return null;
  }
  for (final e in origin.definingCompilationUnit.topLevelVariables.where(
    (f) => f.isPublic && f.isConst && f.computeConstantValue() == object,
  )) {
    return new Revivable._(
      source: Uri.parse(urlOfElement(origin)).replace(fragment: ''),
      accessor: e.name,
    );
  }
  return null;
}

/// Decoded "instructions" for re-creating a const [DartObject] at runtime.
class Revivable {
  /// A URL pointing to the location and class name.
  ///
  /// For example, `LinkedHashMap` looks like: `dart:collection#LinkedHashMap`.
  ///
  /// An accessor to a top-level field or method does not have a fragment and
  /// is instead represented as just something like `dart:collection`, with the
  /// [accessor] field as the name of the symbol.
  final Uri source;

  /// Constructor or getter name used to invoke `const Class(...)`.
  ///
  /// Optional - if empty string (`''`) then this means the default constructor.
  final String accessor;

  /// Positional arguments used to invoke the constructor.
  final List<DartObject> positionalArguments;

  /// Named arguments used to invoke the constructor.
  final Map<String, DartObject> namedArguments;

  const Revivable._({
    this.source,
    this.accessor: '',
    this.positionalArguments: const [],
    this.namedArguments: const {},
  });

  /// Whether this instance is visible outside the same library.
  ///
  /// Builds tools may use this to fail when the symbol is expected to be
  /// importable (i.e. isn't used with `part of`).
  bool get isPrivate => accessor.startsWith('_');
}
