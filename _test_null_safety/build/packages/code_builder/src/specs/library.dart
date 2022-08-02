// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:meta/meta.dart';

import '../base.dart';
import '../mixins/annotations.dart';
import '../visitors.dart';
import 'directive.dart';
import 'expression.dart';

part 'library.g.dart';

@immutable
abstract class Library
    with HasAnnotations
    implements Built<Library, LibraryBuilder>, Spec {
  factory Library([void Function(LibraryBuilder) updates]) = _$Library;
  Library._();

  @override
  BuiltList<Expression> get annotations;

  BuiltList<Directive> get directives;
  BuiltList<Spec> get body;

  /// Name of the library.
  ///
  /// May be `null` when no [annotations] are specified.
  String? get name;

  @override
  R accept<R>(
    SpecVisitor<R> visitor, [
    R? context,
  ]) =>
      visitor.visitLibrary(this, context);
}

abstract class LibraryBuilder
    with HasAnnotationsBuilder
    implements Builder<Library, LibraryBuilder> {
  factory LibraryBuilder() = _$LibraryBuilder;
  LibraryBuilder._();

  @override
  ListBuilder<Expression> annotations = ListBuilder<Expression>();

  ListBuilder<Spec> body = ListBuilder<Spec>();
  ListBuilder<Directive> directives = ListBuilder<Directive>();

  String? name;
}
