// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner_core/src/logging/log_display.dart';
import 'package:test/test.dart';

void main() {
  group('LogDisplay', () {
    test('does nothing', () {
      final display = LogDisplay(() => '');
    });
  });
}
