// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_runner/build_runner.dart';
import 'package:dart_style/dart_style.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart';

import '../common/test_phases.dart';

const _badOutput = r'''
  class _Foo implements Foo {
    // Trigger "A non-redirecting 'factory' constructor must have a body."
    factory _Foo();
  } 
''';

// Tests whether the stack trace emitted on a failed build is legible.
//
// Regression test for https://github.com/dart-lang/build/issues/427.
void main() {
  test('should throw a readable/terse stack trace', () async {
    final result = await testActions([
      new BuildAction(new BadCodeBuilder(), 'a'),
    ], {
      'a|lib/a.dart': 'class Foo {}',
    }, outputs: {
      'a|lib/a.g.dart': _badOutput
    }, checkBuildStatus: false);

    expect(result.status, BuildStatus.failure,
        reason: 'Dartfmt should fail due to invalid code emitted');
    final trace = new Trace.from(result.stackTrace);
    expect(trace.toString(), trace.terse.toString(), reason: 'Should be terse');
    expect(trace.foldFrames((f) => f.package == 'build_runner').toString(),
        trace.toString(),
        reason: 'Should fold build package frames');
  });
}

class BadCodeBuilder implements Builder {
  static final _dartfmt = new DartFormatter();

  @override
  Future<Null> build(BuildStep buildStep) async {
    // ignore: unawaited_futures
    final output = buildStep.inputId.changeExtension('.g.dart');
    await buildStep.writeAsString(output, _dartfmt.format(_badOutput));
  }

  @override
  final buildExtensions = const {
    'dart': const ['g.dart']
  };
}
