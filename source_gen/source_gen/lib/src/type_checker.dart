// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// An abstraction around doing static type checking at compile/build time.
abstract class TypeChecker {
  const TypeChecker._();

  /// Create a new [TypeChecker] backed by a runtime [type].
  ///
  /// This implementation uses `dart:mirrors` (runtime reflection).
  const factory TypeChecker.fromRuntime(Type type) = _MirrorTypeChecker;

  /// Create a new [TypeChecker] backed by a static [type].
  const factory TypeChecker.fromStatic(DartType type) = _LibraryTypeChecker;

  /// Create a new [TypeChecker] backed by a library [url].
  ///
  /// Example of referring to a `LinkedHashMap` from `dart:collection`:
  /// ```dart
  /// const linkedHashMap = const TypeChecker.fromUrl(
  ///   'dart:collection#LinkedHashMap',
  /// );
  /// ```
  const factory TypeChecker.fromUrl(dynamic url) = _UriTypeChecker;

  /// Returns the first constant annotating [element] that is this type.
  ///
  /// Otherwise returns `null`.
  DartObject firstAnnotationOf(Element element) {
    if (element.metadata.isEmpty) {
      return null;
    }
    final results = annotationsOf(element);
    return results.isEmpty ? null : results.first;
  }

  /// Returns every constant annotating [element] that is this type.
  Iterable<DartObject> annotationsOf(Element element) => element.metadata
      .map((a) => a.computeConstantValue())
      .where((a) => isExactlyType(a.type));

  /// Returns `true` if representing the exact same class as [element].
  bool isExactly(Element element);

  /// Returns `true` if representing the exact same type as [staticType].
  bool isExactlyType(DartType staticType) => isExactly(staticType.element);

  /// Returns `true` if representing a super class of [element].
  bool isSuperOf(Element element) =>
      element is ClassElement && element.allSupertypes.any(isExactlyType);

  /// Returns `true` if representing a super type of [staticType].
  bool isSuperTypeOf(DartType staticType) => isSuperOf(staticType.element);
}

Uri _normalizeUrl(Uri url) {
  switch (url.scheme) {
    case 'dart':
      return _normalizeDartUrl(url);
    case 'package':
      return _packageToAssetUrl(url);
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
Uri _normalizeDartUrl(Uri url) => url.pathSegments.isNotEmpty
    ? url.replace(pathSegments: url.pathSegments.take(1))
    : url;

/// Returns a `package:` URL into a `asset:` URL.
///
/// This makes internal comparison logic much easier, but still allows users
/// to define assets in terms of `package:`, which is something that makes more
/// sense to most.
///
/// For example this transforms `package:source_gen/source_gen.dart` into:
/// `asset:source_gen/lib/source_gen.dart`.
Uri _packageToAssetUrl(Uri url) => url.scheme == 'package'
    ? url.replace(
        scheme: 'asset',
        pathSegments: <String>[]
          ..add(url.pathSegments.first)
          ..add('lib')
          ..addAll(url.pathSegments.skip(1)))
    : url;

/// Returns
String _urlOfElement(Element element) => element.kind == ElementKind.DYNAMIC
    ? 'dart:core#dynmaic'
    : _normalizeUrl(element.source.uri)
        .replace(fragment: element.name)
        .toString();

// Checks a static type against another static type;
class _LibraryTypeChecker extends TypeChecker {
  final DartType _type;

  const _LibraryTypeChecker(this._type) : super._();

  @override
  bool isExactly(Element element) =>
      element is ClassElement && element == _type.element;

  @override
  String toString() => '${_urlOfElement(_type.element)}';
}

// Checks a runtime type against a static type.
class _MirrorTypeChecker extends TypeChecker {
  static Uri _uriOf(ClassMirror mirror) =>
      _normalizeUrl((mirror.owner as LibraryMirror).uri)
          .replace(fragment: MirrorSystem.getName(mirror.simpleName));

  // Precomputed type checker for types that already have been used.
  static final _cache = new Expando<TypeChecker>();

  final Type _type;

  const _MirrorTypeChecker(this._type) : super._();

  TypeChecker get _computed =>
      _cache[this] ??= new TypeChecker.fromUrl(_uriOf(reflectClass(_type)));

  @override
  bool isExactly(Element element) => _computed.isExactly(element);

  @override
  String toString() => _computed.toString();
}

// Checks a runtime type against an Uri and Symbol.
class _UriTypeChecker extends TypeChecker {
  final String _url;

  // Precomputed cache of String --> Uri.
  static final _cache = new Expando<Uri>();

  const _UriTypeChecker(dynamic url)
      : _url = '$url',
        super._();

  @override
  bool operator ==(Object o) => o is _UriTypeChecker && o._url == _url;

  @override
  int get hashCode => _url.hashCode;

  /// Url as a [Uri] object, lazily constructed.
  Uri get uri => _cache[this] ??= Uri.parse(_url);

  /// Returns whether this type represents the same as [url].
  bool hasSameUrl(dynamic url) =>
      uri.toString() == (url is String ? url : _normalizeUrl(url).toString());

  @override
  bool isExactly(Element element) => hasSameUrl(_urlOfElement(element));

  @override
  String toString() => '${uri}';
}
