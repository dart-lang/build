// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/src/logging/ansi_buffer.dart';
import 'package:build/src/logging/log_display.dart';

// TODO(davidmorgan): figure out how to make this a test.
void main() async {
  final display = LogDisplay();
  display.block(
    AnsiBuffer()
      ..writeLine(['start with'])
      ..writeLine(['two lines']),
  );
  await Future<void>.delayed(const Duration(seconds: 2));
  display.block(AnsiBuffer()..writeLine(['now there should be one line']));
  await Future<void>.delayed(const Duration(seconds: 2));
  display.block(
    AnsiBuffer()
      ..writeLine(['now'])
      ..writeLine(['three'])
      ..writeLine(['lines']),
  );
  await Future<void>.delayed(const Duration(seconds: 2));
  display.block(AnsiBuffer()..writeLine(['finally one line again']));
}
