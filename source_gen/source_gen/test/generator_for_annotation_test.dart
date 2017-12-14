// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:source_gen/source_gen.dart';

void main() {
  test('Skips output if per-annotation output is empty', () async {
    final generator = new NoOutput();
    var builder = new LibraryBuilder(generator);
    await testBuilder(builder, {
      'a|lib/file.dart': '''
     @deprecated
     final foo = 'foo';
     '''
    }, outputs: {});
  });
}

class NoOutput extends GeneratorForAnnotation<Deprecated> {
  @override
  FutureOr<String> generateForAnnotatedElement(
          Element element, ConstantReader annotation, BuildStep buildStep) =>
      null;
}
