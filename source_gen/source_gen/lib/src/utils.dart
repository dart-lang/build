// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;

String friendlyNameForElement(Element element) {
  var friendlyName = element.displayName;

  if (friendlyName == null) {
    throw new ArgumentError(
        'Cannot get friendly name for $element - ${element.runtimeType}.');
  }

  var names = <String>[friendlyName];
  if (element is ClassElement) {
    names.insert(0, 'class');
    if (element.isAbstract) {
      names.insert(0, 'abstract');
    }
  }
  if (element is VariableElement) {
    names.insert(0, element.type.toString());

    if (element.isConst) {
      names.insert(0, 'const');
    }

    if (element.isFinal) {
      names.insert(0, 'final');
    }
  }
  if (element is LibraryElement) {
    names.insert(0, 'library');
  }

  return names.join(' ');
}

/// Returns a name suitable for `part of "..."` when pointing to [element].
///
/// Returns `null` if [element] is missing identifier.
///
/// Starting in `1.25.0`, setting [allowUnnamedPartials] will fallback
/// (actually, preferred) to `'part of "package:foo/path.dart'`, and null will
/// never be returned.
String nameOfPartial(
  LibraryElement element,
  AssetId source, {
  bool allowUnnamedPartials: false,
}) {
  if (element.name != null && element.name.isNotEmpty) {
    return element.name;
  }
  if (allowUnnamedPartials) {
    var sourceUrl = p.basename(source.uri.toString());
    return '\'$sourceUrl\'';
  }
  return null;
}

/// Returns a suggested library identifier based on [source] path and package.
String suggestLibraryName(AssetId source) {
  // lib/test.dart --> [lib/test.dart]
  var parts = source.path.split('/');
  // [lib/test.dart] --> [lib/test]
  parts[parts.length - 1] = parts.last.split('.').first;
  // [lib/test] --> [test]
  if (parts.first == 'lib') {
    parts = parts.skip(1);
  }
  return '${source.package}.${parts.join('.')}';
}

/// Returns all of the declarations in [unit], including [unit] as the first
/// item.
Iterable<Element> getElementsFromLibraryElement(LibraryElement unit) sync* {
  yield unit;
  for (var cu in unit.units) {
    for (var compUnitMember in cu.unit.declarations) {
      yield* _getElements(compUnitMember);
    }
  }
}

/// Returns an Iterable that will not throw any exceptions while iterating.
///
/// If an exception occurs while iterating [iterable] the return value will
/// finish and [onError] will be called.
Iterable<T> safeIterate<T>(Iterable<T> iterable, void onError(e, st)) sync* {
  try {
    for (var e in iterable) {
      yield e;
    }
  } catch (e, st) {
    onError(e, st);
  }
}

Iterable<Element> _getElements(CompilationUnitMember member) {
  if (member is TopLevelVariableDeclaration) {
    return member.variables.variables
        .map(resolutionMap.elementDeclaredByVariableDeclaration);
  }
  var element = resolutionMap.elementDeclaredByDeclaration(member);

  if (element == null) {
    print([member, member.runtimeType, member.element]);
    throw new Exception('Could not find any elements for the provided unit.');
  }

  return [element];
}
