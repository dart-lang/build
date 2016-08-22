// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';

void main() {
  group('build_test', () {
    group('testPhases', () {
      test('captures logs', () async {
        var p = new Phase()
          ..addAction(new _TestBuilder(), new InputSet('a', ['lib/b.dart']));
        var g = new PhaseGroup()..addPhase(p);
        var messages = <LogRecord>[];

        await testPhases(g, {'a|lib/b.dart': ''},
            outputs: {'a|lib/b.txt': '42'}, onLog: messages.add);
        expect(messages, isEmpty, reason: 'because by default logging is off');

        await testPhases(g, {'a|lib/b.dart': ''},
            outputs: {'a|lib/b.txt': '42'},
            onLog: messages.add,
            logLevel: Level.WARNING);
        expect(
            messages.any((r) =>
                r.level == Level.WARNING && r.message == 'test log message'),
            isTrue,
            reason: 'because logLevel is WARNING');
      });
    });
  });
}

class _TestBuilder implements Builder {
  @override
  Future build(BuildStep buildStep) async {
    buildStep.logger.warning('test log message');
    buildStep.writeAsString(
        new Asset(buildStep.input.id.changeExtension('.txt'), '42'));
  }

  @override
  List<AssetId> declareOutputs(AssetId inputId) =>
      <AssetId>[inputId.changeExtension('.txt')];
}
