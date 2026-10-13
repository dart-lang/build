// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_contract_weaver/contract_weaver.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Weaves each `test/expect/*.dart` and compares the result with the
/// checked-in `.dart.expect` file beside it.
///
/// To update the expectations, run with `UPDATE_EXPECTATIONS=1`.
void main() {
  final update = Platform.environment['UPDATE_EXPECTATIONS'] == '1';
  final inputs = [
    for (final entity in Directory(p.join('test', 'expect')).listSync())
      if (entity is File && entity.path.endsWith('.dart')) entity,
  ]..sort((a, b) => a.path.compareTo(b.path));

  for (final input in inputs) {
    test(p.basename(input.path), () {
      final woven = ContractWeaver().weave(input.readAsStringSync());
      final expectFile = File('${input.path}.expect');
      if (update) {
        expectFile.writeAsStringSync(woven);
        return;
      }
      expect(
        expectFile.existsSync(),
        isTrue,
        reason:
            'Missing ${expectFile.path}; run with UPDATE_EXPECTATIONS=1 '
            'to create it.',
      );
      expect(
        woven,
        expectFile.readAsStringSync(),
        reason:
            'Woven output differs from ${expectFile.path}; if the change is '
            'intended, run with UPDATE_EXPECTATIONS=1.',
      );
    });
  }
}
