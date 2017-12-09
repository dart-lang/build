// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  group('MultiplexingBuilder', () {
    test('Only passes matching inputs', () async {
      final builder = new MultiplexingBuilder(
          [new PickyInput('.foo'), new PickyInput('.bar')]);
      await testBuilder(builder, {'a|lib/a1.foo': 'a1', 'a|lib/a2.bar': 'a2'},
          outputs: {'a|lib/a1.new': 'a1', 'a|lib/a2.new': 'a2'});
    });

    test('merges non-overlapping extension maps', () {
      final builder = new MultiplexingBuilder(
          [new PickyInput('.foo'), new PickyInput('.bar')]);
      expect(builder.buildExtensions, {
        '.foo': ['.new'],
        '.bar': ['.new']
      });
    });

    test('merges overlapping extension maps', () {
      final builder = new MultiplexingBuilder([
        new PickyInput('.foo', ['.new1', '.new2']),
        new PickyInput('.foo', ['.new3'])
      ]);
      expect(builder.buildExtensions, {
        '.foo': ['.new1', '.new2', '.new3']
      });
    });
  });
}

class PickyInput implements Builder {
  final String inputExtension;
  final List<String> outputExtensions;

  PickyInput(this.inputExtension, [this.outputExtensions = const ['.new']]);

  @override
  Map<String, List<String>> get buildExtensions =>
      {inputExtension: outputExtensions};

  @override
  Future build(BuildStep buildStep) {
    if (!buildStep.inputId.path.endsWith(inputExtension)) {
      throw new ArgumentError('Should not run on input ${buildStep.inputId}');
    }
    for (final output in outputExtensions) {
      buildStep.writeAsBytes(buildStep.inputId.changeExtension(output),
          buildStep.readAsBytes(buildStep.inputId));
    }
    return new Future.value(null);
  }
}
