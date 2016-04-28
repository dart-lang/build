// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_gen.generator;

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

abstract class Generator {
  const Generator();

  Future<String> generate(Element element, BuildStep buildStep) => null;

  @override
  String toString() => this.runtimeType.toString();
}

class InvalidGenerationSourceError {
  final String message;
  final String todo;

  InvalidGenerationSourceError(this.message, {String todo})
      : this.todo = todo == null ? '' : todo;

  @override
  String toString() => message;
}
