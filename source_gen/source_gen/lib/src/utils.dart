// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
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

/// Returns a non-null name for the provided [type].
///
/// In newer versions of the Dart analyzer, a `typedef` does not keep the
/// existing `name`, because it is used an alias:
/// ```
/// // Used to return `VoidFunc` for name, is now `null`.
/// typedef VoidFunc = void Function();
/// ```
///
/// This function will return `'VoidFunc'`, unlike [DartType.name].
String typeNameOf(DartType type) {
  if (type is FunctionType) {
    final element = type.element;
    if (element is GenericFunctionTypeElement) {
      return element.enclosingElement.name;
    }
  }
  return type.name;
}

/// Returns a name suitable for `part of "..."` when pointing to [element].
///
/// Returns `null` if [element] is missing identifier.
String nameOfPartial(LibraryElement element, AssetId source) {
  if (element.name != null && element.name.isNotEmpty) {
    return element.name;
  }

  var sourceUrl = p.basename(source.uri.toString());
  return '\'$sourceUrl\'';
}

/// Returns a suggested library identifier based on [source] path and package.
String suggestLibraryName(AssetId source) {
  // lib/test.dart --> [lib/test.dart]
  var parts = source.path.split('/');
  // [lib/test.dart] --> [lib/test]
  parts[parts.length - 1] = parts.last.split('.').first;
  // [lib/test] --> [test]
  if (parts.first == 'lib') {
    parts.removeAt(0);
  }
  return '${source.package}.${parts.join('.')}';
}

/// Returns what 'part "..."' URL is needed to import [output] from [input].
///
/// For example, will return `test_lib.g.dart` for `test_lib.dart`.
String computePartUrl(AssetId input, AssetId output) =>
    p.joinAll(p.split(p.relative(output.path, from: input.path)).skip(1));

/// Returns a URL representing [element].
String urlOfElement(Element element) => element.kind == ElementKind.DYNAMIC
    ? 'dart:core#dynmaic'
    // using librarySource.uri – in case the element is in a part
    : normalizeUrl(element.librarySource.uri)
        .replace(fragment: element.name)
        .toString();

Uri normalizeUrl(Uri url) {
  switch (url.scheme) {
    case 'dart':
      return normalizeDartUrl(url);
    case 'package':
      return packageToAssetUrl(url);
    default:
      return url;
  }
}

/// Make `dart:`-type URLs look like a user-knowable path.
///
/// Some internal dart: URLs are something like `dart:core/map.dart`.
///
/// This isn't a user-knowable path, so we strip out extra path segments
/// and only expose `dart:core`.
Uri normalizeDartUrl(Uri url) => url.pathSegments.isNotEmpty
    ? url.replace(pathSegments: url.pathSegments.take(1))
    : url;

/// Returns a `package:` URL converted to a `asset:` URL.
///
/// This makes internal comparison logic much easier, but still allows users
/// to define assets in terms of `package:`, which is something that makes more
/// sense to most.
///
/// For example, this transforms `package:source_gen/source_gen.dart` into:
/// `asset:source_gen/lib/source_gen.dart`.
Uri packageToAssetUrl(Uri url) => url.scheme == 'package'
    ? url.replace(
        scheme: 'asset',
        pathSegments: <String>[]
          ..add(url.pathSegments.first)
          ..add('lib')
          ..addAll(url.pathSegments.skip(1)))
    : url;

/// Returns a `asset:` URL converted to a `package:` URL.
///
/// For example, this transformers `asset:source_gen/lib/source_gen.dart' into:
/// `package:source_gen/source_gen.dart`. Asset URLs that aren't pointing to a
/// file in the 'lib' folder are not modified.
///
/// Asset URLs come from `package:build`, as they are able to describe URLs that
/// are not describable using `package:...`, such as files in the `bin`, `tool`,
/// `web`, or even root directory of a package - `asset:some_lib/web/main.dart`.
Uri assetToPackageUrl(Uri url) => url.scheme == 'asset' &&
        url.pathSegments.isNotEmpty &&
        url.pathSegments[1] == 'lib'
    ? url.replace(
        scheme: 'package',
        pathSegments: [url.pathSegments.first]
          ..addAll(url.pathSegments.skip(2)))
    : url;
