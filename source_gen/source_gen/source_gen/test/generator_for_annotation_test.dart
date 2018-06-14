// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:source_gen/source_gen.dart';

void main() {
  test('Skips output if per-annotation output is `null`', () async {
    final generator = const LiteralOutput();
    var builder = new LibraryBuilder(generator);
    await testBuilder(builder, _inputMap, outputs: {});
  });

  test('Skips output if per-annotation output is empty string', () async {
    final generator = const LiteralOutput('');
    var builder = new LibraryBuilder(generator);
    await testBuilder(builder, _inputMap, outputs: {});
  });

  test('Skips output if per-annotation output is only whitespace', () async {
    final generator = const LiteralOutput('\n  \n   \t');
    var builder = new LibraryBuilder(generator);
    await testBuilder(builder, _inputMap, outputs: {});
  });

  test('Supports and dedupes multiple return values', () async {
    final generator = const RepeatingGenerator();
    var builder = new LibraryBuilder(generator);
    await testBuilder(builder, _inputMap, outputs: {
      'a|lib/file.g.dart': r'''
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// RepeatingGenerator
// **************************************************************************

// There are deprecated values in this library!

// String foo

// String bar

// String baz
'''
    });
  });

  test('handles errors correctly', () async {
    final generator = const FailingGenerator();
    var builder = new LibraryBuilder(generator);
    await testBuilder(builder, _inputMap, outputs: {
      'a|lib/file.g.dart': r'''
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// FailingGenerator
// **************************************************************************

// Error: Bad state: not supported!
'''
    });
  });
}

class FailingGenerator extends GeneratorForAnnotation<Deprecated> {
  const FailingGenerator();

  @override
  Iterable<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) sync* {
    yield '// There are deprecated values in this library!';
    throw new StateError('not supported!');
  }
}

class RepeatingGenerator extends GeneratorForAnnotation<Deprecated> {
  const RepeatingGenerator();

  @override
  Iterable<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) sync* {
    yield '// There are deprecated values in this library!';

    yield '// $element';
  }
}

class LiteralOutput<T> extends GeneratorForAnnotation<Deprecated> {
  final T value;

  const LiteralOutput([this.value]);

  @override
  T generateForAnnotatedElement(
          Element element, ConstantReader annotation, BuildStep buildStep) =>
      null;
}

const _inputMap = const {
  'a|lib/file.dart': '''
     @deprecated
     final foo = 'foo';

     @deprecated
     final bar = 'bar';

     @deprecated
     final baz = 'baz';
     '''
};
