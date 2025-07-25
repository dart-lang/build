// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

class BootstrapAction {
  final String outputPath;
  final Future<BootstrapActionResult> Function() action;

  BootstrapAction({required this.outputPath, required this.action});

  String get _depsPath => '$outputPath.deps';
  String get _digestsPath => '$outputPath.digests';

  Future<BootstrapActionResult> maybeRun() async {
    if (!File(_depsPath).existsSync()) return runAndDigest();
    if (!File(outputPath).existsSync()) return runAndDigest();
    if (!File(_digestsPath).existsSync()) return runAndDigest();

    final digests = computeDigests();
    final oldDigests = File(_digestsPath).readAsStringSync();
    if (digests != oldDigests) return runAndDigest();

    return BootstrapActionResult(succeeded: true);
  }

  Future<BootstrapActionResult> runAndDigest() async {
    final result = await run();
    return result;
  }

  Future<BootstrapActionResult> run() {
    return action();
  }

  void stamp() {
    // TODO(davidmorgan): spaces.
    File(depsPath).writeAsStringSync('$outputPath: ${inputPaths.join(' ')}');
    File(digestsPath).writeAsStringSync(computeDigests());
  }

  String computeDigests() => '''
inputs digest: ${_computeDigest(inputPaths)}
output digest: ${_computeDigest([outputPath])}
''';

  String _computeDigest(Iterable<String> deps) {
    final digestSink = AccumulatorSink<Digest>();
    final result = md5.startChunkedConversion(digestSink);
    for (final dep in deps) {
      result.add(File(dep).readAsBytesSync());
    }
    result.close();
    return base64.encode(digestSink.events.first.bytes);
  }
}

class BootstrapActionResult {
  bool succeeded;
  String? messages;
  List<String>? _inputPaths;
  String? _content;

  BootstrapActionResult({
    required this.succeeded,
    this.messages,
    List<String>? inputPaths,
    String? content,
  }) : _inputPaths = inputPaths,
       _content = content;
}
