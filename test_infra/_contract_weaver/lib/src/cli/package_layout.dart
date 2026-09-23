// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_value/built_value.dart';

part 'package_layout.g.dart';

/// Where the package to weave lives.
abstract class PackageLayout
    implements Built<PackageLayout, PackageLayoutBuilder> {
  /// The absolute path of the directory holding the root `pubspec.yaml`.
  String get root;

  /// The path, relative to [root], of the workspace member to weave, or `null`
  /// if [root] is a standalone package that is woven itself.
  String? get member;

  /// The absolute path of the package to weave.
  String get packagePath => member == null ? root : '$root/$member';

  /// The name to report the package by.
  String get displayName => member ?? root.split('/').last;

  PackageLayout._();
  factory PackageLayout([void Function(PackageLayoutBuilder) updates]) =
      _$PackageLayout;

  /// Creates a [PackageLayout] from its fields.
  factory PackageLayout.of({required String root, String? member}) =>
      _$PackageLayout._(root: root, member: member);
}
