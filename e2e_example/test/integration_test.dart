// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  Process process;
  Stream<String> stdOutLines;
  setUpAll(() async {
    process = await Process.start('dart', ['tool/build.dart']);
    stdOutLines = process.stdout
        .transform(UTF8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();
    stdOutLines.listen(print);
    expect(stdOutLines, emitsThrough(contains('build completed')));
  });

  tearDownAll(() async {
    expect(process.kill(), true);
    await process.exitCode;
  });

  test('Can run passing tests', () async {
    var result = await Process
        .run('pub', ['run', 'test', '--pub-serve', '8081', '-p', 'chrome']);
    expect(result.stdout, contains('All tests passed!'));
  });
}
