// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import "package:async/async.dart";
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  Process process;
  StreamQueue<String> stdoutLines;

  setUpAll(() async {
    process = await Process.start(Platform.resolvedExecutable,
        [p.join('test', 'environment', 'simple_prompt.dart')]);
    stdoutLines = new StreamQueue(process.stdout
        .transform(new Utf8Decoder())
        .transform(new LineSplitter()));
  });

  test('Can give the user interactive prompts', () async {
    await expectEmits(stdoutLines, contains('Select an option!'));
    await expectEmits(stdoutLines, contains('1 - a'));
    await expectEmits(stdoutLines, contains('2 - b'));
    await expectEmits(stdoutLines, contains('3 - c'));

    process.stdin.writeln('4');
    expect(await stdoutLines.next, contains('Unrecognized option 4'));

    process.stdin.writeln('3');
    await expectEmits(stdoutLines, contains('2'));
    await process.exitCode;
  });
}

Future<Null> expectEmits(StreamQueue<String> stream, Matcher line) async {
  while (true) {
    if (line.matches(await stream.next, null)) {
      return;
    }
  }
}
